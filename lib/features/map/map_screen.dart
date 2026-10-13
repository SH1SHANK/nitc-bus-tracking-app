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
import '../../data/transit/bus_route.dart';
import '../../data/transit/stop.dart';
import 'providers/map_state_provider.dart';
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

class _MapScreenState extends ConsumerState<MapScreen> {
  late final TrackletMapController _mapController;
  bool _isRouteDetailsExpanded = false;

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
    _mapController.fitBounds(
      points,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 104,
        left: 40,
        right: 40,
        bottom: MediaQuery.sizeOf(context).height * 0.24,
      ),
    );
  }

  Future<void> _selectRoute(BusRoute route) async {
    final notifier = ref.read(mapStateNotifierProvider.notifier);
    await notifier.selectRoute(route);
    if (!mounted) return;

    setState(() => _isRouteDetailsExpanded = false);
    final occurrences = ref.read(mapStateNotifierProvider).selectedRouteStops;
    final points = [
      for (final occurrence in occurrences)
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
                        return ListTile(
                          key: ValueKey('route-option-${route.id}'),
                          minLeadingWidth: 40,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: TrackletSpacing.sm,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: TrackletColors.background2,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              route.code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: TrackletColors.primary,
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
                                      : FontWeight.w500,
                            ),
                          ),
                          subtitle:
                              subtitle?.isNotEmpty == true
                                  ? Text(
                                    subtitle!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                  : null,
                          trailing:
                              isSelected
                                  ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: TrackletColors.primary,
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
    ref.read(mapStateNotifierProvider.notifier).selectStop(stop);
    _mapController.moveTo(stop.location);
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
    final markers = [
      for (final stop in mapState.stops)
        MapMarkerData(
          id: stop.id,
          point: stop.location,
          title: stop.name,
          subtitle: stop.code,
          isSelected: mapState.selectedStop?.id == stop.id,
          isRouteStop: activeStopIds.contains(stop.id),
          isMajorHub: stop.isMajorHub,
          width: 112,
          height: 60,
          onTap: () => _selectStop(stop),
          child: StopMarkerWidget(
            key: ValueKey('stop-marker-${stop.id}'),
            stop: stop,
            isSelected: mapState.selectedStop?.id == stop.id,
            isRouteStop: activeStopIds.contains(stop.id),
            onTap: () => _selectStop(stop),
          ),
        ),
    ];

    final selectedRoute = mapState.selectedRoute;
    final polylines = <MapPolylineData>[];
    if (selectedRoute != null && selectedRoute.isGeometryAvailable) {
      polylines.add(
        MapPolylineData(
          id: selectedRoute.id,
          points: selectedRoute.path,
          color: Color(
            int.parse(selectedRoute.colorHex.replaceFirst('#', '0xFF')),
          ),
          strokeWidth: 5,
        ),
      );
    }

    final routeStopCoordinates = [
      for (final occurrence in mapState.selectedRouteStops)
        if (occurrence.stop != null) occurrence.stop!.location,
    ];
    final isStopDetailsVisible = mapState.selectedStop != null;
    final controlsBottom =
        isStopDetailsVisible
            ? 174.0
            : _isRouteDetailsExpanded
            ? MediaQuery.sizeOf(context).height * 0.54 + TrackletSpacing.md
            : 82.0;

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
              onTap: (point) {
                ref.read(mapStateNotifierProvider.notifier).clearSelection();
                setState(() => _isRouteDetailsExpanded = false);
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
          Positioned(
            right: TrackletSpacing.screenMargin,
            bottom: controlsBottom,
            child: MapControls(
              onRecenterCampus: () {
                _mapController.recenterCampus();
                ref.read(mapStateNotifierProvider.notifier).recenterCampus();
              },
              onFitRoute:
                  routeStopCoordinates.isEmpty
                      ? null
                      : () => _fitSelectedRouteStops(routeStopCoordinates),
            ),
          ),
          if (selectedRoute != null && !isStopDetailsVisible)
            Positioned(
              left: TrackletSpacing.screenMargin,
              right: TrackletSpacing.screenMargin,
              bottom: TrackletSpacing.sm,
              child: RouteStopsSheet(
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
                      () => _isRouteDetailsExpanded = !_isRouteDetailsExpanded,
                    ),
                onSelectStop: _selectStop,
              ),
            ),
          if (mapState.selectedStop case final stop?)
            Positioned(
              left: TrackletSpacing.screenMargin,
              right: TrackletSpacing.screenMargin,
              bottom: TrackletSpacing.sm,
              child: StopDetailSheet(
                stop: stop,
                routes: mapState.routes,
                onClose:
                    () =>
                        ref
                            .read(mapStateNotifierProvider.notifier)
                            .clearSelection(),
                onSelectRoute: _selectRoute,
              ),
            ),
        ],
      ),
    );
  }
}
