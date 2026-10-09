import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/geo/geo_point.dart';
import '../../design_system/components/tracklet_error_state.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../services/maps/map_adapter.dart';
import '../../services/maps/map_config.dart';
import 'providers/map_state_provider.dart';
import 'widgets/map_controls.dart';
import 'widgets/route_selector_card.dart';
import 'widgets/route_stops_sheet.dart';
import 'widgets/stop_detail_sheet.dart';
import 'widgets/stop_marker_widget.dart';

/// Spatial, production-grade Mapbox campus map screen for Tracklet transit.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final TrackletMapController _mapController;
  bool _isStopsListExpanded = false;

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
      padding: const EdgeInsets.only(
        top: 140,
        left: 48,
        right: 48,
        bottom: 220,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapStateNotifierProvider);

    if (mapState.isLoading) {
      return const Scaffold(
        backgroundColor: TrackletColors.background,
        body: Center(
          child: CircularProgressIndicator(color: TrackletColors.primary),
        ),
      );
    }

    if (mapState.hasError) {
      return Scaffold(
        backgroundColor: TrackletColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(TrackletSpacing.screenMargin),
            child: TrackletErrorState(
              title: 'Transit Map Unavailable',
              message: mapState.errorMessage ?? 'Failed to load transit data.',
              onRetry: () =>
                  ref.read(mapStateNotifierProvider.notifier).loadTransitData(),
            ),
          ),
        ),
      );
    }

    // Build stop markers
    final markers = <MapMarkerData>[];
    final activeStopIds = mapState.activeRouteStopIds;

    for (final stop in mapState.stops) {
      final isSelected = mapState.selectedStop?.id == stop.id;
      final isRouteStop = activeStopIds.contains(stop.id);

      markers.add(
        MapMarkerData(
          id: stop.id,
          point: stop.location,
          title: stop.name,
          subtitle: stop.code,
          isSelected: isSelected,
          isMajorHub: stop.isMajorHub,
          width: 90.0,
          height: 48.0,
          onTap: () {
            ref.read(mapStateNotifierProvider.notifier).selectStop(stop);
            _mapController.moveTo(stop.location);
          },
          child: StopMarkerWidget(
            stop: stop,
            isSelected: isSelected,
            isRouteStop: isRouteStop,
            onTap: () {
              ref.read(mapStateNotifierProvider.notifier).selectStop(stop);
              _mapController.moveTo(stop.location);
            },
          ),
        ),
      );
    }

    // Build Route Polylines: rendered ONLY when valid road-following geometry is available
    final polylines = <MapPolylineData>[];
    if (mapState.selectedRoute != null &&
        mapState.selectedRoute!.isGeometryAvailable) {
      polylines.add(
        MapPolylineData(
          id: mapState.selectedRoute!.id,
          points: mapState.selectedRoute!.path,
          color: Color(
            int.parse(
              mapState.selectedRoute!.colorHex.replaceFirst('#', '0xFF'),
            ),
          ),
          strokeWidth: 5.0,
        ),
      );
    }

    // Coordinates of all stops in the active route for camera bounds fitting
    final routeStopCoordinates = <GeoPoint>[];
    for (final occurrence in mapState.selectedRouteStops) {
      if (occurrence.stop != null) {
        routeStopCoordinates.add(occurrence.stop!.location);
      }
    }

    return Scaffold(
      backgroundColor: TrackletColors.background,
      body: Stack(
        children: [
          // Underlying Mapbox / Fallback Map View
          Positioned.fill(
            child: TrackletMapView(
              controller: _mapController,
              initialCenter: mapState.cameraCenter,
              initialZoom: MapConfig.defaultZoom,
              markers: markers,
              polylines: polylines,
              onTap: (point) {
                ref.read(mapStateNotifierProvider.notifier).clearSelection();
                setState(() {
                  _isStopsListExpanded = false;
                });
              },
            ),
          ),

          // Top Route Selector Card
          if (mapState.routes.isNotEmpty)
            Positioned(
              top: MediaQuery.paddingOf(context).top + TrackletSpacing.sm,
              left: TrackletSpacing.screenMargin,
              right: TrackletSpacing.screenMargin,
              child: RouteSelectorCard(
                routes: mapState.routes,
                selectedRoute: mapState.selectedRoute,
                isStopsListExpanded: _isStopsListExpanded,
                onSelectRoute: (route) {
                  ref
                      .read(mapStateNotifierProvider.notifier)
                      .selectRoute(route);
                  final occurrences = route.stopOccurrences;
                  final coords = occurrences
                      .where((o) => o.stop != null)
                      .map((o) => o.stop!.location)
                      .toList();
                  if (coords.isNotEmpty) {
                    _fitSelectedRouteStops(coords);
                  }
                },
                onToggleStopsList: () {
                  setState(() {
                    _isStopsListExpanded = !_isStopsListExpanded;
                  });
                },
              ),
            ),

          // Map Control Buttons (Fit Route & Recenter Campus)
          Positioned(
            right: TrackletSpacing.screenMargin,
            bottom: mapState.selectedStop != null
                ? 210.0
                : (_isStopsListExpanded ? 240.0 : 32.0),
            child: MapControls(
              onRecenterCampus: () {
                _mapController.recenterCampus();
                ref.read(mapStateNotifierProvider.notifier).recenterCampus();
              },
              onFitRoute: routeStopCoordinates.isNotEmpty
                  ? () => _fitSelectedRouteStops(routeStopCoordinates)
                  : null,
            ),
          ),

          // Ordered Route Stops Sheet (when expanded)
          if (_isStopsListExpanded && mapState.selectedRoute != null)
            Positioned(
              left: TrackletSpacing.screenMargin,
              right: TrackletSpacing.screenMargin,
              bottom: TrackletSpacing.lg,
              child: RouteStopsSheet(
                route: mapState.selectedRoute!,
                stopOccurrences: mapState.selectedRouteStops,
                selectedStop: mapState.selectedStop,
                onSelectStop: (stop) {
                  ref.read(mapStateNotifierProvider.notifier).selectStop(stop);
                  _mapController.moveTo(stop.location);
                },
                onClose: () {
                  setState(() {
                    _isStopsListExpanded = false;
                  });
                },
              ),
            ),

          // Selected Stop Detail Sheet
          if (mapState.selectedStop != null)
            Positioned(
              left: TrackletSpacing.screenMargin,
              right: TrackletSpacing.screenMargin,
              bottom: TrackletSpacing.lg,
              child: StopDetailSheet(
                stop: mapState.selectedStop!,
                routes: mapState.routes,
                onClose: () {
                  ref.read(mapStateNotifierProvider.notifier).clearSelection();
                },
                onSelectRoute: (route) {
                  ref
                      .read(mapStateNotifierProvider.notifier)
                      .selectRoute(route);
                  final coords = route.stopOccurrences
                      .where((o) => o.stop != null)
                      .map((o) => o.stop!.location)
                      .toList();
                  if (coords.isNotEmpty) {
                    _fitSelectedRouteStops(coords);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
