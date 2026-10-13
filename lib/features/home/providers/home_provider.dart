import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    required this.isLoading,
    this.errorMessage,
  });

  final Profile userProfile;
  final Stop? selectedStop;
  final List<Stop> stops;
  final List<BusRoute> routes;
  final List<Bus> buses;
  final List<ScheduledDeparture> scheduledDepartures;

  final bool isLoading;
  final String? errorMessage;

  HomeTransitState copyWith({
    Profile? userProfile,
    Stop? selectedStop,
    List<Stop>? stops,
    List<BusRoute>? routes,
    List<Bus>? buses,
    List<ScheduledDeparture>? scheduledDepartures,

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

      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final activeBusesStreamProvider = StreamProvider.autoDispose<List<Bus>>((ref) {
  final repo = ref.watch(transitRepositoryProvider);
  return repo.watchActiveBuses();
});

/// Periodic tick stream (every 30 seconds) used for updating live departure ETAs
/// without causing a top-level screen rebuild.
final homeClockProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

final homeStateProvider = FutureProvider.autoDispose<HomeTransitState>((
  ref,
) async {
  final profileRepo = ref.watch(profileRepositoryProvider);
  final transitRepo = ref.watch(transitRepositoryProvider);

  final (profile, stops, activeBuses, scheduledDepartures) =
      await (
        profileRepo.getProfile(),
        transitRepo.getStops(),
        transitRepo.getActiveBuses(),
        transitRepo.getScheduledDepartures(),
      ).wait;
  final routes = await transitRepo.getRoutes(knownStops: stops);

  final selectedStop =
      stops
          .where(
            (stop) =>
                stop.sourceStopId == 'main_gate' || stop.name == 'Main Gate',
          )
          .firstOrNull ??
      stops.firstOrNull;

  return HomeTransitState(
    userProfile: profile,
    selectedStop: selectedStop,
    stops: stops,
    routes: routes,
    buses: activeBuses,
    scheduledDepartures: scheduledDepartures,

    isLoading: false,
  );
});
