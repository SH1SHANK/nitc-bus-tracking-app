import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/transit_repository.dart';

void main() {
  group('SupabaseTransitRepository fallback / offline mode', () {
    late TransitRepository repository;

    setUp(() {
      repository = SupabaseTransitRepository(null);
    });

    test('does not label missing bus positions as simulated telemetry', () {
      expect(repository.usesSimulatedTelemetry, isFalse);
    });

    test('returns the supplied stop records when Supabase is null', () async {
      final stops = await repository.getStops();
      expect(stops, hasLength(9));
      expect(stops.map((stop) => stop.sourceStopId), contains('main_gate'));
      expect(
        stops.firstWhere((stop) => stop.sourceStopId == 'main_gate').location,
        const GeoPoint(latitude: 11.320083, longitude: 75.932722),
      );
    });

    test('returns canonical R1-R4 campus loop routes with explicit missing geometry', () async {
      final routes = await repository.getRoutes();
      expect(routes, hasLength(4));

      final routeCodes = routes.map((r) => r.code).toList();
      expect(routeCodes, containsAll(['R1', 'R2', 'R3', 'R4']));

      for (final route in routes) {
        expect(route.isGeometryMissing, isTrue);
        expect(route.path, isEmpty);
        expect(route.stopOccurrences, isNotEmpty);
      }
    });

    test('fetches ordered route stop occurrences for selected route', () async {
      final r1Stops = await repository.getRouteStops(
        '10000000-0000-4000-8000-000000000001',
      );
      expect(r1Stops, hasLength(8));
      expect(r1Stops[0].stop?.name, 'East Campus');
      expect(r1Stops[1].stop?.name, 'Architecture');
      expect(r1Stops[2].stop?.name, 'Center Circle');
      expect(r1Stops[3].stop?.name, 'Main Gate');
      expect(r1Stops[4].stop?.name, 'Mega Hostel Boys');
      // Preserves repeated occurrences on return loop
      expect(r1Stops[5].stop?.name, 'Main Gate');
      expect(r1Stops[6].stop?.name, 'Center Circle');
      expect(r1Stops[7].stop?.name, 'Architecture');
    });

    test('does not fabricate buses when no telemetry was supplied', () async {
      expect(await repository.getActiveBuses(), isEmpty);
    });

    test(
      'has no scheduled departures without a configured data source',
      () async {
        expect(await repository.getScheduledDepartures(), isEmpty);
      },
    );

    test('finds nearest stop accurately', () async {
      const userNearMainGate = GeoPoint(latitude: 11.3201, longitude: 75.9328);
      final nearest = await repository.getNearestStop(userNearMainGate);

      expect(nearest, isNotNull);
      expect(nearest!.sourceStopId, equals('main_gate'));
    });
  });
}
