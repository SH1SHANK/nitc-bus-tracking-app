import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';

void main() {
  group('GeoPoint', () {
    test('calculates correct Haversine distance between two coordinates', () {
      const p1 = GeoPoint(latitude: 11.3216, longitude: 75.9337);
      const p2 = GeoPoint(latitude: 11.3228, longitude: 75.9348);

      final dist = p1.distanceToMeters(p2);
      expect(dist, greaterThan(150.0));
      expect(dist, lessThan(200.0));
    });

    test('serializes to and from json', () {
      const point = GeoPoint(latitude: 11.3216, longitude: 75.9337);
      final json = point.toJson();
      final deserialized = GeoPoint.fromJson(json);

      expect(deserialized, equals(point));
    });

    test('equality and hashCode match for identical coordinates', () {
      const p1 = GeoPoint(latitude: 11.3216, longitude: 75.9337);
      const p2 = GeoPoint(latitude: 11.3216, longitude: 75.9337);

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });
}
