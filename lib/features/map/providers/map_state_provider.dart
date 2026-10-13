import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/geo_point.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/campus/campus_building_repository.dart';
import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/route_geometry.dart';
import '../../../data/transit/route_stop_occurrence.dart';
import '../../../data/transit/stop.dart';
import '../../../data/transit/transit_repository.dart';
import '../../../services/maps/map_cartography.dart';
import '../../../services/maps/map_config.dart';

/// Immutable state for the Mapbox campus map screen.
class MapScreenState {
  const MapScreenState({
    this.stops = const [],
    this.routes = const [],
    this.selectedRoute,
    this.selectedRouteStops = const [],
    this.selectedStop,
    this.cameraCenter = MapConfig.campusCenter,
    this.isLoading = false,
    this.errorMessage,
    this.isLoadingRouteStops = false,
    this.routeStopsError,
  });

  final List<Stop> stops;
  final List<BusRoute> routes;
  final BusRoute? selectedRoute;
  final List<RouteStopOccurrence> selectedRouteStops;
  final Stop? selectedStop;
  final GeoPoint cameraCenter;
  final bool isLoading;
  final String? errorMessage;
  final bool isLoadingRouteStops;
  final String? routeStopsError;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
  bool get isEmpty => !isLoading && stops.isEmpty;
  bool get isGeometryMissing => selectedRoute?.isGeometryMissing ?? false;

  Set<String> get activeRouteStopIds {
    final occurrences = selectedRouteStops;
    if (occurrences.isNotEmpty) {
      return occurrences.map((occurrence) => occurrence.stopId).toSet();
    }
    return selectedRoute?.stopIds.toSet() ?? const <String>{};
  }

  MapScreenState copyWith({
    List<Stop>? stops,
    List<BusRoute>? routes,
    BusRoute? selectedRoute,
    List<RouteStopOccurrence>? selectedRouteStops,
    Stop? selectedStop,
    GeoPoint? cameraCenter,
    bool? isLoading,
    String? errorMessage,
    bool? isLoadingRouteStops,
    String? routeStopsError,
    bool clearSelectedStop = false,
    bool clearError = false,
    bool clearRouteStopsError = false,
  }) {
    return MapScreenState(
      stops: stops ?? this.stops,
      routes: routes ?? this.routes,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      selectedRouteStops: selectedRouteStops ?? this.selectedRouteStops,
      selectedStop:
          clearSelectedStop ? null : (selectedStop ?? this.selectedStop),
      cameraCenter: cameraCenter ?? this.cameraCenter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoadingRouteStops: isLoadingRouteStops ?? this.isLoadingRouteStops,
      routeStopsError:
          clearRouteStopsError
              ? null
              : (routeStopsError ?? this.routeStopsError),
    );
  }
}

class MapStateNotifier extends Notifier<MapScreenState> {
  bool _isLoadingTransitData = false;
  int _loadGeneration = 0;
  int _routeSelectionGeneration = 0;

  @override
  MapScreenState build() {
    Future.microtask(loadTransitData);
    return const MapScreenState(isLoading: true);
  }

  Future<void> loadTransitData() async {
    if (_isLoadingTransitData) return;
    _isLoadingTransitData = true;
    final generation = ++_loadGeneration;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      isLoadingRouteStops: false,
      clearRouteStopsError: true,
    );
    try {
      final repo = ref.read(transitRepositoryProvider);
      final stops = await repo.getStops();
      final routes = await repo.getRoutes(knownStops: stops);

      BusRoute? initialRoute;
      List<RouteStopOccurrence> initialRouteStops = [];

      if (routes.isNotEmpty) {
        initialRoute = routes.first;
        if (initialRoute.stopOccurrences.isNotEmpty) {
          initialRouteStops = List.of(initialRoute.stopOccurrences);
        } else {
          initialRouteStops = await repo.getRouteStops(initialRoute.id);
        }
        initialRouteStops.sort((a, b) => a.sequence.compareTo(b.sequence));
      }

      if (generation != _loadGeneration) return;
      state = state.copyWith(
        stops: stops,
        routes: routes,
        selectedRoute: initialRoute,
        selectedRouteStops: initialRouteStops,
        isLoading: false,
        clearError: true,
      );
    } catch (error, stackTrace) {
      if (generation != _loadGeneration) return;
      AppLogger.error(
        'Failed to load transit data for map',
        error: error,
        stackTrace: stackTrace,
        tag: 'MapStateNotifier',
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load transit stops right now.',
      );
    } finally {
      _isLoadingTransitData = false;
    }
  }

  Future<void> selectRoute(BusRoute route) async {
    final generation = ++_routeSelectionGeneration;
    state = state.copyWith(
      selectedRoute: route,
      isLoadingRouteStops: true,
      clearRouteStopsError: true,
    );

    try {
      final repo = ref.read(transitRepositoryProvider);
      List<RouteStopOccurrence> occurrences;
      if (route.stopOccurrences.isNotEmpty) {
        occurrences = List.of(route.stopOccurrences);
      } else {
        occurrences = await repo.getRouteStops(route.id);
      }
      occurrences.sort((a, b) => a.sequence.compareTo(b.sequence));

      if (generation != _routeSelectionGeneration ||
          state.selectedRoute?.id != route.id) {
        return;
      }

      final resolvedRoute =
          route.isGeometryAvailable
              ? route
              : route.copyWith(
                geometry: RouteGeometry.available(
                  path:
                      occurrences
                          .map((occurrence) => occurrence.stop?.location)
                          .whereType<GeoPoint>()
                          .toList(),
                ),
                path:
                    occurrences
                        .map((occurrence) => occurrence.stop?.location)
                        .whereType<GeoPoint>()
                        .toList(),
              );

      state = state.copyWith(
        selectedRoute: resolvedRoute,
        selectedRouteStops: occurrences,
        isLoadingRouteStops: false,
        clearRouteStopsError: true,
      );
    } catch (error, stackTrace) {
      if (generation != _routeSelectionGeneration ||
          state.selectedRoute?.id != route.id) {
        return;
      }
      AppLogger.error(
        'Failed to load stops for route ${route.id}',
        error: error,
        stackTrace: stackTrace,
        tag: 'MapStateNotifier',
      );
      state = state.copyWith(
        isLoadingRouteStops: false,
        routeStopsError: 'Could not load this route’s stops. Please retry.',
      );
    }
  }

  void selectBus(Bus bus) {
    // Selects the route associated with the selected bus if available
    final routeId = bus.routeId;
    if (routeId != null) {
      final route = state.routes.where((r) => r.id == routeId).firstOrNull;
      if (route != null) {
        selectRoute(route);
        return;
      }
    }
    clearSelection();
  }

  void selectStop(Stop stop) {
    state = state.copyWith(selectedStop: stop, cameraCenter: stop.location);
  }

  void clearSelection() {
    state = state.copyWith(clearSelectedStop: true);
  }

  void recenterCampus() {
    state = state.copyWith(
      cameraCenter: MapConfig.campusCenter,
      clearSelectedStop: true,
    );
  }
}

final mapStateNotifierProvider =
    NotifierProvider<MapStateNotifier, MapScreenState>(() {
      return MapStateNotifier();
    });

/// Memoized map labels derived from map state and campus buildings.
final mapLabelsProvider = Provider.autoDispose<List<MapLabelFeature>>((ref) {
  final mapState = ref.watch(mapStateNotifierProvider);
  final buildings =
      ref.watch(campusBuildingsProvider).asData?.value ?? const [];
  final activeStopIds = mapState.activeRouteStopIds;

  return [
    for (final building in buildings)
      MapLabelFeature(
        id: 'building-${building.id}',
        name: building.name,
        point: building.location,
        kind: MapLabelKind.building,
      ),
    for (final stop in mapState.stops)
      MapLabelFeature(
        id: 'stop-${stop.id}',
        name: stop.name,
        point: stop.location,
        kind: MapLabelKind.stop,
        isSelected: mapState.selectedStop?.id == stop.id,
        isRouteStop: activeStopIds.contains(stop.id),
      ),
  ];
});
