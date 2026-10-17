import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/geo/geo_point.dart';
import '../../data/campus/campus_building_repository.dart';
import '../../design_system/components/tracklet_empty_state.dart';
import '../../design_system/components/tracklet_error_state.dart';
import '../../design_system/components/tracklet_skeleton.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/shadows.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../services/maps/map_adapter.dart';
import '../../services/maps/map_config.dart';
import '../../data/preferences/user_preferences.dart';
import '../../data/transit/bus.dart';
import '../../data/transit/bus_eta.dart';
import '../../data/transit/bus_route.dart';
import '../../data/transit/bus_telemetry.dart';
import '../../data/transit/route_stop_occurrence.dart';
import '../../data/transit/stop.dart';
import '../../services/location/location_service.dart';
import '../home/providers/home_provider.dart';
import 'bus_stop_progress.dart';
import 'providers/map_state_provider.dart';
import 'widgets/bus_detail_sheet.dart';
import 'widgets/bus_marker_widget.dart';
import 'widgets/map_controls.dart';
import 'widgets/route_selector_card.dart';
import 'widgets/route_stops_sheet.dart';
import 'widgets/stop_detail_sheet.dart';
import 'widgets/stop_marker_widget.dart';

/// Map-first campus transit screen with lightweight route and stop overlays.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  late final TrackletMapController _mapController;
  bool _isRouteDetailsExpanded = false;
  int _cameraActionGeneration = 0;
  Bus? _selectedBus;
  bool _isBusDetailsExpanded = false;
  String? _followingBusId;
  bool _showRoutes = true;
  int _zoomBucket = 1;
  DateTime? _lastStopEventRefresh;
  bool _hasFittedInitialFleet = false;
  bool _hasUserPannedMap = false;
  int _lastFleetCount = 0;
  bool _userExplicitlySelectedRoute = false;
  final Map<String, double> _previousRouteProgress = {};
  final Map<String, double> _previousSpeedMetersPerSecond = {};

  void _fitFleetBounds(List<GeoPoint> points) {
    if (points.isEmpty) return;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _mapController.animatedFitBounds(
      this,
      points,
      disableAnimations: disableAnimations,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 104,
        left: 48,
        right: 48,
        bottom: MediaQuery.sizeOf(context).height * 0.24,
      ),
    );
  }

  Color _routeColor(BusRoute route) => route.color;

  Color? _busRouteColor(Bus bus, List<BusRoute> routes) {
    final route = routes.where((item) => item.id == bus.routeId).firstOrNull;
    return route == null ? null : _routeColor(route);
  }

  bool _showStopLabel(bool isHub, bool isRouteStop, bool isSelected) =>
      isSelected || isHub || (isRouteStop && _zoomBucket > 0);

  List<MapMarkerData> _routeDirectionMarkers(BusRoute? route) {
    if (!_showRoutes || route == null || !route.isGeometryAvailable) {
      return const [];
    }
    final points = route.path;
    final targetCount =
        _zoomBucket >= 2
            ? 8
            : _zoomBucket == 1
            ? 5
            : 3;
    final segmentLengths = [
      for (var index = 1; index < points.length; index++)
        points[index - 1].distanceToMeters(points[index]),
    ];
    final totalLength = segmentLengths.fold<double>(
      0,
      (sum, length) => sum + length,
    );
    final arrowCount =
        math
            .min(
              targetCount,
              math.max(
                1,
                (totalLength / MapConfig.routeArrowDistanceMeters).ceil(),
              ),
            )
            .toInt();
    final color = _routeColor(route);
    final markers = <MapMarkerData>[];
    for (var arrowIndex = 1; arrowIndex <= arrowCount; arrowIndex++) {
      final targetDistance = totalLength * arrowIndex / (arrowCount + 1);
      var traversed = 0.0;
      var segment = 0;
      while (segment < segmentLengths.length - 1 &&
          traversed + segmentLengths[segment] < targetDistance) {
        traversed += segmentLengths[segment++];
      }
      final from = points[segment];
      final to = points[segment + 1];
      final segmentLength = segmentLengths[segment];
      final fraction =
          segmentLength == 0
              ? 0.0
              : ((targetDistance - traversed) / segmentLength)
                  .clamp(0.0, 1.0)
                  .toDouble();
      final bearing = from.bearingTo(to);
      markers.add(
        MapMarkerData(
          id: 'route-direction-${route.id}-$arrowIndex',
          point: GeoPoint(
            latitude: from.latitude + (to.latitude - from.latitude) * fraction,
            longitude:
                from.longitude + (to.longitude - from.longitude) * fraction,
          ),
          width: 24,
          height: 24,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: bearing * math.pi / 180,
              child: Icon(TrackletIcons.navigation, size: 17, color: color),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  @override
  void initState() {
    super.initState();
    _mapController = TrackletMapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bus = ref.read(mapStateNotifierProvider).selectedBus;
      if (bus != null && _selectedBus?.id != bus.id) {
        _applyBusSelection(bus);
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _handleRecenterUser() async {
    setState(() => _followingBusId = null);
    final locationState = ref.read(locationStateProvider);
    final userLocation = locationState.currentLocation;

    if (userLocation != null && BusTelemetry.isValidPoint(userLocation)) {
      final disableAnimations =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      _mapController.animatedMoveTo(
        this,
        userLocation,
        zoom: MapConfig.defaultZoom,
        disableAnimations: disableAnimations,
      );
      return;
    }

    final point =
        await ref
            .read(locationStateProvider.notifier)
            .requestAndFetchLocation();

    if (!mounted) return;

    if (point != null && BusTelemetry.isValidPoint(point)) {
      final disableAnimations =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      _mapController.animatedMoveTo(
        this,
        point,
        zoom: MapConfig.defaultZoom,
        disableAnimations: disableAnimations,
      );
    } else {
      final updatedState = ref.read(locationStateProvider);
      final perm = updatedState.permissionState;
      final isDeniedForever = perm == LocationPermissionState.deniedForever;
      final isServiceDisabled = perm == LocationPermissionState.serviceDisabled;

      final String message =
          updatedState.errorMessage ??
          (isServiceDisabled
              ? 'Location services are disabled on your device.'
              : isDeniedForever
              ? 'Location permission is denied. Enable it in settings.'
              : 'Unable to get your location.');

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
          action: SnackBarAction(
            label:
                (isDeniedForever || isServiceDisabled) ? 'Settings' : 'Retry',
            onPressed: () {
              if (isDeniedForever) {
                ref.read(locationServiceProvider).openAppSettings();
              } else if (isServiceDisabled) {
                ref.read(locationServiceProvider).openLocationSettings();
              } else {
                _handleRecenterUser();
              }
            },
          ),
        ),
      );
    }
  }

  void _openLegendSheet(Color? routeAccentColor) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Material(
              color: TrackletColors.adaptiveSurfaceElevated(sheetContext),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TrackletSpacing.lg,
                    TrackletSpacing.md,
                    TrackletSpacing.lg,
                    TrackletSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: TrackletColors.adaptiveBorder(sheetContext),
                            borderRadius: TrackletRadii.roundedXs,
                          ),
                        ),
                      ),
                      const SizedBox(height: TrackletSpacing.md),
                      Row(
                        children: [
                          Icon(
                            TrackletIcons.layers,
                            size: 20,
                            color: TrackletColors.adaptiveTextPrimary(
                              sheetContext,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Map Legend',
                            style: Theme.of(
                              sheetContext,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: TrackletColors.adaptiveTextPrimary(
                                sheetContext,
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _showRoutes = !_showRoutes);
                              setSheetState(() {});
                            },
                            icon: Icon(
                              _showRoutes
                                  ? TrackletIcons.eye
                                  : TrackletIcons.eyeOff,
                              size: 16,
                            ),
                            label: Text(
                              _showRoutes ? 'Hide routes' : 'Show routes',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TrackletSpacing.sm),
                      _LegendRow(
                        color: routeAccentColor ?? TrackletColors.routeActive,
                        label: 'Live moving bus',
                      ),
                      const _LegendRow(
                        color: TrackletColors.warningStrong,
                        label: 'Stationary bus',
                      ),
                      _LegendRow(
                        color: routeAccentColor ?? TrackletColors.routeActive,
                        label: 'Selected route',
                      ),
                      _LegendRow(
                        color: TrackletColors.adaptiveTextSecondary(
                          sheetContext,
                        ),
                        label: 'Other routes',
                      ),
                      _LegendRow(
                        color: routeAccentColor ?? TrackletColors.routeActive,
                        label: 'Next stop',
                      ),
                      _LegendRow(
                        color: TrackletColors.adaptiveTextSecondary(
                          sheetContext,
                        ),
                        label: 'Upcoming or visited stop',
                      ),
                      const _LegendRow(
                        color: TrackletColors.busOffline,
                        label: 'Stale or offline bus',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _fitSelectedRouteStops(List<GeoPoint> points) {
    if (points.isEmpty) return;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _mapController.animatedFitBounds(
      this,
      points,
      disableAnimations: disableAnimations,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 104,
        left: 40,
        right: 40,
        bottom: MediaQuery.sizeOf(context).height * 0.24,
      ),
    );
  }

  Future<void> _selectRoute(BusRoute route) async {
    final currentGeneration = ++_cameraActionGeneration;
    _userExplicitlySelectedRoute = true;
    if (_followingBusId != null) {
      setState(() => _followingBusId = null);
    }
    final notifier = ref.read(mapStateNotifierProvider.notifier);
    notifier.clearSelectedBus();
    setState(() {
      _selectedBus = null;
      _isBusDetailsExpanded = false;
    });
    await notifier.selectRoute(route);
    if (!mounted || currentGeneration != _cameraActionGeneration) return;

    setState(() => _isRouteDetailsExpanded = false);
    final state = ref.read(mapStateNotifierProvider);
    final points =
        state.selectedRoute?.isGeometryAvailable == true
            ? state.selectedRoute!.path
            : [
              for (final occurrence in state.selectedRouteStops)
                if (occurrence.stop != null) occurrence.stop!.location,
            ];
    _fitSelectedRouteStops(points);
  }

  Future<void> _openRoutePicker(
    List<BusRoute> routes,
    BusRoute? selectedRoute,
  ) async {
    if (routes.isEmpty) return;
    final route = await showModalBottomSheet<BusRoute>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Material(
          color: TrackletColors.adaptiveSurfaceElevated(sheetContext),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.68,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TrackletSpacing.lg,
                      TrackletSpacing.md,
                      TrackletSpacing.lg,
                      TrackletSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: TrackletColors.adaptiveBorder(sheetContext),
                            borderRadius: TrackletRadii.roundedXs,
                          ),
                        ),
                        const SizedBox(height: TrackletSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Choose a route',
                                style: Theme.of(
                                  sheetContext,
                                ).textTheme.titleLarge?.copyWith(
                                  color: TrackletColors.adaptiveTextPrimary(
                                    sheetContext,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              tooltip: 'Close route selection',
                              icon: Icon(
                                TrackletIcons.x,
                                color: TrackletColors.adaptiveTextSecondary(
                                  sheetContext,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(
                        TrackletSpacing.md,
                        0,
                        TrackletSpacing.md,
                        TrackletSpacing.lg,
                      ),
                      itemCount: routes.length,
                      separatorBuilder:
                          (context, index) => Divider(
                            height: 1,
                            indent: 58,
                            color: TrackletColors.adaptiveDivider(sheetContext),
                          ),
                      itemBuilder: (context, index) {
                        final route = routes[index];
                        final isSelected = route.id == selectedRoute?.id;
                        final subtitle = route.description?.trim();
                        final routeColor = _routeColor(route);

                        return ListTile(
                          key: ValueKey('route-option-${route.id}'),
                          minLeadingWidth: 44,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: TrackletSpacing.sm,
                            vertical: 2,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: routeColor.withValues(alpha: 0.12),
                              borderRadius: TrackletRadii.roundedInput,
                              border: Border.all(
                                color: routeColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              route.code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: routeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            route.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: TrackletColors.adaptiveTextPrimary(
                                sheetContext,
                              ),
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                            ),
                          ),
                          subtitle:
                              subtitle?.isNotEmpty == true
                                  ? Text(
                                    subtitle!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          TrackletColors.adaptiveTextSecondary(
                                            sheetContext,
                                          ),
                                    ),
                                  )
                                  : null,
                          trailing:
                              isSelected
                                  ? Icon(
                                    TrackletIcons.checkCircle2,
                                    color: routeColor,
                                  )
                                  : Icon(
                                    TrackletIcons.chevronRight,
                                    color: TrackletColors.adaptiveTextSecondary(
                                      sheetContext,
                                    ),
                                  ),
                          selected: isSelected,
                          onTap: () => Navigator.pop(sheetContext, route),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (route != null && mounted) await _selectRoute(route);
  }

  void _selectStop(Stop stop) {
    ref.read(mapStateNotifierProvider.notifier).clearSelectedBus();
    setState(() {
      _selectedBus = null;
      _isBusDetailsExpanded = false;
      _followingBusId = null;
    });
    ref.read(mapStateNotifierProvider.notifier).selectStop(stop);
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _mapController.animatedMoveTo(
      this,
      stop.location,
      disableAnimations: disableAnimations,
    );
  }

  void _applyBusSelection(Bus bus) {
    setState(() {
      _selectedBus = bus;
      _isBusDetailsExpanded = false;
      _followingBusId = bus.hasValidLocation ? bus.id : null;
      _isRouteDetailsExpanded = false;
    });
    if (bus.hasValidLocation) {
      final disableAnimations =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      _mapController.animatedMoveTo(
        this,
        bus.position.point,
        disableAnimations: disableAnimations,
      );
    }
  }

  void _selectBus(Bus bus) {
    _applyBusSelection(bus);
    ref.read(mapStateNotifierProvider.notifier).selectBus(bus);
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapStateNotifierProvider);
    final buildingsAsync = ref.watch(campusBuildingsProvider);

    if (mapState.isLoading) {
      return Scaffold(
        backgroundColor: TrackletColors.adaptiveBackground(context),
        body: const TrackletMapSkeleton(),
      );
    }

    if (mapState.hasError) {
      return Scaffold(
        backgroundColor: TrackletColors.adaptiveBackground(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(TrackletSpacing.screenMargin),
            child: TrackletErrorState(
              title: 'Transit map unavailable',
              message:
                  mapState.errorMessage ?? 'Transit data could not be loaded.',
              onRetry:
                  () =>
                      ref
                          .read(mapStateNotifierProvider.notifier)
                          .loadTransitData(),
            ),
          ),
        ),
      );
    }

    if (mapState.isEmpty) {
      return Scaffold(
        backgroundColor: TrackletColors.adaptiveBackground(context),
        body: TrackletEmptyState(
          title: 'No campus stops yet',
          description:
              'Active bus stops will appear here when transit data is available.',
          icon: Icon(
            TrackletIcons.mapPinOff,
            color: TrackletColors.adaptiveTextSecondary(context),
            size: 44,
          ),
          actionLabel: 'Try again',
          onAction:
              () =>
                  ref.read(mapStateNotifierProvider.notifier).loadTransitData(),
        ),
      );
    }

    final labels = ref.watch(mapLabelsProvider);
    final activeStopIds = mapState.activeRouteStopIds;
    final selectedRoute = mapState.selectedRoute;
    final routeAccentColor =
        selectedRoute == null ? null : _routeColor(selectedRoute);
    final locationState = ref.watch(locationStateProvider);
    final userLocation = locationState.currentLocation;
    final preferredStopId = ref.watch(userPreferencesProvider).preferredStopId;

    ref.watch(homeClockProvider);
    final liveBusesAsync = ref.watch(activeBusesStreamProvider);
    final liveBuses = liveBusesAsync.value ?? const [];

    final uniqueBuses = <String, Bus>{};
    for (final bus in liveBuses) {
      if (!bus.hasValidLocation) continue;
      final existing = uniqueBuses[bus.id];
      if (existing == null) {
        uniqueBuses[bus.id] = bus;
      } else {
        final shouldAccept = BusTelemetry.shouldAcceptPacket(
          previousEpoch: existing.position.epoch,
          incomingEpoch: bus.position.epoch,
          previousSequence: existing.position.sequenceNumber,
          previousTimestamp: existing.position.timestamp,
          incomingSequence: bus.position.sequenceNumber,
          incomingTimestamp: bus.position.timestamp,
        );
        if (shouldAccept) {
          uniqueBuses[bus.id] = bus;
        }
      }
    }

    final busList = uniqueBuses.values.toList();
    final clusterOffsets = <String, Alignment>{};
    for (var i = 0; i < busList.length; i++) {
      final busA = busList[i];
      if (clusterOffsets.containsKey(busA.id)) continue;
      final cluster = [busA];
      for (var j = i + 1; j < busList.length; j++) {
        final busB = busList[j];
        if (busA.position.point.distanceToMeters(busB.position.point) < 12.0) {
          cluster.add(busB);
        }
      }
      if (cluster.length == 1) {
        clusterOffsets[busA.id] = Alignment.center;
      } else {
        for (var k = 0; k < cluster.length; k++) {
          final angle = 2 * math.pi * k / cluster.length;
          clusterOffsets[cluster[k].id] = Alignment(
            0.55 * math.cos(angle),
            0.55 * math.sin(angle),
          );
        }
      }
    }

    final validBusPoints = [for (final bus in busList) bus.position.point];

    if (!_hasFittedInitialFleet && validBusPoints.isNotEmpty) {
      _hasFittedInitialFleet = true;
      _lastFleetCount = validBusPoints.length;
      if (!_hasUserPannedMap && _selectedBus == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _fitFleetBounds(validBusPoints);
        });
      }
    }

    ref.listen<Bus?>(mapStateNotifierProvider.select((s) => s.selectedBus), (
      previous,
      next,
    ) {
      if (next != null && next.id != _selectedBus?.id) {
        _applyBusSelection(next);
      } else if (next == null && _selectedBus != null) {
        setState(() {
          _selectedBus = null;
          _isBusDetailsExpanded = false;
          _followingBusId = null;
        });
      }
    });

    ref.listen(activeBusesStreamProvider, (previous, next) {
      final selectedTripId = _selectedBus?.tripId;
      final stopRefreshElapsed =
          _lastStopEventRefresh == null ||
          DateTime.now().difference(_lastStopEventRefresh!) >=
              const Duration(seconds: 15);
      if (selectedTripId != null && stopRefreshElapsed) {
        _lastStopEventRefresh = DateTime.now();
        ref.invalidate(busStopEventsProvider(selectedTripId));
      }
      final followingId = _followingBusId;
      if (followingId != null) {
        final bus =
            next.value
                ?.where((candidate) => candidate.id == followingId)
                .firstOrNull;
        if (bus != null) {
          if (bus.hasValidLocation) {
            _mapController.animatedMoveTo(
              this,
              bus.position.point,
              zoom: null,
              disableAnimations:
                  MediaQuery.maybeDisableAnimationsOf(context) ?? false,
            );
          } else {
            setState(() => _followingBusId = null);
          }
        }
      }

      final newValidBusPoints = [
        for (final bus in next.value ?? const <Bus>[])
          if (bus.hasValidLocation) bus.position.point,
      ];
      final fleetCountChanged = _lastFleetCount != newValidBusPoints.length;
      _lastFleetCount = newValidBusPoints.length;

      if (!_hasUserPannedMap &&
          _selectedBus == null &&
          newValidBusPoints.isNotEmpty) {
        if (!_hasFittedInitialFleet || fleetCountChanged) {
          _hasFittedInitialFleet = true;
          _fitFleetBounds(newValidBusPoints);
        }
      }
    });
    final selectedBus =
        _selectedBus == null
            ? null
            : liveBuses
                    .where((bus) => bus.id == _selectedBus!.id)
                    .firstOrNull ??
                _selectedBus;
    final selectedBusRoute =
        selectedBus == null
            ? null
            : mapState.routes
                .where((route) => route.id == selectedBus.routeId)
                .firstOrNull;
    final selectedBusEvents =
        selectedBus?.tripId == null
            ? null
            : ref.watch(busStopEventsProvider(selectedBus!.tripId!));
    final busRouteStops =
        selectedBusRoute == null
            ? const <RouteStopOccurrence>[]
            : selectedRoute?.id == selectedBusRoute.id &&
                mapState.selectedRouteStops.isNotEmpty
            ? mapState.selectedRouteStops
            : selectedBusRoute.stopOccurrences;
    final stopProgress =
        selectedBusEvents?.value == null || selectedBusRoute == null
            ? null
            : resolveBusStopProgress(
              routeStops: busRouteStops,
              events: selectedBusEvents!.value!,
              direction: selectedBusRoute.direction,
            );
    final selectedEtaKey =
        selectedBus == null
            ? null
            : '${selectedBus.id}:${selectedBus.tripId}:${selectedBus.routeId}:${selectedBus.position.epoch}';
    final selectedBusEta =
        selectedBus == null
            ? const BusEtaResult.unavailable(
              BusEtaStatus.unresolvedStopProgress,
            )
            : BusEtaCalculator.calculate(
              bus: selectedBus,
              route: selectedBusRoute?.path ?? const [],
              progress: stopProgress,
              clock: DateTime.now,
              previousProgressMeters: _previousRouteProgress[selectedEtaKey],
              previousSpeedMetersPerSecond:
                  _previousSpeedMetersPerSecond[selectedEtaKey],
            );
    if (selectedEtaKey != null && selectedBusEta.busProgressMeters != null) {
      _previousRouteProgress[selectedEtaKey] =
          selectedBusEta.busProgressMeters!;
    }
    if (selectedEtaKey != null &&
        selectedBusEta.smoothedSpeedMetersPerSecond != null) {
      _previousSpeedMetersPerSecond[selectedEtaKey] =
          selectedBusEta.smoothedSpeedMetersPerSecond!;
    }

    final markers = [
      ..._routeDirectionMarkers(selectedRoute),
      for (final stop in mapState.stops)
        MapMarkerData(
          id: stop.id,
          point: stop.location,
          title: stop.name,
          subtitle: stop.code,
          isSelected: mapState.selectedStop?.id == stop.id,
          isRouteStop: activeStopIds.contains(stop.id),
          isMajorHub: stop.isMajorHub,
          accentColor: routeAccentColor,
          width:
              _showStopLabel(
                    stop.isMajorHub,
                    activeStopIds.contains(stop.id),
                    mapState.selectedStop?.id == stop.id,
                  )
                  ? MapConfig.stopMarkerWidthExpanded
                  : MapConfig.stopMarkerSizeCompact,
          height:
              _showStopLabel(
                    stop.isMajorHub,
                    activeStopIds.contains(stop.id),
                    mapState.selectedStop?.id == stop.id,
                  )
                  ? MapConfig.stopMarkerHeightExpanded
                  : MapConfig.stopMarkerSizeCompact,
          onTap: () => _selectStop(stop),
          child: StopMarkerWidget(
            key: ValueKey('stop-marker-${stop.id}'),
            stop: stop,
            isSelected: mapState.selectedStop?.id == stop.id,
            isRouteStop: activeStopIds.contains(stop.id),
            accentColor: routeAccentColor,
            progress: stopProgress,
            showLabel: _showStopLabel(
              stop.isMajorHub,
              activeStopIds.contains(stop.id),
              mapState.selectedStop?.id == stop.id,
            ),
            onTap: () => _selectStop(stop),
          ),
        ),
      for (final bus in busList)
        MapMarkerData(
          id: 'bus-${bus.id}',
          point: bus.position.point,
          title: bus.name,
          subtitle: bus.status.displayName,
          isSelected: _selectedBus?.id == bus.id,
          alignment: clusterOffsets[bus.id] ?? Alignment.center,
          width: MapConfig.busMarkerSize,
          height: MapConfig.busMarkerSize,
          animatePosition: true,
          sequenceNumber: bus.position.sequenceNumber,
          epoch: bus.position.epoch,
          timestamp: bus.position.timestamp,
          speedKmH: bus.position.speedKmH,
          onTap: () => _selectBus(bus),
          child: BusMarkerWidget(
            key: ValueKey('bus-marker-${bus.id}'),
            bus: bus,
            isSelected: _selectedBus?.id == bus.id,
            routeColor: _busRouteColor(bus, mapState.routes),
            onTap: () => _selectBus(bus),
          ),
        ),
      if (userLocation != null && BusTelemetry.isValidPoint(userLocation))
        MapMarkerData(
          id: 'user-location-marker',
          point: userLocation,
          title: 'You',
          width: MapConfig.userMarkerSize,
          height: MapConfig.userMarkerSize,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TrackletColors.primary.withValues(alpha: 0.18),
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TrackletColors.primary,
                border: Border.all(color: TrackletColors.pure, width: 2),
                boxShadow: const [TrackletShadows.sm],
              ),
              child: const Icon(
                TrackletIcons.locateFixed,
                size: 14,
                color: TrackletColors.pure,
              ),
            ),
          ),
        ),
    ];

    final polylines = <MapPolylineData>[];
    // Background muted polylines for unselected routes to provide context
    for (final r in mapState.routes) {
      if (_showRoutes && r.id != selectedRoute?.id && r.isGeometryAvailable) {
        polylines.add(
          MapPolylineData(
            id: 'bg-${r.id}',
            points: r.path,
            color:
                selectedRoute == null
                    ? r.color.withValues(alpha: 0.45)
                    : TrackletColors.textSecondary.withValues(alpha: 0.22),
            strokeWidth: switch (_zoomBucket) {
              0 => selectedRoute == null ? 3.0 : 2.0,
              1 => selectedRoute == null ? 3.5 : 2.5,
              _ => selectedRoute == null ? 4.0 : 3.0,
            },
          ),
        );
      }
    }
    // Active selected route polyline
    if (_showRoutes &&
        selectedRoute != null &&
        selectedRoute.isGeometryAvailable) {
      polylines.add(
        MapPolylineData(
          id: selectedRoute.id,
          points: selectedRoute.path,
          color: routeAccentColor ?? TrackletColors.primary,
          strokeWidth: switch (_zoomBucket) {
            0 => 4.5,
            1 => 5.5,
            _ => 6.5,
          },
        ),
      );
    }

    final routeStopCoordinates = [
      for (final occurrence in mapState.selectedRouteStops)
        if (occurrence.stop != null) occurrence.stop!.location,
    ];
    final routeFitCoordinates =
        selectedRoute?.isGeometryAvailable == true
            ? selectedRoute!.path
            : routeStopCoordinates;
    final isBusDetailsVisible = selectedBus != null;
    final isStopDetailsVisible = mapState.selectedStop != null;
    final isErrorFleetVisible =
        !isBusDetailsVisible &&
        !isStopDetailsVisible &&
        selectedRoute == null &&
        liveBusesAsync.hasError;
    final isLoadingFleetVisible =
        !isBusDetailsVisible &&
        !isStopDetailsVisible &&
        selectedRoute == null &&
        liveBusesAsync.isLoading &&
        !liveBusesAsync.hasValue;
    final isFleetOverviewVisible =
        !isBusDetailsVisible &&
        !isStopDetailsVisible &&
        selectedRoute == null &&
        validBusPoints.isNotEmpty;
    final isEmptyFleetVisible =
        !isBusDetailsVisible &&
        !isStopDetailsVisible &&
        (!_userExplicitlySelectedRoute || selectedRoute == null) &&
        validBusPoints.isEmpty &&
        liveBusesAsync.hasValue &&
        !liveBusesAsync.isLoading;

    const sheetBottom = 20.0;
    final maxControlsHeight = (MediaQuery.sizeOf(context).height - 290.0).clamp(
      0.0,
      double.infinity,
    );
    final controlsBottom =
        isBusDetailsVisible && _isBusDetailsExpanded
            ? (MediaQuery.sizeOf(context).height * 0.56 + sheetBottom + 8.0)
                .clamp(0.0, maxControlsHeight)
            : isBusDetailsVisible
            ? (sheetBottom + 190.0).clamp(0.0, maxControlsHeight)
            : isStopDetailsVisible
            ? (sheetBottom + 210.0).clamp(0.0, maxControlsHeight)
            : _isRouteDetailsExpanded
            ? (MediaQuery.sizeOf(context).height * 0.54 + sheetBottom + 8.0)
                .clamp(0.0, maxControlsHeight)
            : (selectedRoute != null ||
                    isFleetOverviewVisible ||
                    isEmptyFleetVisible ||
                    isErrorFleetVisible ||
                    isLoadingFleetVisible
                ? sheetBottom + 84.0
                : sheetBottom + 8.0);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_selectedBus != null) {
            ref.read(mapStateNotifierProvider.notifier).clearSelectedBus();
            setState(() {
              _selectedBus = null;
              _isBusDetailsExpanded = false;
              _followingBusId = null;
            });
          } else if (mapState.selectedStop != null) {
            ref.read(mapStateNotifierProvider.notifier).clearSelection();
          } else if (_isRouteDetailsExpanded) {
            setState(() => _isRouteDetailsExpanded = false);
          } else if (_userExplicitlySelectedRoute) {
            ref.read(mapStateNotifierProvider.notifier).clearRoute();
            setState(() {
              _isRouteDetailsExpanded = false;
              _userExplicitlySelectedRoute = false;
            });
          }
        },
      },
      child: Scaffold(
        backgroundColor: TrackletColors.adaptiveBackground(context),
        body: Stack(
          children: [
            Positioned.fill(
              child: TrackletMapView(
                controller: _mapController,
                initialCenter: MapConfig.campusCenter,
                initialZoom: MapConfig.defaultZoom,
                markers: markers,
                polylines: polylines,
                labels: labels,
                onUserGesture: () {
                  _hasUserPannedMap = true;
                  if (_followingBusId != null) {
                    setState(() => _followingBusId = null);
                  }
                },
                onZoomChanged: (zoom) {
                  final bucket =
                      zoom >= MapConfig.zoomBucketDetailed
                          ? 2
                          : zoom >= MapConfig.zoomBucketMedium
                          ? 1
                          : 0;
                  if (bucket != _zoomBucket) {
                    setState(() => _zoomBucket = bucket);
                  }
                },
                onTap: (point) {
                  ref.read(mapStateNotifierProvider.notifier).clearSelection();
                  ref
                      .read(mapStateNotifierProvider.notifier)
                      .clearSelectedBus();
                  setState(() {
                    _selectedBus = null;
                    _isBusDetailsExpanded = false;
                    _followingBusId = null;
                    _isRouteDetailsExpanded = false;
                  });
                },
              ),
            ),
            if (mapState.routes.isNotEmpty)
              Positioned(
                top: MediaQuery.paddingOf(context).top + TrackletSpacing.sm,
                left: TrackletSpacing.screenMargin,
                right: TrackletSpacing.screenMargin,
                child: RouteSelectorCard(
                  selectedRoute: selectedRoute,
                  stopCount: mapState.selectedRouteStops.length,
                  onOpenRoutePicker:
                      () => _openRoutePicker(mapState.routes, selectedRoute),
                  onClearRoute:
                      selectedRoute != null
                          ? () {
                            ref
                                .read(mapStateNotifierProvider.notifier)
                                .clearRoute();
                            setState(() {
                              _isRouteDetailsExpanded = false;
                              _userExplicitlySelectedRoute = false;
                            });
                          }
                          : null,
                ),
              ),
            if (buildingsAsync.hasError)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 74,
                left: TrackletSpacing.screenMargin,
                child: Material(
                  color: TrackletColors.adaptiveSurfaceElevated(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: TrackletRadii.roundedCard,
                    side: BorderSide(
                      color: TrackletColors.adaptiveBorder(context),
                    ),
                  ),
                  elevation: 2,
                  child: TextButton.icon(
                    onPressed: () => ref.invalidate(campusBuildingsProvider),
                    icon: const Icon(TrackletIcons.refreshCw, size: 18),
                    label: const Text('Campus names unavailable · Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: TrackletColors.adaptiveTextSecondary(
                        context,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              right: TrackletSpacing.screenMargin,
              bottom: controlsBottom,
              child: MapControls(
                onRecenterBus:
                    selectedBus == null || !selectedBus.hasValidLocation
                        ? null
                        : () {
                          setState(() => _followingBusId = selectedBus.id);
                          final disableAnimations =
                              MediaQuery.maybeDisableAnimationsOf(context) ??
                              false;
                          _mapController.animatedMoveTo(
                            this,
                            selectedBus.position.point,
                            disableAnimations: disableAnimations,
                          );
                        },
                onFitFleet:
                    validBusPoints.isEmpty
                        ? null
                        : () {
                          setState(() {
                            _followingBusId = null;
                            _hasUserPannedMap = false;
                          });
                          _fitFleetBounds(validBusPoints);
                        },
                onRecenterCampus: () {
                  setState(() {
                    _followingBusId = null;
                    _hasUserPannedMap = false;
                  });
                  final disableAnimations =
                      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
                  _mapController.recenterCampus(
                    vsync: this,
                    disableAnimations: disableAnimations,
                  );
                  ref.read(mapStateNotifierProvider.notifier).recenterCampus();
                },
                onFitRoute:
                    routeFitCoordinates.isEmpty
                        ? null
                        : () {
                          setState(() => _followingBusId = null);
                          _fitSelectedRouteStops(routeFitCoordinates);
                        },
                onRecenterUser: _handleRecenterUser,
                onOpenLegend: () => _openLegendSheet(routeAccentColor),
              ),
            ),
            if (selectedBus != null &&
                selectedBus.hasValidLocation &&
                _followingBusId == null)
              Positioned(
                right: TrackletSpacing.screenMargin,
                top: MediaQuery.paddingOf(context).top + 76,
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() => _followingBusId = selectedBus.id);
                    _mapController.animatedMoveTo(
                      this,
                      selectedBus.position.point,
                      disableAnimations:
                          MediaQuery.maybeDisableAnimationsOf(context) ?? false,
                    );
                  },
                  icon: const Icon(TrackletIcons.locateFixed, size: 18),
                  label: const Text('Resume following'),
                ),
              ),
            Positioned(
              left: TrackletSpacing.screenMargin,
              right: TrackletSpacing.screenMargin,
              bottom: sheetBottom,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.12),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child:
                    isBusDetailsVisible
                        ? BusDetailSheet(
                          key: ValueKey('bus-details-${selectedBus.id}'),
                          bus: selectedBus,
                          route:
                              mapState.routes
                                  .where((r) => r.id == selectedBus.routeId)
                                  .firstOrNull,
                          stopOccurrences:
                              stopProgress?.upcomingStops ?? const [],
                          nextStop: stopProgress?.nextStop,
                          eta: selectedBusEta,
                          isFollowing: _followingBusId == selectedBus.id,
                          onFollowBus:
                              selectedBus.hasValidLocation
                                  ? () {
                                    setState(
                                      () => _followingBusId = selectedBus.id,
                                    );
                                    _mapController.animatedMoveTo(
                                      this,
                                      selectedBus.position.point,
                                      disableAnimations:
                                          MediaQuery.maybeDisableAnimationsOf(
                                            context,
                                          ) ??
                                          false,
                                    );
                                  }
                                  : null,
                          onFitRoute: () {
                            final route = selectedBusRoute;
                            if (route == null) return;
                            setState(() => _followingBusId = null);
                            final points =
                                route.isGeometryAvailable
                                    ? route.path
                                    : [
                                      for (final occurrence in busRouteStops)
                                        if (occurrence.stop != null)
                                          occurrence.stop!.location,
                                    ];
                            _fitSelectedRouteStops(points);
                          },
                          onExpandedChanged:
                              (expanded) => setState(
                                () => _isBusDetailsExpanded = expanded,
                              ),
                          onClose: () {
                            ref
                                .read(mapStateNotifierProvider.notifier)
                                .clearSelectedBus();
                            setState(() {
                              _selectedBus = null;
                              _isBusDetailsExpanded = false;
                              _followingBusId = null;
                            });
                          },
                        )
                        : isStopDetailsVisible
                        ? StopDetailSheet(
                          key: ValueKey(
                            'stop-details-${mapState.selectedStop!.id}',
                          ),
                          stop: mapState.selectedStop!,
                          userLocation: userLocation,
                          isDefaultStop:
                              mapState.selectedStop!.id == preferredStopId,
                          routes: mapState.routes,
                          buses: liveBuses,
                          onClose:
                              () =>
                                  ref
                                      .read(mapStateNotifierProvider.notifier)
                                      .clearSelection(),
                          onSelectRoute: _selectRoute,
                          onSelectBus: _selectBus,
                          onSetAsDefaultStop: () async {
                            final stop = mapState.selectedStop!;
                            await ref
                                .read(userPreferencesProvider.notifier)
                                .setPreferredStop(stop.id, stop.name);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Set ${stop.name} as your boarding stop',
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        )
                        : (isErrorFleetVisible
                            ? _FleetErrorCard(
                              key: const ValueKey('fleet-error-card'),
                              errorMessage: liveBusesAsync.error?.toString(),
                              onRetry:
                                  () => ref.refresh(activeBusesStreamProvider),
                            )
                            : (isLoadingFleetVisible
                                ? const _FleetLoadingCard(
                                  key: ValueKey('fleet-loading-card'),
                                )
                                : (isEmptyFleetVisible
                                    ? _EmptyFleetCard(
                                      key: const ValueKey('empty-fleet-card'),
                                      onRetry:
                                          () => ref.refresh(
                                            activeBusesStreamProvider,
                                          ),
                                    )
                                    : (selectedRoute != null
                                        ? RouteStopsSheet(
                                          key: ValueKey(
                                            'route-stops-${selectedRoute.id}',
                                          ),
                                          route: selectedRoute,
                                          stopOccurrences:
                                              mapState.selectedRouteStops,
                                          selectedStop: mapState.selectedStop,
                                          isExpanded: _isRouteDetailsExpanded,
                                          isLoading:
                                              mapState.isLoadingRouteStops,
                                          errorMessage:
                                              mapState.routeStopsError,
                                          onRetry:
                                              () => ref
                                                  .read(
                                                    mapStateNotifierProvider
                                                        .notifier,
                                                  )
                                                  .selectRoute(selectedRoute),
                                          onToggle:
                                              () => setState(
                                                () =>
                                                    _isRouteDetailsExpanded =
                                                        !_isRouteDetailsExpanded,
                                              ),
                                          onSelectStop: _selectStop,
                                        )
                                        : (isFleetOverviewVisible
                                            ? _FleetOverviewCard(
                                              key: const ValueKey(
                                                'fleet-overview-card',
                                              ),
                                              busCount: validBusPoints.length,
                                              onFitFleet: () {
                                                setState(() {
                                                  _followingBusId = null;
                                                  _hasUserPannedMap = false;
                                                });
                                                _fitFleetBounds(validBusPoints);
                                              },
                                            )
                                            : const SizedBox.shrink(
                                              key: ValueKey(
                                                'empty-bottom-panel',
                                              ),
                                            )))))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FleetLoadingCard extends StatelessWidget {
  const _FleetLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    return Material(
      color: TrackletColors.adaptiveSurfaceElevated(context),
      borderRadius: TrackletRadii.roundedLg,
      elevation: 4,
      shadowColor: TrackletColors.adaptiveTextPrimary(
        context,
      ).withValues(alpha: isDark ? 0.28 : 0.14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TrackletSpacing.md,
          vertical: TrackletSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          borderRadius: TrackletRadii.roundedLg,
          border: Border.all(color: TrackletColors.adaptiveCardBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TrackletColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                TrackletIcons.radar,
                color: TrackletColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: TrackletSpacing.md),
            Expanded(
              child: Text(
                'Connecting to live bus fleet...',
                style: TrackletTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: TrackletColors.adaptiveTextPrimary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FleetErrorCard extends StatelessWidget {
  const _FleetErrorCard({super.key, this.errorMessage, this.onRetry});

  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    return Material(
      color: TrackletColors.adaptiveSurfaceElevated(context),
      borderRadius: TrackletRadii.roundedLg,
      elevation: 4,
      shadowColor: TrackletColors.adaptiveTextPrimary(
        context,
      ).withValues(alpha: isDark ? 0.28 : 0.14),
      child: Container(
        padding: const EdgeInsets.all(TrackletSpacing.md),
        decoration: BoxDecoration(
          borderRadius: TrackletRadii.roundedLg,
          border: Border.all(color: TrackletColors.adaptiveCardBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TrackletColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                TrackletIcons.alertTriangle,
                color: TrackletColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: TrackletSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Unable to load bus locations',
                    style: TrackletTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: TrackletColors.adaptiveTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    errorMessage ?? 'Temporary network or telemetry error.',
                    style: TrackletTypography.bodySmall.copyWith(
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onRetry != null)
              IconButton(
                onPressed: onRetry,
                tooltip: 'Retry live tracking',
                icon: const Icon(TrackletIcons.refresh, size: 20),
                color: TrackletColors.adaptiveTextSecondary(context),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFleetCard extends StatelessWidget {
  const _EmptyFleetCard({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    return Material(
      color: TrackletColors.adaptiveSurfaceElevated(context),
      borderRadius: TrackletRadii.roundedLg,
      elevation: 4,
      shadowColor: TrackletColors.adaptiveTextPrimary(
        context,
      ).withValues(alpha: isDark ? 0.28 : 0.14),
      child: Container(
        padding: const EdgeInsets.all(TrackletSpacing.md),
        decoration: BoxDecoration(
          borderRadius: TrackletRadii.roundedLg,
          border: Border.all(color: TrackletColors.adaptiveCardBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TrackletColors.busOfflineBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: TrackletColors.busOffline.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                TrackletIcons.bus,
                color: TrackletColors.busOffline,
                size: 22,
              ),
            ),
            const SizedBox(width: TrackletSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No active buses right now',
                    style: TrackletTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: TrackletColors.adaptiveTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Live tracking will appear once buses start operating.',
                    style: TrackletTypography.bodySmall.copyWith(
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            if (onRetry != null)
              IconButton(
                onPressed: onRetry,
                tooltip: 'Refresh bus fleet',
                icon: const Icon(TrackletIcons.refresh, size: 20),
                color: TrackletColors.adaptiveTextSecondary(context),
              ),
          ],
        ),
      ),
    );
  }
}

class _FleetOverviewCard extends StatelessWidget {
  const _FleetOverviewCard({
    super.key,
    required this.busCount,
    this.onFitFleet,
  });

  final int busCount;
  final VoidCallback? onFitFleet;

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    return Material(
      color: TrackletColors.adaptiveSurfaceElevated(context),
      borderRadius: TrackletRadii.roundedLg,
      elevation: 4,
      shadowColor: TrackletColors.adaptiveTextPrimary(
        context,
      ).withValues(alpha: isDark ? 0.28 : 0.14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TrackletSpacing.md,
          vertical: TrackletSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          borderRadius: TrackletRadii.roundedLg,
          border: Border.all(color: TrackletColors.adaptiveCardBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TrackletColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: TrackletColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                TrackletIcons.radar,
                color: TrackletColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: TrackletSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Campus Transit Fleet',
                    style: TrackletTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: TrackletColors.adaptiveTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$busCount ${busCount == 1 ? 'bus' : 'buses'} active · Tap any bus for details',
                    style: TrackletTypography.bodySmall.copyWith(
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            if (onFitFleet != null)
              TextButton.icon(
                onPressed: onFitFleet,
                icon: const Icon(TrackletIcons.radar, size: 16),
                label: const Text('Fit all'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: TrackletRadii.roundedXs,
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}
