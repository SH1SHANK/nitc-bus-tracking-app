import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/transit_repository.dart';

void main() {
  group('SupabaseTransitRepository fallback / offline mode', () {
    late TransitRepository repository;

    setUp(() {
      repository = SupabaseTransitRepository(null);
    });

    test('returns default NITC stops when Supabase is null', () async {
      final stops = await repository.getStops();
      expect(stops.isNotEmpty, isTrue);
      expect(stops.any((s) => s.code == 'MG'), isTrue);
    });

    test('returns default NITC routes when Supabase is null', () async {
      final routes = await repository.getRoutes();
      expect(routes.isNotEmpty, isTrue);
      expect(routes.first.name, contains('Campus Express'));
    });

    test('finds nearest stop accurately', () async {
      // Near Main gate (11.3216, 75.9337)
      const userNearMainGate = GeoPoint(latitude: 11.3217, longitude: 75.9338);
      final nearest = await repository.getNearestStop(userNearMainGate);

      expect(nearest, isNotNull);
      expect(nearest!.id, equals('stop-main-gate'));
    });
  });
}
