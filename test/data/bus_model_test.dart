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
          accuracyMeters: 3.5,
          sequenceNumber: 42,
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
      expect(fromJson.position.accuracyMeters, equals(3.5));
      expect(fromJson.position.sequenceNumber, equals(42));
      expect(fromJson.position.timestamp, equals(now));
    });

    test('parses live-position RPC fields without assuming table columns', () {
      final bus = Bus.fromJson({
        'bus_id': 'bus-2',
        'bus_number': 'NITC-02',
        'display_name': 'Campus Shuttle',
        'route_id': 'route-1',
        'status': 'moving',
        'latitude': 11.3216,
        'longitude': 75.9337,
        'speed': 18.5,
        'heading': 120,
        'last_seen': '2026-10-10T10:00:00Z',
        'recorded_at': '2026-10-10T09:59:58Z',
      });

      expect(bus.id, 'bus-2');
      expect(bus.numberPlate, 'NITC-02');
      expect(bus.name, 'Campus Shuttle');
      expect(bus.status, BusStatus.live);
      expect(bus.position.speedKmH, 18.5);
      expect(bus.position.timestamp, DateTime.parse('2026-10-10T09:59:58Z'));
      expect(bus.lastUpdated, DateTime.parse('2026-10-10T10:00:00Z'));
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
