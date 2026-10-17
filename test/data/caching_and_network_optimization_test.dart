import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/academic/department_repository.dart';
import 'package:tracklet/data/campus/campus_building_repository.dart';
import 'package:tracklet/data/campus/hostel_repository.dart';
import 'package:tracklet/data/profile/profile_repository.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_position.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/bus_stop_event.dart';
import 'package:tracklet/data/transit/route_stop_occurrence.dart';
import 'package:tracklet/data/transit/scheduled_departure.dart';
import 'package:tracklet/data/transit/stop.dart';
import 'package:tracklet/data/transit/transit_cache_metrics.dart';
import 'package:tracklet/data/transit/transit_repository.dart';
import 'package:tracklet/features/home/providers/home_provider.dart';

class _MockTransitRepository implements TransitRepository {
  _MockTransitRepository();

  List<Bus> buses = const [];
  List<Stop> stops = const [];
  List<BusRoute> routes = const [];
  List<ScheduledDeparture> departures = const [];

  final StreamController<List<Bus>> _streamController =
      StreamController<List<Bus>>.broadcast();

  int getActiveBusesCount = 0;
  int watchActiveBusesCount = 0;

  void emitBuses(List<Bus> newBuses) {
    buses = newBuses;
    _streamController.add(newBuses);
  }

  @override
  Future<List<Bus>> getActiveBuses() async {
    getActiveBusesCount++;
    return buses;
  }

  @override
  Stream<List<Bus>> watchActiveBuses() {
    watchActiveBusesCount++;
    return _streamController.stream;
  }

  @override
  Future<Bus?> getBusById(String busId) async =>
      buses.where((b) => b.id == busId).firstOrNull;

  @override
  Future<List<BusStopEvent>> getBusStopEvents(String tripId) async => const [];

  @override
  Future<Stop?> getNearestStop(GeoPoint userLocation) async =>
      stops.firstOrNull;

  @override
  Future<List<BusRoute>> getRoutes({List<Stop>? knownStops}) async => routes;

  @override
  Future<List<RouteStopOccurrence>> getRouteStops(String routeId) async =>
      const [];

  @override
  Future<List<ScheduledDeparture>> getScheduledDepartures() async => departures;

  @override
  Future<List<Stop>> getStops() async => stops;
}

void main() {
  setUp(() {
    TransitCacheMetrics.instance.reset();
  });

  group('TransitCacheMetrics', () {
    test(
      'accurately increments hits, misses, dedups, broadcasts, and polls',
      () {
        final metrics = TransitCacheMetrics.instance;
        expect(metrics.totalCacheHits, 0);
        expect(metrics.totalCacheMisses, 0);
        expect(metrics.totalDeduplicatedRequests, 0);

        metrics.recordHit('stops');
        metrics.recordHit('stops');
        metrics.recordMiss('stops');
        metrics.recordDeduplicated('stops');
        metrics.recordRealtimeBroadcast();
        metrics.recordFallbackPoll();

        expect(metrics.totalCacheHits, 2);
        expect(metrics.totalCacheMisses, 1);
        expect(metrics.totalDeduplicatedRequests, 1);
        expect(metrics.totalRealtimeBroadcasts, 1);
        expect(metrics.totalFallbackPolls, 1);
        expect(metrics.getHits('stops'), 2);
        expect(metrics.getMisses('stops'), 1);
        expect(metrics.getDeduplications('stops'), 1);

        final snapshot = metrics.snapshot();
        expect(snapshot['totalCacheHits'], 2);
        expect(snapshot['totalCacheMisses'], 1);
        expect(snapshot['totalRealtimeBroadcasts'], 1);
        expect(snapshot['totalFallbackPolls'], 1);
      },
    );
  });

  group('SupabaseTransitRepository In-Flight Coalescing & Cache Behavior', () {
    test(
      'returns empty without making network calls when client is null',
      () async {
        final repo = SupabaseTransitRepository(null);
        expect(await repo.getStops(), isEmpty);
        expect(await repo.getRoutes(), isEmpty);
        expect(await repo.getRouteStops('r1'), isEmpty);
        expect(await repo.getScheduledDepartures(), isEmpty);
        expect(await repo.getActiveBuses(), isEmpty);
        expect(await repo.watchActiveBuses().first, isEmpty);
        repo.dispose();
      },
    );

    test('static cache invalidation clears cached reference data', () async {
      final repo = SupabaseTransitRepository(null);
      repo.invalidateStaticCaches();
      expect(await repo.getStops(), isEmpty);
      repo.dispose();
    });
  });

  group('Profile Caching and Request Deduplication', () {
    test('guest profile is cached immediately without calling RPC', () async {
      final repo = LocalOrSupabaseProfileRepository(null);
      final p1 = await repo.getProfile();
      expect(p1.id, 'guest');
      expect(p1.role, 'Student');

      final p2 = await repo.getProfile();
      expect(identical(p1, p2) || p1 == p2, isTrue);
    });

    test('invalidateCache clears cached profile and allows reload', () async {
      final repo = LocalOrSupabaseProfileRepository(null);
      final p1 = await repo.getProfile();
      repo.invalidateCache();
      final p2 = await repo.getProfile();
      expect(p1.id, p2.id);
    });
  });

  group('Live Transit Stream Single Source of Truth', () {
    test(
      'LiveTransitPollingNotifier receives live stream events without periodic polling timer',
      () async {
        final mockRepo = _MockTransitRepository();
        final container = ProviderContainer(
          overrides: [transitRepositoryProvider.overrideWithValue(mockRepo)],
        );
        addTearDown(container.dispose);
        final sub = container.listen(liveTransitPollingProvider, (_, _) {});
        addTearDown(sub.close);

        final notifier = container.read(liveTransitPollingProvider.notifier);
        final initial = container.read(liveTransitPollingProvider);
        expect(initial.buses, isEmpty);

        // Verify watchActiveBuses was called to subscribe to live stream
        expect(mockRepo.watchActiveBusesCount, 1);
        expect(mockRepo.getActiveBusesCount, 0);

        // Emit live bus update via broadcast stream
        final testBus = Bus(
          id: 'bus-1',
          name: 'Campus Shuttle',
          numberPlate: 'KL-11-TEST',
          status: BusStatus.live,
          position: BusPosition(
            point: const GeoPoint(latitude: 11.3216, longitude: 75.9337),
            timestamp: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );

        mockRepo.emitBuses([testBus]);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final updated = container.read(liveTransitPollingProvider);
        expect(updated.buses, hasLength(1));
        expect(updated.buses.first.id, 'bus-1');
        expect(updated.lastSuccessfulUpdate, isNotNull);

        // Manual refresh still invokes getActiveBuses on demand
        await notifier.refresh(force: true);
        expect(mockRepo.getActiveBusesCount, 1);
      },
    );

    test(
      'pause and resume correctly pause and resume live stream subscription',
      () async {
        final mockRepo = _MockTransitRepository();
        final container = ProviderContainer(
          overrides: [transitRepositoryProvider.overrideWithValue(mockRepo)],
        );
        addTearDown(container.dispose);
        final sub = container.listen(liveTransitPollingProvider, (_, _) {});
        addTearDown(sub.close);

        final notifier = container.read(liveTransitPollingProvider.notifier);
        notifier.pause();

        final testBus = Bus(
          id: 'bus-paused',
          name: 'Paused Shuttle',
          numberPlate: 'KL-11-PAUSED',
          status: BusStatus.live,
          position: BusPosition(
            point: const GeoPoint(latitude: 11.3216, longitude: 75.9337),
            timestamp: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );
        mockRepo.emitBuses([testBus]);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Should still be empty because stream was paused
        final pausedState = container.read(liveTransitPollingProvider);
        expect(pausedState.buses, isEmpty);

        // Resuming triggers refresh
        await notifier.resume();
        expect(mockRepo.getActiveBusesCount, 1);
      },
    );
  });

  group(
    'Campus Reference Repositories Caching and In-Flight Deduplication',
    () {
      test(
        'CampusBuildingRepository caches in memory and invalidates on request',
        () async {
          final repo = SupabaseCampusBuildingRepository(null);
          final b1 = await repo.getBuildings();
          expect(b1, isEmpty);
          repo.invalidateCache();
          final b2 = await repo.getBuildings();
          expect(b2, isEmpty);
        },
      );

      test(
        'HostelRepository caches in memory and invalidates on request',
        () async {
          final repo = SupabaseHostelRepository(null);
          final h1 = await repo.getHostels();
          expect(h1, isEmpty);
          repo.invalidateCache();
          final h2 = await repo.getHostels();
          expect(h2, isEmpty);
        },
      );

      test(
        'DepartmentRepository caches in memory and invalidates on request',
        () async {
          final repo = SupabaseDepartmentRepository(null);
          final d1 = await repo.getDepartments();
          expect(d1, isEmpty);
          repo.invalidateCache();
          final d2 = await repo.getDepartments();
          expect(d2, isEmpty);
        },
      );
    },
  );
}
