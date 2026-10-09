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
    bool? isLoadingRouteStops,
    String? routeStopsError,
    bool clearRouteStopsError = false,
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
      isLoadingRouteStops: isLoadingRouteStops ?? this.isLoadingRouteStops,
      routeStopsError:
          clearRouteStopsError
              ? null
              : (routeStopsError ?? this.routeStopsError),
    );
  }
}

class MapStateNotifier extends Notifier<MapScreenState> {
  int _loadGeneration = 0;
  int _routeSelectionGeneration = 0;
  bool _isLoadingTransitData = false;

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
      final routes = await repo.getRoutes();

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
    } catch (e, stackTrace) {
      if (generation != _loadGeneration) return;
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
    } finally {
      if (generation == _loadGeneration) _isLoadingTransitData = false;
    }
  }

  Future<void> selectRoute(BusRoute route) async {
    final generation = ++_routeSelectionGeneration;
    final initialOccurrences = List<RouteStopOccurrence>.of(
      route.stopOccurrences,
    )..sort((a, b) => a.sequence.compareTo(b.sequence));

    state = state.copyWith(
      selectedRoute: route,
      selectedRouteStops: initialOccurrences,
      clearSelectedStop: true,
      isLoadingRouteStops: initialOccurrences.isEmpty,
      clearRouteStopsError: true,
    );

    if (initialOccurrences.isNotEmpty) return;

    try {
      final repo = ref.read(transitRepositoryProvider);
      final occurrences = await repo.getRouteStops(route.id)
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      if (generation != _routeSelectionGeneration ||
          state.selectedRoute?.id != route.id) {
        return;
      }
      state = state.copyWith(
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
