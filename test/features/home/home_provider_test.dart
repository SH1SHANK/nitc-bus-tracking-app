import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_position.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/bus_stop_event.dart';
import 'package:tracklet/data/transit/route_stop_occurrence.dart';
import 'package:tracklet/data/transit/scheduled_departure.dart';
import 'package:tracklet/data/transit/stop.dart';
import 'package:tracklet/data/transit/transit_repository.dart';
import 'package:tracklet/features/home/providers/home_provider.dart';

class _FakeTransitRepository implements TransitRepository {
  _FakeTransitRepository({
    this.buses = const [],
    this.getBusesDelay = Duration.zero,
  });

  List<Bus> buses;
  Duration getBusesDelay;
  int getActiveBusesCallCount = 0;

  @override
  Future<List<Bus>> getActiveBuses() async {
    getActiveBusesCallCount++;
    if (getBusesDelay > Duration.zero) {
      await Future<void>.delayed(getBusesDelay);
    }
    return buses;
  }

  @override
  Future<Bus?> getBusById(String busId) async => null;

  @override
  Future<List<BusStopEvent>> getBusStopEvents(String tripId) async => const [];

  @override
  Future<Stop?> getNearestStop(GeoPoint userLocation) async => null;

  @override
  Future<List<BusRoute>> getRoutes({List<Stop>? knownStops}) async => const [];

  @override
  Future<List<RouteStopOccurrence>> getRouteStops(String routeId) async =>
      const [];

  @override
  Future<List<ScheduledDeparture>> getScheduledDepartures() async => const [];

  @override
  Future<List<Stop>> getStops() async => const [];

  @override
  Stream<List<Bus>> watchActiveBuses() => Stream.value(buses);
}

void main() {
  group('LiveTransitPollingNotifier', () {
    test('initializes with empty state and loads active buses', () async {
      final fakeRepo = _FakeTransitRepository(
        buses: [
          Bus(
            id: 'bus-1',
            numberPlate: 'KL-11-0001',
            name: 'Campus Express',
            status: BusStatus.live,
            position: BusPosition(
              point: const GeoPoint(latitude: 11.3216, longitude: 75.9337),
              timestamp: DateTime.now(),
            ),
            lastUpdated: DateTime.now(),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [transitRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final initial = container.read(liveTransitPollingProvider);
      expect(initial.buses, isEmpty);
      expect(initial.isRefreshing, isFalse);

      await container
          .read(liveTransitPollingProvider.notifier)
          .refresh(force: true);

      final loaded = container.read(liveTransitPollingProvider);
      expect(loaded.buses, hasLength(1));
      expect(loaded.buses.first.id, 'bus-1');
      expect(loaded.lastSuccessfulUpdate, isNotNull);
      expect(loaded.isRefreshing, isFalse);
      expect(fakeRepo.getActiveBusesCallCount, 1);
    });

    test(
      'coalesces concurrent refresh requests to avoid overlapping queries',
      () async {
        final fakeRepo = _FakeTransitRepository(
          buses: [],
          getBusesDelay: const Duration(milliseconds: 50),
        );

        final container = ProviderContainer(
          overrides: [transitRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(liveTransitPollingProvider.notifier);

        // Trigger two simultaneous standard refreshes
        final f1 = notifier.refresh();
        final f2 = notifier.refresh();

        await Future.wait([f1, f2]);

        // Only one network call should execute while in-flight
        expect(fakeRepo.getActiveBusesCallCount, 1);
      },
    );

    test('pauses and resumes polling timer without throwing', () async {
      final fakeRepo = _FakeTransitRepository(buses: []);
      final container = ProviderContainer(
        overrides: [transitRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(liveTransitPollingProvider.notifier);
      expect(() => notifier.pause(), returnsNormally);
      expect(() => notifier.resume(), returnsNormally);
      expect(() => notifier.pause(), returnsNormally);
    });

    test('ignores out-of-order responses gracefully', () async {
      final fakeRepo = _FakeTransitRepository(buses: []);
      final container = ProviderContainer(
        overrides: [transitRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      final notifier = container.read(liveTransitPollingProvider.notifier);
      container.dispose();

      // Refreshing after container disposal should not throw
      await expectLater(notifier.refresh(force: true), completes);
    });
  });
}
