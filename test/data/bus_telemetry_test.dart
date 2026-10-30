import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_position.dart';
import 'package:tracklet/data/transit/bus_telemetry.dart';

void main() {
  group('BusTelemetry Coordinate and Spatial Validation', () {
    test(
      'interpolates coordinates and wraps heading over the shortest arc',
      () {
        const from = GeoPoint(latitude: 11.32, longitude: 75.93);
        const to = GeoPoint(latitude: 11.321, longitude: 75.932);

        expect(BusTelemetry.interpolatePoint(from, to, 0.5).latitude, 11.3205);
        expect(BusTelemetry.interpolateHeading(359, 1, 0.5), 0);
        expect(
          BusTelemetry.interpolatePoint(
            const GeoPoint(latitude: 10, longitude: 179.9),
            const GeoPoint(latitude: 10, longitude: -179.9),
            0.5,
          ).longitude,
          closeTo(-180, 1e-8),
        );
      },
    );

    test(
      'rejects Null Island (0,0) and near-zero uncalibrated coordinates',
      () {
        expect(
          BusTelemetry.isValidPoint(const GeoPoint(latitude: 0, longitude: 0)),
          isFalse,
        );
        expect(
          BusTelemetry.isValidPoint(
            const GeoPoint(latitude: 0.00001, longitude: 0.00001),
          ),
          isFalse,
        );
        expect(GeoPoint.isValidCoordinates(0, 0), isFalse);
        expect(const GeoPoint(latitude: 0, longitude: 0).isValid, isFalse);
      },
    );

    test(
      'GeoPoint.isValidCoordinates rejects out of bounds, non-finite, and NaN',
      () {
        expect(GeoPoint.isValidCoordinates(91, 75.93), isFalse);
        expect(GeoPoint.isValidCoordinates(-91, 75.93), isFalse);
        expect(GeoPoint.isValidCoordinates(11.32, 181), isFalse);
        expect(GeoPoint.isValidCoordinates(11.32, -181), isFalse);
        expect(GeoPoint.isValidCoordinates(double.nan, 75.93), isFalse);
        expect(GeoPoint.isValidCoordinates(11.32, double.infinity), isFalse);
        expect(
          GeoPoint.isValidCoordinates(11.32, double.negativeInfinity),
          isFalse,
        );
      },
    );

    test('accepts valid geographic coordinates within NIT Calicut region', () {
      expect(
        BusTelemetry.isValidPoint(
          const GeoPoint(latitude: 11.3216, longitude: 75.9337),
        ),
        isTrue,
      );
      expect(GeoPoint.isValidCoordinates(11.3216, 75.9337), isTrue);
    });

    test(
      'GeoPoint.tryParse safely handles null, invalid, and Null Island JSON',
      () {
        expect(GeoPoint.tryParse(null), isNull);
        expect(GeoPoint.tryParse({}), isNull);
        expect(GeoPoint.tryParse({'latitude': 0, 'longitude': 0}), isNull);
        expect(
          GeoPoint.tryParse({'lat': 11.3216, 'lng': 75.9337}),
          const GeoPoint(latitude: 11.3216, longitude: 75.9337),
        );
      },
    );

    test(
      'BusPosition.fromJson handles missing or invalid coords gracefully',
      () {
        final defaultPos = BusPosition.fromJson({});
        expect(defaultPos.isValid, isFalse);

        final validPos = BusPosition.fromJson({
          'latitude': 11.3216,
          'longitude': 75.9337,
          'speed_kmh': 20.0,
        });
        expect(validPos.isValid, isTrue);
        expect(validPos.speedKmH, 20.0);
      },
    );

    test(
      'Bus.hasValidLocation and trackingState reflect GPS coordinates state',
      () {
        final now = DateTime.now();
        final validBus = Bus(
          id: 'bus-1',
          name: 'Campus Bus 1',
          numberPlate: 'KL 11 BH 0001',
          status: BusStatus.live,
          position: BusPosition(
            point: const GeoPoint(latitude: 11.32, longitude: 75.93),
            speedKmH: 15,
            timestamp: now,
          ),
          lastUpdated: now,
        );
        expect(validBus.hasValidLocation, isTrue);
        expect(validBus.trackingState(), BusTrackingState.liveMoving);

        final stationaryBus = Bus(
          id: 'bus-2',
          name: 'Campus Bus 2',
          numberPlate: 'KL 11 BH 0002',
          status: BusStatus.live,
          position: BusPosition(
            point: const GeoPoint(latitude: 11.32, longitude: 75.93),
            speedKmH: 0.5,
            timestamp: now,
          ),
          lastUpdated: now,
        );
        expect(stationaryBus.trackingState(), BusTrackingState.liveStationary);

        final noLocationBus = Bus(
          id: 'bus-3',
          name: 'Campus Bus 3',
          numberPlate: 'KL 11 BH 0003',
          status: BusStatus.live,
          position: BusPosition(
            point: const GeoPoint(latitude: 0, longitude: 0),
            timestamp: now,
          ),
          lastUpdated: now,
        );
        expect(noLocationBus.hasValidLocation, isFalse);
        expect(noLocationBus.trackingState(), BusTrackingState.noLocation);
      },
    );
  });

  group('BusTelemetry Packet Acceptance and Sequence Advancement', () {
    test(
      'clamps cadence and snaps invalid or implausible telemetry safely',
      () {
        expect(
          BusTelemetry.animationDuration(const Duration(milliseconds: 100)),
          const Duration(milliseconds: 500),
        );
        expect(
          BusTelemetry.animationDuration(const Duration(seconds: 8)),
          const Duration(seconds: 3),
        );
        expect(
          BusTelemetry.isLargeJump(
            const GeoPoint(latitude: 11.32, longitude: 75.93),
            const GeoPoint(latitude: 11.324, longitude: 75.93),
          ),
          isTrue,
        );
      },
    );

    test(
      'orders packets by timestamp and sequence, allowing a reset to snap',
      () {
        final timestamp = DateTime.utc(2026, 10, 14);
        bool accepts(int sequence, DateTime time) =>
            BusTelemetry.shouldAcceptPacket(
              previousSequence: 8,
              previousTimestamp: timestamp,
              incomingSequence: sequence,
              incomingTimestamp: time,
            );

        expect(accepts(8, timestamp.add(const Duration(seconds: 1))), isFalse);
        expect(
          accepts(9, timestamp.subtract(const Duration(seconds: 1))),
          isFalse,
        );
        expect(accepts(9, timestamp), isTrue);
        expect(BusTelemetry.isSequenceReset(8, 1), isTrue);
      },
    );

    test(
      'rejects duplicate and out-of-order sequence packets in same epoch',
      () {
        final baseTime = DateTime.utc(2026, 10, 14, 12, 0, 0);

        // Initial packet without previous sequence
        expect(
          BusTelemetry.shouldAcceptPacket(
            previousSequence: null,
            previousTimestamp: baseTime,
            incomingSequence: 10,
            incomingTimestamp: baseTime,
          ),
          isTrue,
        );

        // Duplicate sequence in same epoch rejected
        expect(
          BusTelemetry.shouldAcceptPacket(
            previousEpoch: 1,
            previousSequence: 10,
            previousTimestamp: baseTime,
            incomingEpoch: 1,
            incomingSequence: 10,
            incomingTimestamp: baseTime.add(const Duration(seconds: 2)),
          ),
          isFalse,
        );

        // Older sequence in same epoch rejected even with newer timestamp
        expect(
          BusTelemetry.shouldAcceptPacket(
            previousEpoch: 1,
            previousSequence: 10,
            previousTimestamp: baseTime,
            incomingEpoch: 1,
            incomingSequence: 9,
            incomingTimestamp: baseTime.add(const Duration(seconds: 2)),
          ),
          isFalse,
        );

        // Higher sequence with valid timestamp accepted
        expect(
          BusTelemetry.shouldAcceptPacket(
            previousEpoch: 1,
            previousSequence: 10,
            previousTimestamp: baseTime,
            incomingEpoch: 1,
            incomingSequence: 11,
            incomingTimestamp: baseTime.add(const Duration(seconds: 2)),
          ),
          isTrue,
        );
      },
    );

    test(
      'orders packets by epoch before sequence and snaps on a new epoch',
      () {
        final oldTime = DateTime.utc(2026, 10, 14, 10);
        expect(
          BusTelemetry.shouldAcceptPacket(
            previousEpoch: 2,
            previousSequence: 100,
            previousTimestamp: oldTime,
            incomingEpoch: 3,
            incomingSequence: 1,
            incomingTimestamp: oldTime.subtract(const Duration(seconds: 1)),
          ),
          isTrue,
        );
        expect(
          BusTelemetry.shouldAcceptPacket(
            previousEpoch: 3,
            previousSequence: 1,
            previousTimestamp: oldTime,
            incomingEpoch: 2,
            incomingSequence: 200,
            incomingTimestamp: oldTime.add(const Duration(seconds: 1)),
          ),
          isFalse,
        );
        expect(BusTelemetry.isEpochReset(2, 3), isTrue);
      },
    );

    test(
      'rejects duplicate timestamp packet when sequence number is null or unchanged',
      () {
        final baseTime = DateTime.utc(2026, 10, 14, 12, 0, 0);
        // Duplicate timestamp with null sequences rejected
        expect(
          BusTelemetry.shouldAcceptPacket(
            previousSequence: null,
            previousTimestamp: baseTime,
            incomingSequence: null,
            incomingTimestamp: baseTime,
          ),
          isFalse,
        );
        // Duplicate timestamp with identical sequences rejected
        expect(
          BusTelemetry.shouldAcceptPacket(
            previousSequence: 5,
            previousTimestamp: baseTime,
            incomingSequence: 5,
            incomingTimestamp: baseTime,
          ),
          isFalse,
        );
        // Strictly advancing timestamp accepted
        expect(
          BusTelemetry.shouldAcceptPacket(
            previousSequence: null,
            previousTimestamp: baseTime,
            incomingSequence: null,
            incomingTimestamp: baseTime.add(const Duration(milliseconds: 100)),
          ),
          isTrue,
        );
      },
    );

    test(
      'BusPosition.fromJson defensively parses string numbers and tracks hasHeading/hasAccuracy',
      () {
        final pos = BusPosition.fromJson({
          'latitude': '11.3216',
          'longitude': '75.9337',
          'speed_kmh': '25.5',
          'heading': '180.0',
          'accuracy_meters': '4.5',
          'sequence_number': '12',
          'epoch': '2',
        });
        expect(pos.isValid, isTrue);
        expect(pos.point.latitude, 11.3216);
        expect(pos.point.longitude, 75.9337);
        expect(pos.speedKmH, 25.5);
        expect(pos.heading, 180.0);
        expect(pos.hasHeading, isTrue);
        expect(pos.accuracyMeters, 4.5);
        expect(pos.hasAccuracy, isTrue);
        expect(pos.sequenceNumber, 12);
        expect(pos.epoch, 2);

        final noHeadingPos = BusPosition.fromJson({
          'latitude': 11.3216,
          'longitude': 75.9337,
        });
        expect(noHeadingPos.hasHeading, isFalse);
        expect(noHeadingPos.hasAccuracy, isFalse);
        expect(noHeadingPos.heading, 0.0);
        expect(noHeadingPos.accuracyMeters, 0.0);
      },
    );
  });
}
