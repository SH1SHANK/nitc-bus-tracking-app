import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus_telemetry.dart';

void main() {
  test('interpolates coordinates and wraps heading over the shortest arc', () {
    const from = GeoPoint(latitude: 11.32, longitude: 75.93);
    const to = GeoPoint(latitude: 11.321, longitude: 75.932);

    expect(BusTelemetry.interpolatePoint(from, to, 0.5).latitude, 11.3205);
    expect(BusTelemetry.interpolateHeading(359, 1, 0.5), 0);
  });

  test('clamps cadence and snaps invalid or implausible telemetry safely', () {
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
    expect(
      BusTelemetry.isValidPoint(
        const GeoPoint(latitude: 11.32, longitude: 75.93),
      ),
      isTrue,
    );
  });

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

  test('orders packets by epoch before sequence and snaps on a new epoch', () {
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
  });
}
