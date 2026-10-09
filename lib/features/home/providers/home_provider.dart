import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/geo_point.dart';
import '../../../data/profile/profile.dart';
import '../../../data/profile/profile_repository.dart';
import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/scheduled_departure.dart';
import '../../../data/transit/stop.dart';
import '../../../data/transit/transit_repository.dart';

class HomeTransitState {
  const HomeTransitState({
    required this.userProfile,
    required this.selectedStop,
    required this.stops,
    required this.routes,
    required this.buses,
    required this.scheduledDepartures,
    required this.usesSimulatedTelemetry,
    required this.isLoading,
    this.errorMessage,
  });

  final Profile userProfile;
  final Stop selectedStop;
  final List<Stop> stops;
  final List<BusRoute> routes;
  final List<Bus> buses;
  final List<ScheduledDeparture> scheduledDepartures;
  final bool usesSimulatedTelemetry;
  final bool isLoading;
  final String? errorMessage;

  HomeTransitState copyWith({
    Profile? userProfile,
    Stop? selectedStop,
    List<Stop>? stops,
    List<BusRoute>? routes,
    List<Bus>? buses,
    List<ScheduledDeparture>? scheduledDepartures,
    bool? usesSimulatedTelemetry,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeTransitState(
      userProfile: userProfile ?? this.userProfile,
      selectedStop: selectedStop ?? this.selectedStop,
      stops: stops ?? this.stops,
      routes: routes ?? this.routes,
      buses: buses ?? this.buses,
      scheduledDepartures: scheduledDepartures ?? this.scheduledDepartures,
      usesSimulatedTelemetry:
          usesSimulatedTelemetry ?? this.usesSimulatedTelemetry,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final activeBusesStreamProvider = StreamProvider.autoDispose<List<Bus>>((ref) {
  final repo = ref.watch(transitRepositoryProvider);
  return repo.watchActiveBuses();
});

final homeStateProvider = FutureProvider.autoDispose<HomeTransitState>((
  ref,
) async {
  final profileRepo = ref.watch(profileRepositoryProvider);
  final transitRepo = ref.watch(transitRepositoryProvider);

  final profile = await profileRepo.getProfile();
  final stops = await transitRepo.getStops();
  final routes = await transitRepo.getRoutes();
  final activeBuses = await transitRepo.getActiveBuses();
  final scheduledDepartures = await transitRepo.getScheduledDepartures();

  final selectedStop =
      stops
          .where(
            (stop) =>
                stop.sourceStopId == 'main_gate' || stop.name == 'Main Gate',
          )
          .firstOrNull ??
      (stops.isNotEmpty
          ? stops.first
          : const Stop(
              id: 'stop-default',
              name: 'Main Gate',
              code: 'MG',
              location: GeoPoint(latitude: 11.320083, longitude: 75.932722),
              walkingTimeMinutes: 2,
            ));

  return HomeTransitState(
    userProfile: profile,
    selectedStop: selectedStop,
    stops: stops,
    routes: routes,
    buses: activeBuses,
    scheduledDepartures: scheduledDepartures,
    usesSimulatedTelemetry: transitRepo.usesSimulatedTelemetry,
    isLoading: false,
  );
});
