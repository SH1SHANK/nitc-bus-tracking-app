import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/geo_point.dart';
import '../../../data/profile/profile.dart';
import '../../../data/profile/profile_repository.dart';
import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/stop.dart';
import '../../../data/transit/transit_repository.dart';

class HomeTransitState {
  const HomeTransitState({
    required this.userProfile,
    required this.selectedStop,
    required this.nextBus,
    required this.nextBusRoute,
    required this.etaMinutes,
    required this.upcomingBuses,
    required this.isLoading,
    this.errorMessage,
  });

  final Profile userProfile;
  final Stop selectedStop;
  final Bus? nextBus;
  final BusRoute? nextBusRoute;
  final int etaMinutes;
  final List<Bus> upcomingBuses;
  final bool isLoading;
  final String? errorMessage;

  HomeTransitState copyWith({
    Profile? userProfile,
    Stop? selectedStop,
    Bus? nextBus,
    BusRoute? nextBusRoute,
    int? etaMinutes,
    List<Bus>? upcomingBuses,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeTransitState(
      userProfile: userProfile ?? this.userProfile,
      selectedStop: selectedStop ?? this.selectedStop,
      nextBus: nextBus ?? this.nextBus,
      nextBusRoute: nextBusRoute ?? this.nextBusRoute,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      upcomingBuses: upcomingBuses ?? this.upcomingBuses,
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

  final selectedStop = stops.isNotEmpty
      ? stops.first
      : const Stop(
          id: 'stop-default',
          name: 'Main Gate',
          code: 'MG',
          location: GeoPoint(latitude: 11.3216, longitude: 75.9337),
          walkingTimeMinutes: 2,
        );

  final nextBus = activeBuses.isNotEmpty ? activeBuses.first : null;
  BusRoute? nextBusRoute;
  if (nextBus?.routeId != null) {
    try {
      nextBusRoute = routes.firstWhere((r) => r.id == nextBus!.routeId);
    } catch (_) {}
  }

  final upcoming = activeBuses.length > 1 ? activeBuses.sublist(1) : <Bus>[];

  return HomeTransitState(
    userProfile: profile,
    selectedStop: selectedStop,
    nextBus: nextBus,
    nextBusRoute: nextBusRoute,
    etaMinutes: 3,
    upcomingBuses: upcoming,
    isLoading: false,
  );
});
