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
  });
}
