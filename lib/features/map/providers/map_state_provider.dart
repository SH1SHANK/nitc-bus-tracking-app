import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/geo_point.dart';
import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/stop.dart';
import '../../../data/transit/transit_repository.dart';
import '../../../services/maps/map_config.dart';

class MapScreenState {
  const MapScreenState({
    required this.buses,
    required this.stops,
    required this.routes,
    this.selectedBus,
    this.selectedStop,
    this.activeRoute,
    this.userLocation,
    this.cameraCenter = MapConfig.campusCenter,
    this.isLoading = false,
  });

  final List<Bus> buses;
  final List<Stop> stops;
  final List<BusRoute> routes;
  final Bus? selectedBus;
  final Stop? selectedStop;
  final BusRoute? activeRoute;
  final GeoPoint? userLocation;
  final GeoPoint cameraCenter;
  final bool isLoading;

  MapScreenState copyWith({
    List<Bus>? buses,
    List<Stop>? stops,
    List<BusRoute>? routes,
    Bus? selectedBus,
    bool clearSelectedBus = false,
    Stop? selectedStop,
    bool clearSelectedStop = false,
    BusRoute? activeRoute,
    bool clearActiveRoute = false,
    GeoPoint? userLocation,
    GeoPoint? cameraCenter,
    bool? isLoading,
  }) {
    return MapScreenState(
      buses: buses ?? this.buses,
      stops: stops ?? this.stops,
      routes: routes ?? this.routes,
      selectedBus: clearSelectedBus ? null : (selectedBus ?? this.selectedBus),
      selectedStop: clearSelectedStop
          ? null
          : (selectedStop ?? this.selectedStop),
      activeRoute: clearActiveRoute ? null : (activeRoute ?? this.activeRoute),
      userLocation: userLocation ?? this.userLocation,
      cameraCenter: cameraCenter ?? this.cameraCenter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MapStateNotifier extends Notifier<MapScreenState> {
  @override
  MapScreenState build() {
    // Initial fetch of static transit entities
    Future.microtask(_loadInitialData);

    // Subscribe to live bus stream
    final repo = ref.watch(transitRepositoryProvider);
    final sub = repo.watchActiveBuses().listen((updatedBuses) {
      state = state.copyWith(buses: updatedBuses);
      if (state.selectedBus != null) {
        final updatedSelected = updatedBuses
            .where((b) => b.id == state.selectedBus!.id)
            .firstOrNull;
        if (updatedSelected != null) {
          state = state.copyWith(selectedBus: updatedSelected);
        }
      }
    });

    ref.onDispose(sub.cancel);

    return const MapScreenState(
      buses: [],
      stops: [],
      routes: [],
      isLoading: true,
    );
  }

  Future<void> _loadInitialData() async {
    final repo = ref.read(transitRepositoryProvider);
    final stops = await repo.getStops();
    final routes = await repo.getRoutes();
    final buses = await repo.getActiveBuses();

    state = state.copyWith(
      stops: stops,
      routes: routes,
      buses: buses,
      isLoading: false,
      activeRoute: routes.isNotEmpty ? routes.first : null,
    );
  }

  void selectBus(Bus bus) {
    BusRoute? route;
    if (bus.routeId != null) {
      try {
        route = state.routes.firstWhere((r) => r.id == bus.routeId);
      } catch (_) {}
    }

    state = state.copyWith(
      selectedBus: bus,
      clearSelectedStop: true,
      activeRoute: route,
      cameraCenter: bus.position.point,
    );
  }

  void selectStop(Stop stop) {
    state = state.copyWith(
      selectedStop: stop,
      clearSelectedBus: true,
      cameraCenter: stop.location,
    );
  }

  void clearSelection() {
    state = state.copyWith(clearSelectedBus: true, clearSelectedStop: true);
  }

  void updateUserLocation(GeoPoint point) {
    state = state.copyWith(userLocation: point, cameraCenter: point);
  }

  void centerCampus() {
    state = state.copyWith(cameraCenter: MapConfig.campusCenter);
  }
}

final mapStateNotifierProvider =
    NotifierProvider<MapStateNotifier, MapScreenState>(() {
      return MapStateNotifier();
    });
