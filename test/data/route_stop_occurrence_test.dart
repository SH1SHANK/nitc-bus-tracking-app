import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/route_stop_occurrence.dart';
import 'package:tracklet/data/transit/stop.dart';

void main() {
  group('RouteStopOccurrence model', () {
    const testStop = Stop(
      id: 'stop-1',
      code: 'main_gate',
      name: 'Main Gate',
      location: GeoPoint(latitude: 11.320083, longitude: 75.932722),
    );

    test('preserves sequence and referenced stop metadata', () {
      const occurrence = RouteStopOccurrence(
        routeId: 'route-r1',
        stopId: 'stop-1',
        sequence: 3,
        stop: testStop,
        distanceFromStart: 1250.5,
        estimatedDurationSec: 300,
      );

      expect(occurrence.routeId, 'route-r1');
      expect(occurrence.stopId, 'stop-1');
      expect(occurrence.sequence, 3);
      expect(occurrence.stop?.name, 'Main Gate');
      expect(occurrence.distanceFromStart, 1250.5);
      expect(occurrence.estimatedDurationSec, 300);
    });

    test('parses from JSON with nested stop record', () {
      final json = {
        'route_id': 'route-r1',
        'stop_id': 'stop-1',
        'sequence': 0,
        'distance_from_start': 0.0,
        'estimated_duration_sec': 0,
        'stops': {
          'id': 'stop-1',
          'code': 'east_campus',
          'name': 'East Campus',
          'latitude': 11.323361,
          'longitude': 75.937194,
          'is_active': true,
        },
      };

      final occurrence = RouteStopOccurrence.fromJson(json);
      expect(occurrence.routeId, 'route-r1');
      expect(occurrence.stopId, 'stop-1');
      expect(occurrence.sequence, 0);
      expect(occurrence.stop?.name, 'East Campus');
      expect(occurrence.stop?.location.latitude, 11.323361);
    });

    test('maintains equality based on route, stop, and sequence', () {
      const occ1 = RouteStopOccurrence(
        routeId: 'route-1',
        stopId: 'stop-a',
        sequence: 0,
      );
      const occ2 = RouteStopOccurrence(
        routeId: 'route-1',
        stopId: 'stop-a',
        sequence: 0,
      );
      const occRepeated = RouteStopOccurrence(
        routeId: 'route-1',
        stopId: 'stop-a',
        sequence: 5,
      );

      expect(occ1, equals(occ2));
      expect(occ1, isNot(equals(occRepeated)));
    });
  });
}
