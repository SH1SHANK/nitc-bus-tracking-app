import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/route_geometry.dart';

void main() {
  group('RouteGeometry model & status classification', () {
    test('handles NULL and empty paths as RouteGeometryStatus.missing', () {
      final nullGeom = RouteGeometry.fromBackend(null);
      expect(nullGeom.status, RouteGeometryStatus.missing);
      expect(nullGeom.isMissing, isTrue);
      expect(nullGeom.isAvailable, isFalse);
      expect(nullGeom.path, isEmpty);

      final emptyListGeom = RouteGeometry.fromBackend(<dynamic>[]);
      expect(emptyListGeom.status, RouteGeometryStatus.missing);
      expect(emptyListGeom.isMissing, isTrue);

      final emptyStrGeom = RouteGeometry.fromBackend('');
      expect(emptyStrGeom.status, RouteGeometryStatus.missing);
    });

    test('correctly parses valid GeoJSON LineString (Longitude-first)', () {
      final geoJson = {
        'type': 'LineString',
        'coordinates': [
          [75.937194, 11.323361],
          [75.936722, 11.323028],
          [75.934083, 11.321333],
        ],
      };

      final geom = RouteGeometry.fromBackend(
        geoJson,
        source: 'osm',
        isVerified: true,
      );

      expect(geom.status, RouteGeometryStatus.available);
      expect(geom.isAvailable, isTrue);
      expect(geom.isVerified, isTrue);
      expect(geom.source, 'osm');
      expect(geom.path, hasLength(3));

      // Verify coordinate order: GeoJSON is [lon, lat], GeoPoint is (lat, lon)
      expect(
        geom.path[0],
        const GeoPoint(latitude: 11.323361, longitude: 75.937194),
      );
      expect(
        geom.path[1],
        const GeoPoint(latitude: 11.323028, longitude: 75.936722),
      );
      expect(
        geom.path[2],
        const GeoPoint(latitude: 11.321333, longitude: 75.934083),
      );
    });

    test('classifies single-point or out-of-bounds LineStrings as invalid', () {
      final singlePointGeoJson = {
        'type': 'LineString',
        'coordinates': [
          [75.937194, 11.323361],
        ],
      };

      final geom = RouteGeometry.fromBackend(singlePointGeoJson);
      expect(geom.status, RouteGeometryStatus.invalid);
      expect(geom.isInvalid, isTrue);
      expect(geom.errorMessage, contains('at least 2 points'));

      final outOfBoundsGeoJson = {
        'type': 'LineString',
        'coordinates': [
          [200.0, 11.323361],
          [75.936722, 11.323028],
        ],
      };

      final invalidGeom = RouteGeometry.fromBackend(outOfBoundsGeoJson);
      expect(invalidGeom.status, RouteGeometryStatus.invalid);
      expect(invalidGeom.errorMessage, contains('out of bounds'));
    });

    test('correctly parses valid stringified GeoJSON LineString', () {
      const geoJsonString =
          '{"type": "LineString", "coordinates": [[75.937194, 11.323361], [75.934083, 11.321333]]}';

      final geom = RouteGeometry.fromBackend(geoJsonString, source: 'rpc');
      expect(geom.status, RouteGeometryStatus.available);
      expect(geom.isAvailable, isTrue);
      expect(geom.path, hasLength(2));
      expect(
        geom.path[0],
        const GeoPoint(latitude: 11.323361, longitude: 75.937194),
      );
    });

    test('handles malformed stringified JSON gracefully as invalid', () {
      const malformedJson = '{"type": "LineString", "coordinates": [[75.93,';
      final geom = RouteGeometry.fromBackend(malformedJson);
      expect(geom.status, RouteGeometryStatus.invalid);
      expect(geom.isInvalid, isTrue);
      expect(geom.errorMessage, contains('Malformed JSON'));
    });

    test(
      'correctly parses raw list of coordinate pairs [longitude, latitude]',
      () {
        final rawCoords = [
          [75.937194, 11.323361],
          [75.934083, 11.321333],
        ];

        final geom = RouteGeometry.fromBackend(rawCoords, source: 'coords');
        expect(geom.status, RouteGeometryStatus.available);
        expect(geom.path[0].latitude, 11.323361);
        expect(geom.path[0].longitude, 75.937194);
      },
    );

    test('serializes and deserializes to JSON predictably', () {
      const geom = RouteGeometry.available(
        path: [
          GeoPoint(latitude: 11.32, longitude: 75.93),
          GeoPoint(latitude: 11.33, longitude: 75.94),
        ],
        source: 'gps_trace',
        isVerified: true,
      );

      final json = geom.toJson();
      expect(json['status'], 'available');
      expect(json['source'], 'gps_trace');
      expect(json['is_verified'], isTrue);
      expect((json['path'] as List), hasLength(2));
    });
  });
}
