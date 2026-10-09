import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/stop.dart';

void main() {
  group('Stop Model', () {
    test('serializes and deserializes from JSON', () {
      const stop = Stop(
        id: 'stop-lhc',
        name: 'Lecture Hall Complex',
        code: 'LHC',
        location: GeoPoint(latitude: 11.3228, longitude: 75.9348),
        walkingTimeMinutes: 4,
        isMajorHub: true,
      );

      final json = stop.toJson();
      final fromJson = Stop.fromJson(json);

      expect(fromJson.id, equals('stop-lhc'));
      expect(fromJson.name, equals('Lecture Hall Complex'));
      expect(fromJson.code, equals('LHC'));
      expect(fromJson.isMajorHub, isTrue);
      expect(fromJson.walkingTimeMinutes, equals(4));
    });

    test(
      'parses the supplied stop row shape and preserves its source slug',
      () {
        final stop = Stop.fromJson({
          'id': '1db6c799-56e2-49c2-8e7b-1799fad1b0a6',
          'stop_id': 'department_building',
          'name': 'Department Building',
          'lat': 11.321778,
          'lng': 75.935111,
          'nearest_node_id': 12509565487,
          'is_active': true,
          'description': 'Bus stop near Main Department Buildings',
        });

        expect(stop.id, '1db6c799-56e2-49c2-8e7b-1799fad1b0a6');
        expect(stop.sourceStopId, 'department_building');
        expect(stop.location.latitude, 11.321778);
        expect(stop.location.longitude, 75.935111);
        expect(stop.nearestNodeId, '12509565487');
        expect(stop.isActive, isTrue);
      },
    );
  });
}
