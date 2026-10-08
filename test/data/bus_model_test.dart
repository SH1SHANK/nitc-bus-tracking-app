import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_position.dart';

void main() {
  group('Bus Model', () {
    test('serializes and deserializes from JSON', () {
      final now = DateTime.now();
      final bus = Bus(
        id: 'bus-1',
        numberPlate: 'KL-11-NITC-101',
        name: 'Campus Express 1',
        routeId: 'route-1',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.3216, longitude: 75.9337),
          heading: 90.0,
          speedKmH: 25.0,
          timestamp: now,
        ),
        occupancy: 'Seats Available',
        lastUpdated: now,
      );

      final json = bus.toJson();
      final fromJson = Bus.fromJson(json);

      expect(fromJson.id, equals('bus-1'));
      expect(fromJson.numberPlate, equals('KL-11-NITC-101'));
      expect(fromJson.status, equals(BusStatus.live));
      expect(fromJson.isLive, isTrue);
      expect(fromJson.position.point.latitude, equals(11.3216));
    });

    test('parses fallback status as offline', () {
      final bus = Bus.fromJson({
        'id': 'bus-offline',
        'number_plate': 'KL-11-NITC-999',
        'name': 'Standby Bus',
        'status': 'unknown_status',
        'latitude': 11.32,
        'longitude': 75.93,
      });

      expect(bus.status, equals(BusStatus.offline));
      expect(bus.isLive, isFalse);
    });
  });
}
