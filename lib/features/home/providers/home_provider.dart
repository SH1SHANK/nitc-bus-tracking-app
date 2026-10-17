import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/preferences/user_preferences.dart';
import '../../../data/profile/profile.dart';
import '../../../data/profile/profile_repository.dart';
import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/bus_stop_progress.dart';
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

class LiveTransitPollingState {
  const LiveTransitPollingState({
    this.buses = const [],
    this.lastSuccessfulUpdate,
    this.isRefreshing = false,
    this.error,
  });

  final List<Bus> buses;
  final DateTime? lastSuccessfulUpdate;
  final bool isRefreshing;
  final Object? error;

  LiveTransitPollingState copyWith({
    List<Bus>? buses,
    DateTime? lastSuccessfulUpdate,
    bool? isRefreshing,
    Object? error,
  }) {
    return LiveTransitPollingState(
      buses: buses ?? this.buses,
      lastSuccessfulUpdate: lastSuccessfulUpdate ?? this.lastSuccessfulUpdate,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
    );
  }
}

class LiveTransitPollingNotifier extends Notifier<LiveTransitPollingState> {
  StreamSubscription<List<Bus>>? _busSubscription;
  bool _isRefreshing = false;
  bool _isPaused = false;
  bool _isDisposed = false;
  int _refreshGeneration = 0;

  @override
  LiveTransitPollingState build() {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
      _busSubscription?.cancel();
    });
    _listenToBusStream();
    return const LiveTransitPollingState();
  }

  void _listenToBusStream() {
    _busSubscription?.cancel();
    final repository = ref.read(transitRepositoryProvider);
    _busSubscription = repository.watchActiveBuses().listen(
      (buses) {
        if (_isDisposed || _isPaused) return;
        state = LiveTransitPollingState(
          buses: buses,
          lastSuccessfulUpdate: DateTime.now(),
          isRefreshing: false,
          error: null,
        );
      },
      onError: (Object error) {
        if (_isDisposed || _isPaused) return;
        state = state.copyWith(isRefreshing: false, error: error);
      },
    );
  }

  void pause() {
    _isPaused = true;
    _busSubscription?.pause();
  }

  Future<void> resume() async {
    if (_isPaused) {
      _isPaused = false;
      if (_busSubscription?.isPaused ?? false) {
        _busSubscription?.resume();
      }
      await refresh();
    }
  }

  Future<void> refresh({bool force = false}) async {
    if (_isRefreshing && !force) return;
    final gen = ++_refreshGeneration;
    _isRefreshing = true;
    if (!_isDisposed) {
      state = state.copyWith(isRefreshing: true);
    }

    try {
      final repository = ref.read(transitRepositoryProvider);
      final activeBuses = await repository.getActiveBuses();
      if (_isDisposed || gen != _refreshGeneration) return;
      state = LiveTransitPollingState(
        buses: activeBuses,
        lastSuccessfulUpdate: DateTime.now(),
        isRefreshing: false,
        error: null,
      );
    } catch (e) {
      if (_isDisposed || gen != _refreshGeneration) return;
      state = state.copyWith(isRefreshing: false, error: e);
    } finally {
      if (gen == _refreshGeneration) {
        _isRefreshing = false;
      }
    }
  }
}

final liveTransitPollingProvider = NotifierProvider.autoDispose<
  LiveTransitPollingNotifier,
  LiveTransitPollingState
>(LiveTransitPollingNotifier.new);

final activeBusesStreamProvider = StreamProvider.autoDispose<List<Bus>>((ref) {
  final repo = ref.watch(transitRepositoryProvider);
  return repo.watchActiveBuses();
});

/// Periodic tick stream (every 5 seconds) used for dynamic telemetry age updates
/// ("Updated X ago") and rapid staleness evaluation (>90s) without full screen rebuild.
final homeClockProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 5), (_) => DateTime.now());
});

final homeStateProvider = FutureProvider.autoDispose<HomeTransitState>((
  ref,
) async {
  final profileRepo = ref.watch(profileRepositoryProvider);
  final transitRepo = ref.watch(transitRepositoryProvider);
  final preferences = ref.watch(userPreferencesProvider);

  final (profile, stops, activeBuses, scheduledDepartures) =
      await (
        profileRepo.getProfile(),
        transitRepo.getStops(),
        transitRepo.getActiveBuses(),
        transitRepo.getScheduledDepartures(),
      ).wait;
  final routes = await transitRepo.getRoutes(knownStops: stops);

  final preferredStop =
      stops
          .where(
            (stop) =>
                stop.id == preferences.preferredStopId ||
                stop.sourceStopId == preferences.preferredStopId ||
                stop.name == preferences.preferredStopName,
          )
          .firstOrNull;

  final selectedStop =
      preferredStop ??
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

/// Batch provider that resolves stop progress for active buses without build-time loops.
final activeBusesProgressProvider = FutureProvider.autoDispose<
  Map<String, BusStopProgress?>
>((ref) async {
  final repo = ref.watch(transitRepositoryProvider);
  final pollingBuses = ref.watch(liveTransitPollingProvider).buses;
  final homeState = await ref.watch(homeStateProvider.future);
  final activeBuses = pollingBuses.isNotEmpty ? pollingBuses : homeState.buses;
  final routesById = {for (final route in homeState.routes) route.id: route};

  final progressMap = <String, BusStopProgress?>{};
  for (final bus in activeBuses) {
    final tripId = bus.tripId;
    final route = routesById[bus.routeId];
    if (tripId != null && route != null) {
      try {
        final events = await repo.getBusStopEvents(tripId);
        progressMap[bus.id] = resolveBusStopProgress(
          routeStops: route.stopOccurrences,
          events: events,
          direction: route.direction,
        );
      } catch (_) {
        progressMap[bus.id] = null;
      }
    }
  }
  return progressMap;
});
