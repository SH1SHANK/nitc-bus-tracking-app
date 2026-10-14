import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/geo/geo_point.dart';
import '../../data/campus/campus_building_repository.dart';
import '../../design_system/components/tracklet_empty_state.dart';
import '../../design_system/components/tracklet_error_state.dart';
import '../../design_system/components/tracklet_skeleton.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../services/maps/map_adapter.dart';
import '../../services/maps/map_config.dart';
import '../../data/transit/bus.dart';
import '../../data/transit/bus_eta.dart';
import '../../data/transit/bus_route.dart';
import '../../data/transit/route_stop_occurrence.dart';
import '../../data/transit/stop.dart';
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
  bool _legendExpanded = false;
  bool _showRoutes = true;
  int _zoomBucket = 1;
  DateTime? _lastStopEventRefresh;
  final Map<String, double> _previousRouteProgress = {};
  final Map<String, double> _previousSpeedMetersPerSecond = {};

  Color _routeColor(BusRoute route) {
    final name = '${route.name} ${route.description ?? ''}'.toLowerCase();
    if (name.contains('soms')) return const Color(0xFF0D9488);
    if (name.contains('mbh') || name.contains('mega boys')) {
      return const Color(0xFF4F46E5);
    }
    try {
      final hex = route.colorHex.replaceFirst('#', '');
      return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
    } catch (_) {
      return TrackletColors.primary;
    }
  }

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
    if (totalLength == 0) return const [];
    final arrowCount =
        math.min(targetCount, math.max(1, (totalLength / 180).ceil())).toInt();
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
              child: Icon(Icons.navigation_rounded, size: 17, color: color),
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
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
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
    if (_followingBusId != null) {
      setState(() => _followingBusId = null);
    }
    final notifier = ref.read(mapStateNotifierProvider.notifier);
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
          color: TrackletColors.surfaceElevated,
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
                            color: TrackletColors.border,
                            borderRadius: BorderRadius.circular(4),
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
                                  color: TrackletColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              tooltip: 'Close route selection',
                              icon: const Icon(Icons.close_rounded),
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
                          (context, index) => const Divider(
                            height: 1,
                            indent: 58,
                            color: TrackletColors.border,
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
                              borderRadius: BorderRadius.circular(10),
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
                              color: TrackletColors.textPrimary,
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
                                    style: const TextStyle(
                                      color: TrackletColors.textSecondary,
                                    ),
                                  )
                                  : null,
                          trailing:
                              isSelected
                                  ? Icon(
                                    Icons.check_circle_rounded,
                                    color: routeColor,
                                  )
                                  : const Icon(
                                    Icons.chevron_right_rounded,
                                    color: TrackletColors.textSecondary,
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

  void _selectBus(Bus bus) {
    setState(() {
      _selectedBus = bus;
      _isBusDetailsExpanded = false;
      _followingBusId = bus.id;
      _isRouteDetailsExpanded = false;
    });
    final notifier = ref.read(mapStateNotifierProvider.notifier);
    notifier.clearSelection();
    final mapState = ref.read(mapStateNotifierProvider);
    final route =
        mapState.routes.where((item) => item.id == bus.routeId).firstOrNull;
    if (route != null && mapState.selectedRoute?.id != route.id) {
      unawaited(notifier.selectRoute(route));
    }
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _mapController.animatedMoveTo(
      this,
      bus.position.point,
      disableAnimations: disableAnimations,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapStateNotifierProvider);
    final buildingsAsync = ref.watch(campusBuildingsProvider);

    if (mapState.isLoading) {
      return const Scaffold(
        backgroundColor: TrackletColors.background,
        body: TrackletMapSkeleton(),
      );
    }

    if (mapState.hasError) {
      return Scaffold(
        backgroundColor: TrackletColors.background,
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
        backgroundColor: TrackletColors.background,
        body: TrackletEmptyState(
          title: 'No campus stops yet',
          description:
              'Active bus stops will appear here when transit data is available.',
          icon: const Icon(
            Icons.location_off_outlined,
            color: TrackletColors.textSecondary,
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

    ref.watch(homeClockProvider);
    final liveBusesAsync = ref.watch(activeBusesStreamProvider);
    final liveBuses = liveBusesAsync.value ?? const [];
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
      if (followingId == null) return;
      final bus =
          next.value
              ?.where((candidate) => candidate.id == followingId)
              .firstOrNull;
      if (bus != null) {
        _mapController.animatedMoveTo(
          this,
          bus.position.point,
          zoom: null,
          disableAnimations:
              MediaQuery.maybeDisableAnimationsOf(context) ?? false,
        );
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
                  ? 112
                  : 48,
          height:
              _showStopLabel(
                    stop.isMajorHub,
                    activeStopIds.contains(stop.id),
                    mapState.selectedStop?.id == stop.id,
                  )
                  ? 60
                  : 48,
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
      for (final bus in liveBuses)
        MapMarkerData(
          id: 'bus-${bus.id}',
          point: bus.position.point,
          title: bus.name,
          subtitle: bus.status.displayName,
          isSelected: _selectedBus?.id == bus.id,
          width: 48,
          height: 48,
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
    ];

    final polylines = <MapPolylineData>[];
    // Background muted polylines for unselected routes to provide context
    for (final r in mapState.routes) {
      if (_showRoutes && r.id != selectedRoute?.id && r.isGeometryAvailable) {
        polylines.add(
          MapPolylineData(
            id: 'bg-${r.id}',
            points: r.path,
            color: TrackletColors.textSecondary.withValues(alpha: 0.22),
            strokeWidth: switch (_zoomBucket) {
              0 => 2,
              1 => 2.5,
              _ => 3,
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
    final controlsBottom =
        isBusDetailsVisible && _isBusDetailsExpanded
            ? MediaQuery.sizeOf(context).height * 0.60
            : isBusDetailsVisible || isStopDetailsVisible
            ? 188.0
            : _isRouteDetailsExpanded
            ? MediaQuery.sizeOf(context).height * 0.54 + TrackletSpacing.md
            : (selectedRoute != null ? 92.0 : 28.0);

    return Scaffold(
      backgroundColor: TrackletColors.background,
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
                if (_followingBusId != null) {
                  setState(() => _followingBusId = null);
                }
              },
              onZoomChanged: (zoom) {
                final bucket =
                    zoom >= 18.5
                        ? 2
                        : zoom >= 16.5
                        ? 1
                        : 0;
                if (bucket != _zoomBucket) {
                  setState(() => _zoomBucket = bucket);
                }
              },
              onTap: (point) {
                ref.read(mapStateNotifierProvider.notifier).clearSelection();
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
                          setState(() => _isRouteDetailsExpanded = false);
                        }
                        : null,
              ),
            ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 88,
            left: TrackletSpacing.screenMargin,
            child: Material(
              color: TrackletColors.surfaceElevated,
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed:
                                () => setState(
                                  () => _legendExpanded = !_legendExpanded,
                                ),
                            icon: Icon(
                              _legendExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.legend_toggle_rounded,
                            ),
                            label: const Text('Map legend'),
                          ),
                        ),
                        IconButton(
                          tooltip: _showRoutes ? 'Hide routes' : 'Show routes',
                          onPressed:
                              () => setState(() => _showRoutes = !_showRoutes),
                          icon: Icon(
                            _showRoutes
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                        ),
                      ],
                    ),
                    if (_legendExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LegendRow(
                              color:
                                  routeAccentColor ??
                                  TrackletColors.routeActive,
                              label: 'Live or stationary bus',
                            ),
                            _LegendRow(
                              color:
                                  routeAccentColor ??
                                  TrackletColors.routeActive,
                              label: 'Selected route',
                            ),
                            const _LegendRow(
                              color: TrackletColors.textSecondary,
                              label: 'Other routes',
                            ),
                            _LegendRow(
                              color:
                                  routeAccentColor ??
                                  TrackletColors.routeActive,
                              label: 'Next stop',
                            ),
                            const _LegendRow(
                              color: TrackletColors.textSecondary,
                              label: 'Upcoming or visited stop',
                            ),
                            const _LegendRow(
                              color: TrackletColors.busOffline,
                              label: 'Stale or offline bus',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (buildingsAsync.hasError)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 74,
              left: TrackletSpacing.screenMargin,
              child: Material(
                color: TrackletColors.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: TrackletColors.border),
                ),
                elevation: 2,
                child: TextButton.icon(
                  onPressed: () => ref.invalidate(campusBuildingsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Campus names unavailable · Retry'),
                  style: TextButton.styleFrom(
                    foregroundColor: TrackletColors.textSecondary,
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
                  selectedBus == null
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
              onRecenterCampus: () {
                setState(() => _followingBusId = null);
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
            ),
          ),
          if (selectedBus != null && _followingBusId == null)
            Positioned(
              right: TrackletSpacing.screenMargin,
              top: MediaQuery.paddingOf(context).top + 96,
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
                icon: const Icon(Icons.my_location_rounded, size: 18),
                label: const Text('Resume following'),
              ),
            ),
          Positioned(
            left: TrackletSpacing.screenMargin,
            right: TrackletSpacing.screenMargin,
            bottom: TrackletSpacing.sm,
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
                        onFollowBus: () {
                          setState(() => _followingBusId = selectedBus.id);
                          _mapController.animatedMoveTo(
                            this,
                            selectedBus.position.point,
                            disableAnimations:
                                MediaQuery.maybeDisableAnimationsOf(context) ??
                                false,
                          );
                        },
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
                        onClose:
                            () => setState(() {
                              _selectedBus = null;
                              _isBusDetailsExpanded = false;
                              _followingBusId = null;
                            }),
                      )
                      : isStopDetailsVisible
                      ? StopDetailSheet(
                        key: ValueKey(
                          'stop-details-${mapState.selectedStop!.id}',
                        ),
                        stop: mapState.selectedStop!,
                        routes: mapState.routes,
                        onClose:
                            () =>
                                ref
                                    .read(mapStateNotifierProvider.notifier)
                                    .clearSelection(),
                        onSelectRoute: _selectRoute,
                      )
                      : (selectedRoute != null
                          ? RouteStopsSheet(
                            key: ValueKey('route-stops-${selectedRoute.id}'),
                            route: selectedRoute,
                            stopOccurrences: mapState.selectedRouteStops,
                            selectedStop: mapState.selectedStop,
                            isExpanded: _isRouteDetailsExpanded,
                            isLoading: mapState.isLoadingRouteStops,
                            errorMessage: mapState.routeStopsError,
                            onRetry:
                                () => ref
                                    .read(mapStateNotifierProvider.notifier)
                                    .selectRoute(selectedRoute),
                            onToggle:
                                () => setState(
                                  () =>
                                      _isRouteDetailsExpanded =
                                          !_isRouteDetailsExpanded,
                                ),
                            onSelectStop: _selectStop,
                          )
                          : const SizedBox.shrink(
                            key: ValueKey('empty-bottom-panel'),
                          )),
            ),
          ),
        ],
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
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}
