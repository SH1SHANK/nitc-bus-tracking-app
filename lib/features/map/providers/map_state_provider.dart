import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/geo_point.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/route_geometry.dart';
import '../../../data/transit/route_stop_occurrence.dart';
import '../../../data/transit/stop.dart';
import '../../../data/transit/transit_repository.dart';
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
  });

  final List<Stop> stops;
  final List<BusRoute> routes;
  final BusRoute? selectedRoute;
  final List<RouteStopOccurrence> selectedRouteStops;
  final Stop? selectedStop;
  final GeoPoint cameraCenter;
  final bool isLoading;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
  bool get isEmpty => !isLoading && !hasError && stops.isEmpty;

  RouteGeometryStatus get geometryStatus =>
      selectedRoute?.geometry.status ?? RouteGeometryStatus.missing;

  bool get isGeometryAvailable =>
      geometryStatus == RouteGeometryStatus.available;
  bool get isGeometryMissing => geometryStatus == RouteGeometryStatus.missing;
  bool get isGeometryInvalid => geometryStatus == RouteGeometryStatus.invalid;

  Set<String> get activeRouteStopIds {
    if (selectedRoute == null) return const {};
    if (selectedRouteStops.isNotEmpty) {
      return selectedRouteStops.map((s) => s.stopId).toSet();
    }
    return selectedRoute!.stopIds.toSet();
  }

  MapScreenState copyWith({
    List<Stop>? stops,
    List<BusRoute>? routes,
    BusRoute? selectedRoute,
    bool clearSelectedRoute = false,
    List<RouteStopOccurrence>? selectedRouteStops,
    Stop? selectedStop,
    bool clearSelectedStop = false,
    GeoPoint? cameraCenter,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MapScreenState(
      stops: stops ?? this.stops,
      routes: routes ?? this.routes,
      selectedRoute:
          clearSelectedRoute ? null : (selectedRoute ?? this.selectedRoute),
      selectedRouteStops: selectedRouteStops ?? this.selectedRouteStops,
      selectedStop:
          clearSelectedStop ? null : (selectedStop ?? this.selectedStop),
      cameraCenter: cameraCenter ?? this.cameraCenter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MapStateNotifier extends Notifier<MapScreenState> {
  @override
  MapScreenState build() {
    Future.microtask(loadTransitData);
    return const MapScreenState(isLoading: true);
  }

  Future<void> loadTransitData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(transitRepositoryProvider);
      final stops = await repo.getStops();
      final routes = await repo.getRoutes();

      BusRoute? initialRoute;
      List<RouteStopOccurrence> initialRouteStops = [];

      if (routes.isNotEmpty) {
        initialRoute = routes.first;
        if (initialRoute.stopOccurrences.isNotEmpty) {
          initialRouteStops = initialRoute.stopOccurrences;
        } else {
          initialRouteStops = await repo.getRouteStops(initialRoute.id);
        }
      }

      state = state.copyWith(
        stops: stops,
        routes: routes,
        selectedRoute: initialRoute,
        selectedRouteStops: initialRouteStops,
        isLoading: false,
        clearError: true,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load transit data for map screen',
        error: e,
        stackTrace: stackTrace,
        tag: 'MapStateNotifier',
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Unable to load campus transit stops. Please check your network.',
      );
    }
  }

  Future<void> selectRoute(BusRoute route) async {
    List<RouteStopOccurrence> occurrences = route.stopOccurrences;
    if (occurrences.isEmpty) {
      final repo = ref.read(transitRepositoryProvider);
      occurrences = await repo.getRouteStops(route.id);
    }

    state = state.copyWith(
      selectedRoute: route,
      selectedRouteStops: occurrences,
      clearSelectedStop: true,
    );
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
