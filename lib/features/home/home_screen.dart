import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatting/transit_formatter.dart';
import '../../data/profile/profile.dart';
import '../../data/transit/bus.dart';
import '../../data/transit/bus_route.dart';
import '../../data/transit/stop.dart';
import '../../design_system/components/tracklet_error_state.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../services/location/location_service.dart';
import '../map/providers/map_state_provider.dart';
import 'home_transit_logic.dart';
import 'providers/home_provider.dart';
import 'widgets/live_bus_route_preview.dart';
import 'widgets/next_bus_card.dart';
import 'widgets/next_buses_card.dart';

/// Campus transit dashboard with a route-aware arrival and live map entry.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _destinationFocusNode = FocusNode();
  String _destinationQuery = '';
  Stop? _destinationStop;
  bool _showStopSuggestions = false;
  DateTime _clockNow = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _destinationFocusNode.addListener(_handleDestinationFocusChange);
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _clockNow = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(locationStateProvider.notifier).refreshLocationIfPermitted();
      }
    });
  }

  void _handleDestinationFocusChange() {
    if (!mounted) return;
    setState(() {
      if (_destinationFocusNode.hasFocus && _destinationQuery.isNotEmpty) {
        _showStopSuggestions = true;
      } else if (!_destinationFocusNode.hasFocus) {
        _showStopSuggestions = false;
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _destinationFocusNode.removeListener(_handleDestinationFocusChange);
    _destinationController.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeStateAsync = ref.watch(homeStateProvider);
    final liveBusesAsync = ref.watch(activeBusesStreamProvider);
    final locationState = ref.watch(locationStateProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: TrackletColors.background,
      drawer: homeStateAsync.maybeWhen(
        data: (state) => _buildDrawer(context, state.userProfile),
        orElse: () => null,
      ),
      body: homeStateAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: TrackletColors.primary),
            ),
        error:
            (error, stack) => SafeArea(
              child: TrackletErrorState(
                message: 'Unable to load campus buses',
                onRetry: () => ref.invalidate(homeStateProvider),
              ),
            ),
        data: (state) {
          final profile = state.userProfile;
          final firstName =
              profile.name.isNotEmpty
                  ? profile.name.split(' ').first
                  : 'Student';
          final buses = liveBusesAsync.value ?? state.buses;
          final stops =
              state.stops.isNotEmpty ? state.stops : [state.selectedStop];
          final nearestStop =
              locationState.currentLocation == null
                  ? null
                  : nearestStopTo(locationState.currentLocation!, stops);
          final boardingStop =
              nearestStop ??
              stops
                  .where((stop) => stop.id == state.selectedStop.id)
                  .firstOrNull ??
              stops.first;
          final nearestStopDistanceMeters =
              nearestStop == null
                  ? null
                  : locationState.currentLocation!.distanceToMeters(
                    nearestStop.location,
                  );
          final walkTimeMinutes =
              nearestStopDistanceMeters == null
                  ? null
                  : estimateWalkMinutes(nearestStopDistanceMeters);
          final matchingStops = _matchingStops(stops);
          final destinationStop =
              _destinationStop == null
                  ? null
                  : stops
                      .where((stop) => stop.id == _destinationStop!.id)
                      .firstOrNull;
          final arrival = estimateNextBus(
            stop: boardingStop,
            buses: buses,
            routes: state.routes,
          );
          final eligibleBuses =
              buses.where((bus) {
                  final route =
                      state.routes
                          .where((item) => item.id == bus.routeId)
                          .firstOrNull;
                  return bus.status != BusStatus.offline &&
                      route != null &&
                      route.stopIds.contains(boardingStop.id) &&
                      bus.id != arrival?.bus.id;
                }).toList()
                ..sort(
                  (a, b) => _etaFor(
                    a,
                    boardingStop,
                    state.routes,
                  ).compareTo(_etaFor(b, boardingStop, state.routes)),
                );
          final upcomingDepartures = upcomingDeparturesForStop(
            stop: boardingStop,
            departures: state.scheduledDepartures,
            routes: state.routes,
            now: _clockNow,
          );
          final scheduledNext =
              arrival == null ? upcomingDepartures.firstOrNull : null;
          final scheduledRoute =
              scheduledNext == null
                  ? null
                  : state.routes
                      .where((route) => route.id == scheduledNext.routeId)
                      .firstOrNull;
          final previewRoute =
              arrival?.route ??
              scheduledRoute ??
              state.routes
                  .where((route) => route.stopIds.contains(boardingStop.id))
                  .firstOrNull;
          final reduceMotion = MediaQuery.disableAnimationsOf(context);
          final header = _DashboardHeader(
            scaffoldKey: _scaffoldKey,
            profile: profile,
            firstName: firstName,
            destinationController: _destinationController,
            destinationFocusNode: _destinationFocusNode,
            query: _destinationQuery,
            suggestions: matchingStops,
            hasLocation: locationState.currentLocation != null,
            isLocationLoading: locationState.isLoading,
            showSuggestions: _showStopSuggestions,
            onQueryChanged: _updateDestinationQuery,
            onSearchTapped: _openStopSuggestions,
            onStopSelected: _selectDestination,
            onClearSearch: _clearDestinationSearch,
            onUseLocation: _requestLocation,
            onProfilePressed: () => context.go('/profile'),
          );
          final headerWidget =
              reduceMotion
                  ? header
                  : header
                      .animate()
                      .fadeIn(duration: 380.ms)
                      .slideY(begin: -0.025);
          final nextBusCard = NextBusCard(
            selectedStop: boardingStop,
            arrival: arrival,
            scheduledDeparture: scheduledNext,
            scheduledRoute: scheduledRoute,
            isNearestStop: locationState.currentLocation != null,
            routePreview: LiveBusRoutePreview(
              route: previewRoute,
              stop: boardingStop,
              stops: stops,
              bus: arrival?.bus,
              destinationStop: destinationStop,
            ),
            onTrackPressed:
                arrival == null
                    ? () => context.go('/map')
                    : () => _openMapWithBus(arrival.bus),
          );
          final nextBusWidget =
              reduceMotion
                  ? nextBusCard
                  : nextBusCard
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 420.ms)
                      .slideY(begin: 0.06, curve: Curves.easeOutCubic);

          return RefreshIndicator(
            color: TrackletColors.primary,
            onRefresh: () async {
              ref.invalidate(homeStateProvider);
              await ref.read(homeStateProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: headerWidget),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NearestStopSummary(
                          nearestStop: nearestStop,
                          fallbackStop: boardingStop,
                          distanceMeters: nearestStopDistanceMeters,
                          walkingMinutes: walkTimeMinutes,
                          isLoading: locationState.isLoading,
                          onUseLocation: _requestLocation,
                        ),
                        const SizedBox(height: TrackletSpacing.lg),
                        const Text(
                          'Your next ride',
                          style: TextStyle(
                            color: TrackletColors.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        nextBusWidget,
                        if (state.usesSimulatedTelemetry) ...[
                          const SizedBox(height: TrackletSpacing.sm),
                          const _SimulationNotice(),
                        ],
                        const SizedBox(height: TrackletSpacing.lg),
                        NextBusesCard(
                          stopName: boardingStop.name,
                          buses: eligibleBuses,
                          scheduledDepartures:
                              eligibleBuses.isEmpty
                                  ? upcomingDepartures
                                  : const [],
                          routes: state.routes,
                          onBusTap: _openMapWithBus,
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

  List<Stop> _matchingStops(List<Stop> stops) {
    final query = _destinationQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final matches =
        stops.where((stop) {
          return stop.name.toLowerCase().contains(query) ||
              stop.code.toLowerCase().contains(query);
        }).toList();
    matches.sort((a, b) {
      final aStartsWith =
          a.name.toLowerCase().startsWith(query) ||
          a.code.toLowerCase().startsWith(query);
      final bStartsWith =
          b.name.toLowerCase().startsWith(query) ||
          b.code.toLowerCase().startsWith(query);
      if (aStartsWith != bStartsWith) return aStartsWith ? -1 : 1;
      return a.orderIndex.compareTo(b.orderIndex);
    });
    return matches.take(5).toList();
  }

  void _updateDestinationQuery(String query) {
    setState(() {
      _destinationQuery = query;
      _destinationStop = null;
      _showStopSuggestions = query.trim().isNotEmpty;
    });
  }

  void _openStopSuggestions() {
    if (_destinationQuery.trim().isNotEmpty && !_showStopSuggestions) {
      setState(() => _showStopSuggestions = true);
    }
  }

  void _selectDestination(Stop stop) {
    setState(() {
      _destinationStop = stop;
      _destinationQuery = stop.name;
      _showStopSuggestions = false;
    });
    _destinationController.value = TextEditingValue(
      text: stop.name,
      selection: TextSelection.collapsed(offset: stop.name.length),
    );
    _destinationFocusNode.unfocus();
  }

  void _clearDestinationSearch() {
    setState(() {
      _destinationStop = null;
      _destinationQuery = '';
      _showStopSuggestions = false;
    });
    _destinationController.clear();
    _destinationFocusNode.requestFocus();
  }

  int _etaFor(Bus bus, Stop stop, List<BusRoute> routes) {
    final result = estimateNextBus(stop: stop, buses: [bus], routes: routes);
    return result?.etaMinutes ?? 60;
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
    return Drawer(
      backgroundColor: TrackletColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: Text(
                'Account Options',
                style: TextStyle(
                  color: TrackletColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: TrackletColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: TrackletColors.cardBorder),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/profile');
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 23,
                          backgroundColor: TrackletColors.background2,
                          child: Text(
                            _getInitials(profile.name),
                            style: const TextStyle(
                              color: TrackletColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name.isEmpty
                                    ? 'Student User'
                                    : profile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: TrackletColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.email.isEmpty
                                    ? 'student@nitc.ac.in'
                                    : profile.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: TrackletColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: TrackletColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'CAMPUS',
                style: TextStyle(
                  color: TrackletColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            _drawerItem(
              icon: Icons.map_outlined,
              title: 'Live Campus Map',
              onTap: () {
                Navigator.pop(context);
                context.go('/map');
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'PREFERENCES & SUPPORT',
                style: TextStyle(
                  color: TrackletColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            _drawerItem(
              icon: Icons.tune_rounded,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
            _drawerItem(
              icon: Icons.error_outline_rounded,
              title: 'Report Errors/Bugs',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening bug report form...')),
                );
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            _drawerItem(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              onTap: () {
                Navigator.pop(context);
                context.go('/auth/login');
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Text(
                'Tracklet v1.0.0 · NITC Bus Tracking',
                style: TextStyle(
                  color: TrackletColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    minLeadingWidth: 24,
    leading: Icon(icon, color: TrackletColors.textSecondary, size: 21),
    title: Text(
      title,
      style: const TextStyle(
        color: TrackletColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    onTap: onTap,
  );

  static String _getInitials(String name) {
    if (name.trim().isEmpty) return 'SC';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length.clamp(1, 2))
          .toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _NearestStopSummary extends StatelessWidget {
  const _NearestStopSummary({
    required this.nearestStop,
    required this.fallbackStop,
    required this.distanceMeters,
    required this.walkingMinutes,
    required this.isLoading,
    required this.onUseLocation,
  });

  final Stop? nearestStop;
  final Stop fallbackStop;
  final double? distanceMeters;
  final int? walkingMinutes;
  final bool isLoading;
  final VoidCallback onUseLocation;

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        nearestStop != null && distanceMeters != null && walkingMinutes != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TrackletColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TrackletColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasLocation ? 'Nearest bus stop' : 'Default boarding stop',
            style: const TextStyle(
              color: TrackletColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: TrackletColors.locationBlueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.location_on_outlined,
                  color: TrackletColors.permissionBlueIcon,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLocation ? nearestStop!.name : fallbackStop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TrackletColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasLocation
                          ? '~${TransitFormatter.formatDistance(distanceMeters!)} straight-line distance'
                          : isLoading
                          ? 'Finding your nearest stop…'
                          : 'Turn on location to find your nearest stop',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TrackletColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasLocation)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      TransitFormatter.formatWalkingTime(walkingMinutes!),
                      style: const TextStyle(
                        color: TrackletColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'approx.',
                      style: TextStyle(
                        color: TrackletColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                )
              else
                TextButton.icon(
                  onPressed: isLoading ? null : onUseLocation,
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.my_location_rounded, size: 16),
                  label: Text(isLoading ? 'Locating' : 'Locate'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 40),
                    foregroundColor: TrackletColors.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.scaffoldKey,
    required this.profile,
    required this.firstName,
    required this.destinationController,
    required this.destinationFocusNode,
    required this.query,
    required this.suggestions,
    required this.hasLocation,
    required this.isLocationLoading,
    required this.showSuggestions,
    required this.onQueryChanged,
    required this.onSearchTapped,
    required this.onStopSelected,
    required this.onClearSearch,
    required this.onUseLocation,
    required this.onProfilePressed,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final Profile profile;
  final String firstName;
  final TextEditingController destinationController;
  final FocusNode destinationFocusNode;
  final String query;
  final List<Stop> suggestions;
  final bool hasLocation;
  final bool isLocationLoading;
  final bool showSuggestions;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSearchTapped;
  final ValueChanged<Stop> onStopSelected;
  final VoidCallback onClearSearch;
  final VoidCallback onUseLocation;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final initials =
        profile.name.trim().isEmpty
            ? 'SC'
            : profile.name
                .trim()
                .split(RegExp(r'\s+'))
                .take(2)
                .map((part) => part[0].toUpperCase())
                .join();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE5F1FF), TrackletColors.background],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, TrackletSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeaderButton(
                    icon: Icons.menu_rounded,
                    onTap: () => scaffoldKey.currentState?.openDrawer(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: TrackletColors.busLive,
                          size: 7,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'NITC CAMPUS',
                          style: TextStyle(
                            color: TrackletColors.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: TrackletColors.primaryBackground,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onProfilePressed,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: TrackletColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TrackletSpacing.md),
              Text(
                '${_greeting()}, $firstName',
                style: const TextStyle(
                  color: TrackletColors.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),
              const Text(
                'Where are you headed?',
                style: TextStyle(
                  color: TrackletColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: TrackletSpacing.sm),
              _StopSearchField(
                controller: destinationController,
                focusNode: destinationFocusNode,
                query: query,
                suggestions: suggestions,
                hasLocation: hasLocation,
                isLocationLoading: isLocationLoading,
                showSuggestions: showSuggestions,
                onQueryChanged: onQueryChanged,
                onSearchTapped: onSearchTapped,
                onStopSelected: onStopSelected,
                onClear: onClearSearch,
                onUseLocation: onUseLocation,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _StopSearchField extends StatelessWidget {
  const _StopSearchField({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.suggestions,
    required this.hasLocation,
    required this.isLocationLoading,
    required this.showSuggestions,
    required this.onQueryChanged,
    required this.onSearchTapped,
    required this.onStopSelected,
    required this.onClear,
    required this.onUseLocation,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final List<Stop> suggestions;
  final bool hasLocation;
  final bool isLocationLoading;
  final bool showSuggestions;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSearchTapped;
  final ValueChanged<Stop> onStopSelected;
  final VoidCallback onClear;
  final VoidCallback onUseLocation;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final showResults = showSuggestions && query.trim().isNotEmpty;

    return AnimatedContainer(
      duration:
          reducedMotion ? Duration.zero : const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: TrackletColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              focusNode.hasFocus
                  ? TrackletColors.primary
                  : TrackletColors.cardBorder,
          width: focusNode.hasFocus ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 15),
                const Icon(
                  Icons.search_rounded,
                  color: TrackletColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onQueryChanged,
                    onTap: onSearchTapped,
                    onSubmitted: (_) {
                      if (suggestions.isNotEmpty) {
                        onStopSelected(suggestions.first);
                      }
                    },
                    textInputAction: TextInputAction.search,
                    textCapitalization: TextCapitalization.words,
                    autocorrect: false,
                    style: const TextStyle(
                      color: TrackletColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search a campus stop',
                      hintStyle: TextStyle(
                        color: TrackletColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (query.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: TrackletColors.textSecondary,
                      size: 19,
                    ),
                  )
                else
                  const SizedBox(width: 4),
                IconButton(
                  tooltip:
                      isLocationLoading
                          ? 'Getting your location'
                          : hasLocation
                          ? 'Refresh my location'
                          : 'Use my location',
                  onPressed: isLocationLoading ? null : onUseLocation,
                  icon:
                      isLocationLoading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: TrackletColors.primary,
                            ),
                          )
                          : Icon(
                            Icons.my_location_rounded,
                            color:
                                hasLocation
                                    ? TrackletColors.busLive
                                    : TrackletColors.textSecondary,
                            size: 19,
                          ),
                ),
              ],
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration:
                  reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration:
                    reducedMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder:
                    (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.035),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                child:
                    showResults
                        ? Column(
                          key: const ValueKey('stop-suggestions-open'),
                          children: [
                            const Divider(
                              height: 1,
                              color: TrackletColors.border,
                            ),
                            if (suggestions.isEmpty)
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'No matching campus stops',
                                    style: TextStyle(
                                      color: TrackletColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            else
                              for (
                                var index = 0;
                                index < suggestions.length;
                                index++
                              ) ...[
                                if (index > 0)
                                  const Divider(
                                    height: 1,
                                    indent: 48,
                                    color: TrackletColors.border,
                                  ),
                                _StopSuggestionTile(
                                  stop: suggestions[index],
                                  onTap:
                                      () => onStopSelected(suggestions[index]),
                                ),
                              ],
                          ],
                        )
                        : const SizedBox.shrink(
                          key: ValueKey('stop-suggestions-closed'),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopSuggestionTile extends StatelessWidget {
  const _StopSuggestionTile({required this.stop, required this.onTap});

  final Stop stop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: TrackletColors.textSecondary,
              size: 19,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                stop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TrackletColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              stop.code,
              style: const TextStyle(
                color: TrackletColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.82),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: TrackletColors.textPrimary, size: 22),
      ),
    ),
  );
}

class _SimulationNotice extends StatelessWidget {
  const _SimulationNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: TrackletColors.notificationYellowBgLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: TrackletColors.notificationYellowBg),
    ),
    child: const Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: TrackletColors.notificationAmber,
          size: 16,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Demo bus locations are simulated along campus routes.',
            style: TextStyle(
              color: TrackletColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
