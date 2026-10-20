import 'dart:async';

import 'package:flutter/material.dart';
import '../../design_system/tokens/shadows.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatting/transit_formatter.dart';
import '../../core/geo/geo_point.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/notifications/notification_repository.dart';
import '../../data/preferences/user_preferences.dart';
import '../../data/profile/profile.dart';
import '../../data/transit/bus.dart';
import '../../data/transit/bus_route.dart';
import '../../data/transit/bus_stop_progress.dart';
import '../../data/transit/scheduled_departure.dart';
import '../../data/transit/stop.dart';
import '../../design_system/tokens/tracklet_fonts.dart';
import '../../design_system/tokens/typography.dart';
import '../../design_system/components/tracklet_empty_state.dart';
import '../../design_system/components/tracklet_error_state.dart';
import '../../design_system/components/tracklet_skeleton.dart';
import '../../design_system/components/voxel_avatar.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/components/tracklet_brand_lockup.dart';
import '../../design_system/tokens/motion.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
import '../../services/location/location_service.dart';
import '../../services/notifications/onesignal_service.dart';
import '../../services/widget/widget_sync_service.dart';
import '../admin/providers/admin_provider.dart';
import '../map/providers/map_state_provider.dart';
import 'home_transit_logic.dart';
import 'providers/home_provider.dart';
import 'widgets/next_bus_card.dart';
import 'widgets/next_buses_card.dart';
import 'widgets/stop_selector_sheet.dart';

/// Campus transit dashboard with a stop-first, position-first, and confidence-aware bus tracking experience.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Stop? _manualBoardingStop;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Persist only subscriptions that OneSignal reports as opted in.
        OneSignalService.setupPushSubscriptionObserver(
          onRegistered: (subId) {
            final pushPreference =
                ref.read(userPreferencesProvider).pushNotificationsEnabled;
            if (pushPreference == false) {
              unawaited(OneSignalService.disablePushNotifications());
              return;
            }
            if (pushPreference == null) {
              unawaited(
                ref
                    .read(userPreferencesProvider.notifier)
                    .setPushNotificationsEnabled(true),
              );
            }
            final authRepo = ref.read(authRepositoryProvider);
            if (authRepo.isAuthenticated) {
              ref
                  .read(notificationRepositoryProvider)
                  .updateSubscription(
                    platform:
                        Theme.of(context).platform == TargetPlatform.iOS
                            ? 'ios'
                            : 'android',
                    oneSignalSubId: subId,
                  );
            }
          },
        );

        final locState = ref.read(locationStateProvider);
        if (locState.currentLocation != null) {
          WidgetSyncService.setUserLocation(
            latitude: locState.currentLocation!.latitude,
            longitude: locState.currentLocation!.longitude,
          );
        }

        if (!locState.hasPermission &&
            locState.permissionState != LocationPermissionState.deniedForever) {
          ref.read(locationStateProvider.notifier).requestAndFetchLocation();
        } else {
          ref.read(locationStateProvider.notifier).refreshLocationIfPermitted();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Push reference data (stops + route-stop maps) to the Android widget store once the
    // home state resolves. This supersedes the hardcoded fallback in WidgetPreferences.kt.
    ref.listenManual(homeStateProvider, (_, next) {
      next.whenData((state) {
        if (state.stops.isNotEmpty && state.routes.isNotEmpty) {
          WidgetSyncService.syncReferenceData(
            stops: state.stops,
            routes: state.routes,
          );
        }
      });
    });
    // Keep the widget state fresh whenever live bus positions update while the app is open.
    ref.listenManual(liveTransitPollingProvider, (_, next) {
      if (!next.isRefreshing) {
        _pushWidgetBusState(next.buses);
      }
    });
    // Keep the widget GPS position in sync whenever the user's location updates.
    ref.listenManual(locationStateProvider, (_, next) {
      final loc = next.currentLocation;
      if (loc != null) {
        WidgetSyncService.setUserLocation(
          latitude: loc.latitude,
          longitude: loc.longitude,
        );
      }
    });
  }

  /// Resolves the nearest qualifying bus for the current boarding stop and pushes
  /// it to the Android home-screen widget cache.
  void _pushWidgetBusState(List<Bus> buses) {
    final homeStateValue = ref.read(homeStateProvider).value;
    if (homeStateValue == null) return;

    final stops = homeStateValue.stops;
    final routes = homeStateValue.routes;
    final locationState = ref.read(locationStateProvider);

    // Replicate boarding-stop resolution identical to the build() logic.
    final nearestStop =
        locationState.currentLocation == null
            ? null
            : nearestCampusStopTo(locationState.currentLocation!, stops);

    final boardingStop =
        _manualBoardingStop != null
            ? (stops
                    .where((s) => s.id == _manualBoardingStop!.id)
                    .firstOrNull ??
                _manualBoardingStop!)
            : (nearestStop ??
                stops
                    .where(
                      (s) =>
                          s.sourceStopId == 'main_gate' ||
                          s.name == 'Main Gate',
                    )
                    .firstOrNull ??
                stops.firstOrNull);

    if (boardingStop == null) return;

    final routesById = {for (final r in routes) r.id: r};

    // Find the closest qualifying bus (route serves boardingStop, valid position,
    // not (0,0)) — mirrors the Kotlin widget logic.
    Bus? nearestBus;
    double? nearestDistanceMeters;

    for (final bus in buses) {
      final route = routesById[bus.routeId];
      if (route == null) continue;
      if (!route.stopIds.contains(boardingStop.id)) continue;
      if (!bus.hasValidLocation) continue;
      if (bus.position.point.latitude == 0.0 &&
          bus.position.point.longitude == 0.0) {
        continue;
      }

      final dist = bus.position.point.distanceToMeters(boardingStop.location);
      if (nearestDistanceMeters == null || dist < nearestDistanceMeters) {
        nearestBus = bus;
        nearestDistanceMeters = dist;
      }
    }

    WidgetSyncService.updateWidgetState(
      stopName: boardingStop.name,
      bus: nearestBus,
      distanceMeters: nearestDistanceMeters,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(liveTransitPollingProvider.notifier).pause();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(liveTransitPollingProvider.notifier).resume();
      ref.read(locationStateProvider.notifier).refreshPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeStateAsync = ref.watch(homeStateProvider);
    final locationState = ref.watch(locationStateProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: TrackletColors.adaptiveBackground(context),
      drawer: homeStateAsync.maybeWhen(
        data: (state) => _buildDrawer(context, state.userProfile),
        orElse: () => null,
      ),
      body: homeStateAsync.when(
        loading: () => const TrackletHomeSkeleton(),
        error:
            (error, stack) => SafeArea(
              child: TrackletErrorState(
                message: 'Could not load campus buses',
                onRetry: () {
                  ref.invalidate(homeStateProvider);
                  ref
                      .read(liveTransitPollingProvider.notifier)
                      .refresh(force: true);
                },
              ),
            ),
        data: (state) {
          if (state.stops.isEmpty) {
            return SafeArea(
              child: TrackletEmptyState(
                title: 'Campus transit unavailable',
                description:
                    'Transit stops will appear here when the campus data source is available.',
                actionLabel: 'Retry',
                onAction: () {
                  ref.invalidate(homeStateProvider);
                  ref
                      .read(liveTransitPollingProvider.notifier)
                      .refresh(force: true);
                },
              ),
            );
          }

          final profile = state.userProfile;
          final stops = state.stops;
          final selectedStop = state.selectedStop ?? stops.first;

          final nearestStop =
              locationState.currentLocation == null
                  ? null
                  : nearestCampusStopTo(locationState.currentLocation!, stops);

          final boardingStop =
              _manualBoardingStop != null
                  ? (stops
                          .where((s) => s.id == _manualBoardingStop!.id)
                          .firstOrNull ??
                      _manualBoardingStop!)
                  : (nearestStop ??
                      stops
                          .where((stop) => stop.id == selectedStop.id)
                          .firstOrNull ??
                      selectedStop);

          // Calculate actual distance & walking time using user GPS and Supabase stop coordinates
          final boardingStopDistanceMeters = locationState.currentLocation
              ?.distanceToMeters(boardingStop.location);

          final isOutsideCampus =
              locationState.currentLocation != null &&
              (boardingStopDistanceMeters != null &&
                  boardingStopDistanceMeters > campusStopWalkingRangeMeters);

          final walkTimeMinutes =
              (boardingStopDistanceMeters == null || isOutsideCampus)
                  ? null
                  : estimateWalkMinutes(boardingStopDistanceMeters);

          final reduceMotion = MediaQuery.disableAnimationsOf(context);

          final header = _HomeHeader(
            scaffoldKey: _scaffoldKey,
            profile: profile,
            onProfilePressed: () => context.go('/profile'),
          );

          final headerWidget =
              reduceMotion
                  ? header
                  : RepaintBoundary(
                    child: header
                        .animate()
                        .fadeIn(
                          duration: TrackletMotion.medium,
                          curve: TrackletMotion.easeOut,
                        )
                        .slideY(
                          begin: -0.025,
                          duration: TrackletMotion.medium,
                          curve: TrackletMotion.easeOut,
                        ),
                  );

          return RefreshIndicator(
            color: TrackletColors.primary,
            onRefresh: () async {
              ref.invalidate(homeStateProvider);
              await ref
                  .read(liveTransitPollingProvider.notifier)
                  .refresh(force: true);
              await ref.read(homeStateProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: headerWidget),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      12,
                      18,
                      100 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BoardingStopCard(
                          boardingStop: boardingStop,
                          distanceMeters: boardingStopDistanceMeters,
                          walkingMinutes: walkTimeMinutes,
                          isAutoSelected: _manualBoardingStop == null,
                          isLoadingLocation: locationState.isLoading,
                          isOutsideCampus: isOutsideCampus,
                          onLocate: _requestLocation,
                          onResetToAuto: () {
                            HapticFeedback.selectionClick();
                            setState(() => _manualBoardingStop = null);
                            WidgetSyncService.setPinnedStop(
                              stopId: null,
                              stopName: null,
                            );
                          },
                          onChange:
                              () => _openStopSelector(
                                stops,
                                boardingStop,
                                locationState.currentLocation,
                              ),
                        ),
                        const SizedBox(height: TrackletSpacing.lg),
                        _LiveBusesSection(
                          boardingStop: boardingStop,
                          stops: stops,
                          routes: state.routes,
                          fallbackBuses: state.buses,
                          onOpenMapWithBus: _openMapWithBus,
                          onOpenStopSelector:
                              () => _openStopSelector(
                                stops,
                                boardingStop,
                                locationState.currentLocation,
                              ),
                          reduceMotion: reduceMotion,
                        ),
                        _ScheduledDeparturesSection(
                          boardingStop: boardingStop,
                          scheduledDepartures: state.scheduledDepartures,
                          routes: state.routes,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openStopSelector(
    List<Stop> stops,
    Stop currentStop,
    GeoPoint? userLocation,
  ) {
    StopSelectorSheet.show(
      context: context,
      stops: stops,
      currentStop: currentStop,
      userLocation: userLocation,
      onStopSelected: (selected) {
        setState(() {
          _manualBoardingStop = selected;
        });
        WidgetSyncService.setPinnedStop(
          stopId: selected.id,
          stopName: selected.name,
        );
      },
    );
  }

  Future<void> _requestLocation() async {
    try {
      await ref.read(locationStateProvider.notifier).requestAndFetchLocation();
      if (!mounted) return;
      final location = ref.read(locationStateProvider);
      if (location.currentLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              location.errorMessage ??
                  'Location unavailable. Using the default campus stop.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get your location. Try again.'),
        ),
      );
    }
  }

  void _openMapWithBus(Bus bus) {
    ref.read(mapStateNotifierProvider.notifier).selectBus(bus);
    context.go('/map');
  }

  Widget _buildDrawer(BuildContext context, Profile profile) {
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    return Drawer(
      backgroundColor: TrackletColors.adaptiveBackground(context),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: TrackletBrandLockup(
                logoSize: 38,
                wordmarkHeight: 24,
                spacing: 10,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: Text(
                        'Account Options',
                        style: TextStyle(
                          color: TrackletColors.adaptiveTextSecondary(context),
                          fontSize: TrackletTypography.fontSize12,
                          fontWeight: TrackletTypography.weightExtraBold,
                          letterSpacing: TrackletTypography.letterSpacingWide,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: TrackletSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: TrackletColors.adaptiveSurfaceElevated(context),
                        borderRadius: TrackletRadii.roundedCardLg,
                        border: Border.all(
                          color: TrackletColors.adaptiveCardBorder(context),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            context.go('/profile');
                          },
                          borderRadius: TrackletRadii.roundedCardLg,
                          child: Padding(
                            padding: const EdgeInsets.all(
                              TrackletSpacing.compactLg,
                            ),
                            child: Row(
                              children: [
                                VoxelAvatar(
                                  email: profile.email,
                                  name: profile.name,
                                  avatarSeed: profile.avatarSeed,
                                  size: 46,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.name.isEmpty
                                            ? 'Student User'
                                            : profile.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                              TrackletColors.adaptiveTextPrimary(
                                                context,
                                              ),
                                          fontSize:
                                              TrackletTypography.fontSize14,
                                          fontWeight:
                                              TrackletTypography
                                                  .weightExtraBold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        profile.email.isEmpty
                                            ? 'student@nitc.ac.in'
                                            : profile.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                              TrackletColors.adaptiveTextSecondary(
                                                context,
                                              ),
                                          fontSize:
                                              TrackletTypography.fontSize12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  TrackletIcons.chevronRight,
                                  color: TrackletColors.adaptiveTextMuted(
                                    context,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text(
                        'CAMPUS TRANSIT',
                        style: TextStyle(
                          color: TrackletColors.adaptiveTextMuted(context),
                          fontSize: TrackletTypography.fontSize10,
                          fontWeight: TrackletTypography.weightExtraBold,
                          letterSpacing:
                              TrackletTypography.letterSpacingExpanded,
                        ),
                      ),
                    ),
                    _drawerItem(
                      context: context,
                      icon: TrackletIcons.map,
                      title: 'Live Campus Map',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/map');
                      },
                    ),
                    _drawerItem(
                      context: context,
                      icon: TrackletIcons.calendar,
                      title: 'Bus Timetable & Schedule',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/schedule');
                      },
                    ),
                    _drawerItem(
                      context: context,
                      icon: TrackletIcons.notifications,
                      title: 'Announcements & Inbox',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/notifications');
                      },
                    ),
                    _drawerItem(
                      context: context,
                      icon: TrackletIcons.clock,
                      title: 'Boarding Reminders',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/reminders');
                      },
                    ),
                    if (isAdmin) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          'ADMIN CONTROLS',
                          style: TextStyle(
                            color: TrackletColors.adaptiveTextMuted(context),
                            fontSize: TrackletTypography.fontSize10,
                            fontWeight: TrackletTypography.weightExtraBold,
                            letterSpacing:
                                TrackletTypography.letterSpacingExpanded,
                          ),
                        ),
                      ),
                      _drawerItem(
                        context: context,
                        icon: TrackletIcons.shield,
                        title: 'Admin Control Panel',
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/admin');
                        },
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'PREFERENCES & SUPPORT',
                        style: TextStyle(
                          color: TrackletColors.adaptiveTextMuted(context),
                          fontSize: TrackletTypography.fontSize10,
                          fontWeight: TrackletTypography.weightExtraBold,
                          letterSpacing:
                              TrackletTypography.letterSpacingExpanded,
                        ),
                      ),
                    ),
                    _drawerItem(
                      context: context,
                      icon: TrackletIcons.slidersHorizontal,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/profile');
                      },
                    ),
                    _drawerItem(
                      context: context,
                      icon: TrackletIcons.alertCircle,
                      title: 'Report Errors/Bugs',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/bug-report');
                      },
                    ),
                    _drawerItem(
                      context: context,
                      icon: TrackletIcons.sparkles,
                      title: 'Suggest a Feature',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/feature-suggestion');
                      },
                    ),
                    _drawerItem(
                      context: context,
                      icon: TrackletIcons.helpCircle,
                      title: 'About & Information',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/about');
                      },
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: TrackletColors.adaptiveDivider(context)),
            _drawerItem(
              context: context,
              icon: TrackletIcons.logOut,
              title: 'Log Out',
              onTap: _handleDrawerLogout,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Text(
                'BusTracker v1.0.0 · NITC Bus Tracking',
                style: TextStyle(
                  color: TrackletColors.adaptiveTextSecondary(context),
                  fontSize: TrackletTypography.fontSize11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDrawerLogout() async {
    Navigator.pop(context);
    final authRepo = ref.read(authRepositoryProvider);
    final isGuest = authRepo.currentUser?.isAnonymous ?? false;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: TrackletRadii.roundedLg,
            ),
            backgroundColor: TrackletColors.adaptiveSurface(ctx),
            title: Row(
              children: [
                Container(
                  width: TrackletSpacing.icon,
                  height: TrackletSpacing.icon,
                  decoration: BoxDecoration(
                    color: TrackletColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    TrackletIcons.logOut,
                    color: TrackletColors.primary,
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: TrackletSpacing.md),
                Text(
                  isGuest ? 'Exit Guest Session' : 'Log Out',
                  style: TrackletFonts.outfit(
                    fontSize: TrackletTypography.fontSize18,
                    fontWeight: FontWeight.bold,
                    color: TrackletColors.adaptiveTextPrimary(ctx),
                  ),
                ),
              ],
            ),
            content: Text(
              isGuest
                  ? 'Are you sure you want to exit your guest session? You can return to guest mode or sign in with your student account anytime.'
                  : 'Are you sure you want to log out of BusTracker on this device?',
              style: TrackletTypography.bodyMedium.copyWith(
                color: TrackletColors.adaptiveTextSecondary(ctx),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: TrackletFonts.outfit(
                    color: TrackletColors.adaptiveTextSecondary(ctx),
                    fontWeight: TrackletTypography.weightSemiBold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TrackletColors.primary,
                  foregroundColor: TrackletColors.textInverse,
                  shape: const RoundedRectangleBorder(
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                  elevation: TrackletShadows.elevationLevel0,
                ),
                child: Text(
                  isGuest ? 'Exit Guest Mode' : 'Log Out',
                  style: TrackletFonts.outfit(
                    fontWeight: TrackletTypography.weightSemiBold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await ref.read(authRepositoryProvider).signOut();
      } catch (_) {}
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Widget _drawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: TrackletSpacing.section,
    ),
    minLeadingWidth: 24,
    leading: Icon(
      icon,
      color: TrackletColors.adaptiveTextSecondary(context),
      size: 21,
    ),
    title: Text(
      title,
      style: TextStyle(
        color: TrackletColors.adaptiveTextPrimary(context),
        fontSize: TrackletTypography.fontSize14,
        fontWeight: TrackletTypography.weightSemiBold,
      ),
    ),
    onTap: onTap,
  );
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({
    required this.scaffoldKey,
    required this.profile,
    required this.onProfilePressed,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final Profile profile;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadCountAsync.value ?? 0;
    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? TrackletColors.darkBackground : TrackletColors.background,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(TrackletRadii.avatar),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Row(
            children: [
              _HeaderButton(
                icon: TrackletIcons.menu,
                onTap: () => scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(width: 12),
              Image.asset(
                'assets/branding/bustracker_bus_icon.png',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BusTracker',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            isDark
                                ? TrackletColors.darkTextPrimary
                                : TrackletColors.textPrimary,
                        fontSize: TrackletTypography.fontSize20,
                        fontWeight: TrackletTypography.weightExtraBold,
                        letterSpacing: TrackletTypography.letterSpacingDisplay,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'NIT Calicut',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            isDark
                                ? TrackletColors.darkTextSecondary
                                : TrackletColors.textSecondary,
                        fontSize: TrackletTypography.fontSize12,
                        fontWeight: TrackletTypography.weightSemiBold,
                        letterSpacing: TrackletTypography.letterSpacingSubtle,
                      ),
                    ),
                  ],
                ),
              ),
              if (MediaQuery.sizeOf(context).width > 360) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TrackletSpacing.compactMd,
                    vertical: TrackletSpacing.compact,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? TrackletColors.darkSurfaceElevated.withValues(
                              alpha: 0.85,
                            )
                            : TrackletColors.pure.withValues(alpha: 0.75),
                    borderRadius: TrackletRadii.roundedPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        TrackletIcons.circle,
                        color: TrackletColors.busLive,
                        size: 7,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'CAMPUS',
                        style: TextStyle(
                          color:
                              isDark
                                  ? TrackletColors.darkTextSecondary
                                  : TrackletColors.textSecondary,
                          fontSize: TrackletTypography.fontSize9,
                          fontWeight: TrackletTypography.weightExtraBold,
                          letterSpacing:
                              TrackletTypography.letterSpacingEmphasis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _HeaderButton(
                    icon: TrackletIcons.notifications,
                    onTap: () => context.push('/notifications'),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(TrackletSpacing.xs),
                        decoration: const BoxDecoration(
                          color: TrackletColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: TrackletColors.textInverse,
                            fontSize: TrackletTypography.fontSize9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onProfilePressed,
                  customBorder: const CircleBorder(),
                  child: VoxelAvatar(
                    email: profile.email,
                    name: profile.name,
                    avatarSeed: profile.avatarSeed,
                    size: 44,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardingStopCard extends StatelessWidget {
  const _BoardingStopCard({
    required this.boardingStop,
    required this.distanceMeters,
    required this.walkingMinutes,
    required this.isAutoSelected,
    required this.isLoadingLocation,
    required this.isOutsideCampus,
    required this.onLocate,
    required this.onChange,
    this.onResetToAuto,
  });

  final Stop boardingStop;
  final double? distanceMeters;
  final int? walkingMinutes;
  final bool isAutoSelected;
  final bool isLoadingLocation;
  final bool isOutsideCampus;
  final VoidCallback onLocate;
  final VoidCallback onChange;
  final VoidCallback? onResetToAuto;

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        distanceMeters != null && walkingMinutes != null && !isOutsideCampus;

    final Widget statusWidget;
    if (isAutoSelected && hasLocation) {
      statusWidget = Row(
        children: [
          Icon(
            TrackletIcons.radar,
            size: 14,
            color: TrackletColors.adaptiveTextSecondary(context),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Automatically selected using your location',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: TrackletColors.adaptiveTextSecondary(context),
                fontSize: TrackletTypography.fontSize12,
                fontWeight: TrackletTypography.weightMedium,
              ),
            ),
          ),
        ],
      );
    } else if (!isAutoSelected) {
      statusWidget = Row(
        children: [
          Icon(
            TrackletIcons.mousePointer,
            size: 14,
            color: TrackletColors.adaptiveTextSecondary(context),
          ),
          const SizedBox(width: 6),
          Text(
            'Selected manually',
            style: TextStyle(
              color: TrackletColors.adaptiveTextSecondary(context),
              fontSize: TrackletTypography.fontSize12,
              fontWeight: TrackletTypography.weightMedium,
            ),
          ),
          if (onResetToAuto != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onResetToAuto,
              borderRadius: TrackletRadii.roundedCompact,
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: TrackletSpacing.xs,
                  vertical: TrackletSpacing.xxs,
                ),
                child: Text(
                  '· Reset to GPS',
                  style: TextStyle(
                    color: TrackletColors.primary,
                    fontSize: TrackletTypography.fontSize12,
                    fontWeight: TrackletTypography.weightBold,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    } else if (isOutsideCampus) {
      statusWidget = Row(
        children: [
          Icon(
            TrackletIcons.globe2,
            size: 14,
            color: TrackletColors.adaptiveTextSecondary(context),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Default boarding stop',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: TrackletColors.adaptiveTextSecondary(context),
                fontSize: TrackletTypography.fontSize12,
                fontWeight: TrackletTypography.weightMedium,
              ),
            ),
          ),
        ],
      );
    } else {
      statusWidget = Row(
        children: [
          Icon(
            isLoadingLocation ? TrackletIcons.clock : TrackletIcons.compass,
            size: 14,
            color: TrackletColors.adaptiveTextSecondary(context),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isLoadingLocation
                  ? 'Finding your nearest stop…'
                  : 'Choose a stop near you',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: TrackletColors.adaptiveTextSecondary(context),
                fontSize: TrackletTypography.fontSize12,
                fontWeight: TrackletTypography.weightMedium,
              ),
            ),
          ),
          if (!isLoadingLocation) ...[
            TextButton.icon(
              onPressed: onLocate,
              style: TextButton.styleFrom(
                foregroundColor: TrackletColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: TrackletSpacing.sm,
                  vertical: TrackletSpacing.xs,
                ),
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(TrackletIcons.locateFixed, size: 14),
              label: const Text(
                'Locate',
                style: TextStyle(
                  fontSize: TrackletTypography.fontSize12,
                  fontWeight: TrackletTypography.weightBold,
                ),
              ),
            ),
          ],
        ],
      );
    }

    final isDark = TrackletColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.lg,
        vertical: TrackletSpacing.md,
      ),
      decoration: BoxDecoration(
        color: TrackletColors.adaptiveSurfaceElevated(context),
        borderRadius: TrackletRadii.roundedCardLg,
        border: Border.all(color: TrackletColors.adaptiveCardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      TrackletIcons.mapPin,
                      size: 14,
                      color: TrackletColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'BOARDING STOP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TrackletColors.adaptiveTextSecondary(context),
                          fontSize: TrackletTypography.fontSize11,
                          fontWeight: TrackletTypography.weightExtraBold,
                          letterSpacing: TrackletTypography.letterSpacingWide,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onChange,
                style: TextButton.styleFrom(
                  foregroundColor: TrackletColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: TrackletSpacing.compactMd,
                    vertical: TrackletSpacing.compact,
                  ),
                  minimumSize: const Size(48, 48),
                  backgroundColor: TrackletColors.primary.withValues(
                    alpha: 0.08,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: TrackletRadii.roundedInput,
                  ),
                ),
                icon: const Icon(TrackletIcons.arrowRightLeft, size: 16),
                label: const Text(
                  'Change',
                  style: TextStyle(
                    fontSize: TrackletTypography.fontSize13,
                    fontWeight: TrackletTypography.weightBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? TrackletColors.permissionBlueBgDark
                          : TrackletColors.locationBlueBg,
                  borderRadius: TrackletRadii.roundedCard,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  TrackletIcons.locateFixed,
                  color: TrackletColors.permissionBlueIcon,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      boardingStop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: TrackletColors.adaptiveTextPrimary(context),
                        fontSize: TrackletTypography.fontSize18,
                        fontWeight: TrackletTypography.weightExtraBold,
                        letterSpacing: TrackletTypography.letterSpacingTitle,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (hasLocation)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            TrackletIcons.footprints,
                            size: 13,
                            color: TrackletColors.adaptiveTextSecondary(
                              context,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '${TransitFormatter.formatDistance(distanceMeters!)} away · ~${TransitFormatter.formatWalkingTime(walkingMinutes!)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: TrackletColors.adaptiveTextSecondary(
                                  context,
                                ),
                                fontSize: TrackletTypography.fontSize13,
                                fontWeight: TrackletTypography.weightMedium,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (isOutsideCampus)
                      Text(
                        'Location is outside the campus service area',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TrackletColors.adaptiveTextSecondary(context),
                          fontSize: TrackletTypography.fontSize12,
                          fontWeight: TrackletTypography.weightMedium,
                        ),
                      )
                    else if (isLoadingLocation)
                      Text(
                        'Finding your nearest stop…',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TrackletColors.adaptiveTextSecondary(context),
                          fontSize: TrackletTypography.fontSize12,
                          fontWeight: TrackletTypography.weightMedium,
                        ),
                      )
                    else
                      Text(
                        'Turn on location to find your nearest stop',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TrackletColors.adaptiveTextSecondary(context),
                          fontSize: TrackletTypography.fontSize12,
                          fontWeight: TrackletTypography.weightMedium,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          statusWidget,
        ],
      ),
    );
  }
}

class _LiveBusesSection extends ConsumerWidget {
  const _LiveBusesSection({
    required this.boardingStop,
    required this.stops,
    required this.routes,
    required this.fallbackBuses,
    required this.onOpenMapWithBus,
    required this.onOpenStopSelector,
    required this.reduceMotion,
  });

  final Stop boardingStop;
  final List<Stop> stops;
  final List<BusRoute> routes;
  final List<Bus> fallbackBuses;
  final ValueChanged<Bus> onOpenMapWithBus;
  final VoidCallback onOpenStopSelector;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveTransit = ref.watch(liveTransitPollingProvider);
    final progressAsync = ref.watch(activeBusesProgressProvider);
    final progressByBusId =
        progressAsync.value ?? const <String, BusStopProgress?>{};
    final clockNow = ref.watch(homeClockProvider).value ?? DateTime.now();

    final buses =
        liveTransit.lastSuccessfulUpdate != null
            ? liveTransit.buses
            : (liveTransit.buses.isNotEmpty
                ? liveTransit.buses
                : fallbackBuses);

    final routesById = {for (final route in routes) route.id: route};

    final relevantBuses = filterRelevantBusesForStop(
      boardingStop: boardingStop,
      buses: buses,
      routesById: routesById,
      progressByBusId: progressByBusId,
      clock: () => clockNow,
    );

    if (relevantBuses.isEmpty) {
      return _NoBusesApproachingCard(
        stopName: boardingStop.name,
        onChangeStop: onOpenStopSelector,
        onRefresh: () {
          ref.invalidate(homeStateProvider);
          ref.read(liveTransitPollingProvider.notifier).refresh(force: true);
        },
      );
    }

    final primaryArrival = relevantBuses.firstOrNull;
    final nextBusCard = NextBusCard(
      selectedStop: boardingStop,
      arrival: primaryArrival,
      stops: stops,
      busProgress: primaryArrival?.progress,
      onTrackPressed:
          primaryArrival == null
              ? () => context.go('/map')
              : () => onOpenMapWithBus(primaryArrival.bus),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'Buses approaching your stop',
                style: TextStyle(
                  color: TrackletColors.adaptiveTextPrimary(context),
                  fontSize: TrackletTypography.fontSize19,
                  fontWeight: TrackletTypography.weightExtraBold,
                  letterSpacing: TrackletTypography.letterSpacingHeading,
                ),
              ),
            ),
            _LiveTrackingBadge(
              isRefreshing: liveTransit.isRefreshing,
              hasActiveError: liveTransit.error != null,
              hasLiveBuses: buses.any(
                (b) => !b.isStale && b.status == BusStatus.live,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        reduceMotion
            ? nextBusCard
            : RepaintBoundary(
              child: nextBusCard
                  .animate()
                  .fadeIn(
                    delay: TrackletMotion.fast,
                    duration: TrackletMotion.medium,
                    curve: TrackletMotion.easeOut,
                  )
                  .slideY(
                    begin: 0.06,
                    duration: TrackletMotion.medium,
                    curve: TrackletMotion.easeOut,
                  ),
            ),
        if (relevantBuses.length > 1) ...[
          const SizedBox(height: TrackletSpacing.lg),
          NextBusesCard(
            title: 'Other live buses',
            subtitle: 'Additional buses serving your stop',
            stopName: boardingStop.name,
            estimates: relevantBuses.sublist(1),
            routes: routes,
            onBusTap: onOpenMapWithBus,
          ),
        ],
      ],
    );
  }
}

class _ScheduledDeparturesSection extends ConsumerWidget {
  const _ScheduledDeparturesSection({
    required this.boardingStop,
    required this.scheduledDepartures,
    required this.routes,
  });

  final Stop boardingStop;
  final List<ScheduledDeparture> scheduledDepartures;
  final List<BusRoute> routes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clockNow = ref.watch(homeClockProvider).value ?? DateTime.now();
    final upcomingDepartures = upcomingDeparturesForStop(
      stop: boardingStop,
      departures: scheduledDepartures,
      routes: routes,
      now: clockNow,
    );

    if (upcomingDepartures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: TrackletSpacing.xl),
      child: NextBusesCard(
        title: 'Scheduled departures',
        stopName: boardingStop.name,
        scheduledDepartures: upcomingDepartures,
        routes: routes,
        onViewSchedule:
            () => context.push('/schedule?stopId=${boardingStop.id}'),
      ),
    );
  }
}

class _NoBusesApproachingCard extends StatelessWidget {
  const _NoBusesApproachingCard({
    required this.stopName,
    required this.onChangeStop,
    required this.onRefresh,
  });

  final String stopName;
  final VoidCallback onChangeStop;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TrackletSpacing.section),
      decoration: BoxDecoration(
        color: TrackletColors.adaptiveSurfaceElevated(context),
        borderRadius: TrackletRadii.roundedXl,
        border: Border.all(color: TrackletColors.adaptiveCardBorder(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  isDark
                      ? TrackletColors.primaryContainerDark
                      : TrackletColors.background2,
              borderRadius: TrackletRadii.roundedButton,
            ),
            child: const Icon(
              TrackletIcons.bus,
              color: TrackletColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No buses approaching this stop',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TrackletColors.adaptiveTextPrimary(context),
              fontSize: TrackletTypography.fontSize16,
              fontWeight: TrackletTypography.weightBold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'There are no active buses currently expected to reach $stopName right now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TrackletColors.adaptiveTextSecondary(context),
              fontSize: TrackletTypography.fontSize13,
              height: TrackletTypography.lineHeightBodyCompact,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onChangeStop,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: TrackletSpacing.compactLg,
                  ),
                  foregroundColor: TrackletColors.primary,
                  side: BorderSide(
                    color: TrackletColors.adaptiveBorder(context),
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: TrackletRadii.roundedCard,
                  ),
                ),
                icon: const Icon(TrackletIcons.arrowRightLeft, size: 16),
                label: const Text('Change stop'),
              ),
              ElevatedButton.icon(
                onPressed: onRefresh,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: TrackletSpacing.compactLg,
                  ),
                  backgroundColor: TrackletColors.primary,
                  foregroundColor: TrackletColors.textInverse,
                  elevation: TrackletShadows.elevationLevel0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: TrackletRadii.roundedCard,
                  ),
                ),
                icon: const Icon(TrackletIcons.refreshCw, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color:
          isDark
              ? TrackletColors.darkSurfaceElevated.withValues(alpha: 0.82)
              : TrackletColors.pure.withValues(alpha: 0.82),
      borderRadius: TrackletRadii.roundedCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: TrackletRadii.roundedCard,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color:
                isDark
                    ? TrackletColors.darkTextPrimary
                    : TrackletColors.textPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _LiveTrackingBadge extends StatelessWidget {
  const _LiveTrackingBadge({
    required this.isRefreshing,
    this.hasActiveError = false,
    this.hasLiveBuses = true,
  });

  final bool isRefreshing;
  final bool hasActiveError;
  final bool hasLiveBuses;

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    final String label;
    final Color color;
    final Color background;

    if (isRefreshing) {
      label = 'Updating…';
      color = TrackletColors.primary;
      background = TrackletColors.primary.withValues(
        alpha: isDark ? 0.2 : 0.08,
      );
    } else if (hasActiveError) {
      label = 'Sync paused';
      color =
          isDark
              ? TrackletColors.onWarningContainerDark
              : TrackletColors.warningStrong;
      background =
          isDark
              ? TrackletColors.warningContainerDark
              : TrackletColors.notificationYellowBg;
    } else if (!hasLiveBuses) {
      label = 'Tracking idle';
      color =
          isDark
              ? TrackletColors.darkTextSecondary
              : TrackletColors.textSecondary;
      background =
          isDark
              ? TrackletColors.darkSurfaceElevated
              : TrackletColors.background2;
    } else {
      label = 'Live tracking';
      color = isDark ? TrackletColors.busLiveTextDark : TrackletColors.busLive;
      background =
          isDark ? TrackletColors.busLiveBgDark : TrackletColors.busLiveBg;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.sm,
        vertical: TrackletSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: TrackletRadii.roundedInput,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRefreshing) ...[
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(width: 5),
          ] else ...[
            Icon(TrackletIcons.circle, size: 7, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: TrackletTypography.fontSize11,
              fontWeight: TrackletTypography.weightBold,
            ),
          ),
        ],
      ),
    );
  }
}
