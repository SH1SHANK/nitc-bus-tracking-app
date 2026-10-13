import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
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
  });
}
