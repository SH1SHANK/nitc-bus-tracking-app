import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus_stop_event.dart';
import 'package:tracklet/data/transit/transit_repository.dart';

void main() {
  group('SupabaseTransitRepository without a configured client', () {
    late SupabaseTransitRepository repository;

    setUp(() {
      repository = SupabaseTransitRepository(null);
    });

    test('returns no fabricated institutional transit data', () async {
      expect(await repository.getStops(), isEmpty);
      expect(await repository.getRoutes(), isEmpty);
      expect(await repository.getRouteStops('route-id'), isEmpty);
      expect(await repository.getActiveBuses(), isEmpty);
      expect(await repository.getScheduledDepartures(), isEmpty);
      expect(await repository.getBusById('bus-id'), isNull);
    });

    test(
      'nearest stop is absent when no database stops are available',
      () async {
        const location = GeoPoint(latitude: 11.3216, longitude: 75.9337);
        expect(await repository.getNearestStop(location), isNull);
      },
    );

    test('live bus stream emits no fabricated buses', () async {
      expect(await repository.watchActiveBuses().first, isEmpty);
    });

    test(
      'stop event read degrades to empty when Supabase is unavailable',
      () async {
        expect(await repository.getBusStopEvents('trip-1'), isEmpty);
      },
    );
  });

  test(
    'stop event reads deduplicate, cache, expire, and invalidate by trip',
    () async {
      var now = DateTime.utc(2026, 10, 14);
      var loads = 0;
      final gate = Completer<List<BusStopEvent>>();
      final repository = SupabaseTransitRepository(
        null,
        clock: () => now,
        stopEventLoader: (_) {
          loads++;
          return gate.future;
        },
      );
      final first = repository.getBusStopEvents('trip-1');
      final second = repository.getBusStopEvents('trip-1');
      expect(loads, 1);
      gate.complete([
        BusStopEvent(stopId: 'stop-1', type: 'arrived', occurredAt: now),
      ]);
      expect(await first, hasLength(1));
      expect(await second, hasLength(1));
      await repository.getBusStopEvents('trip-1');
      expect(loads, 1);

      now = now.add(const Duration(seconds: 11));
      await repository.getBusStopEvents('trip-1');
      expect(loads, 2);
      repository.invalidateBusStopEvents('trip-1');
      await repository.getBusStopEvents('trip-1');
      expect(loads, 3);
    },
  );

  test(
    'stop event loader errors degrade without caching a false progress state',
    () async {
      var loads = 0;
      final repository = SupabaseTransitRepository(
        null,
        stopEventLoader: (_) async {
          loads++;
          if (loads == 1) throw StateError('temporary RLS/network error');
          return const [];
        },
      );
      final first = repository.getBusStopEvents('trip-1');
      final second = repository.getBusStopEvents('trip-1');
      expect(await first, isEmpty);
      expect(await second, isEmpty);
      expect(loads, 1);
      expect(await repository.getBusStopEvents('trip-1'), isEmpty);
      expect(loads, 2);
    },
  );
}
