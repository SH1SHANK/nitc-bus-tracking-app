import 'dart:math' as math;

import '../../core/geo/geo_point.dart';

/// Small, deterministic rules and thresholds shared across transit tracking,
/// telemetry ingestion, and map presentation.
abstract final class BusTelemetry {
  /// Telemetry freshness threshold: records older than this are considered stale.
  static const Duration staleAfter = Duration(seconds: 90);

  /// Standard polling interval for active bus positions.
  static const Duration pollingInterval = Duration(seconds: 15);

  /// Duration for caching active trip stop events.
  static const Duration stopEventCacheDuration = Duration(seconds: 10);

  /// Maximum acceptable gap between telemetry observations before snapping instead of interpolating.
  static const Duration maxInterpolationGap = Duration(seconds: 30);

  /// Minimum animation duration for marker movement (smoothing jitter).
  static const Duration minAnimationCadence = Duration(milliseconds: 500);

  /// Maximum animation duration for marker movement (avoiding dragging old updates).
  static const Duration maxAnimationCadence = Duration(seconds: 3);

  /// Telemetry clock skew tolerance before flagging as anomalous.
  static const Duration clockSkewTolerance = Duration(seconds: 15);

  /// Maximum distance in meters between consecutive GPS points before treating as an implausible jump.
  static const double largeJumpThresholdMeters = 300.0;

  /// Speed threshold below which a bus is considered stationary (km/h).
  static const double stationarySpeedThresholdKmH = 2.0;

  /// Distance threshold below which stationary GPS jitter is ignored (meters).
  static const double stationaryDistanceThresholdMeters = 8.0;

  /// Dwelling speed threshold near a stop (km/h).
  static const double stopDwellingSpeedThresholdKmH = 12.0;

  /// Distance threshold to a stop to be considered dwelling/at-stop (meters).
  static const double atStopThresholdMeters = 35.0;

  /// Maximum distance from route polyline before considered off-route (meters).
  static const double maxOffRouteMeters = 150.0;

  /// Walking speed in meters per minute (approx 4.8 km/h).
  static const double walkingMetersPerMinute = 80.0;

  /// Campus walking range threshold (meters). Beyond this, user is considered outside campus walking range.
  static const double campusStopWalkingRangeMeters = 3000.0;

  /// Validates whether [point] represents a genuine, finite geographic coordinate.
  /// Rejects non-finite values, coordinates outside [-90, 90] / [-180, 180],
  /// and uninitialized/Null Island coordinates at or near (0, 0).
  static bool isValidPoint(GeoPoint point) {
    if (!point.latitude.isFinite || !point.longitude.isFinite) return false;
    if (point.latitude < -90.0 || point.latitude > 90.0) return false;
    if (point.longitude < -180.0 || point.longitude > 180.0) return false;
    // Reject Null Island (0, 0) and uncalibrated near-zero GPS coordinates
    if (point.latitude.abs() < 1e-4 && point.longitude.abs() < 1e-4) {
      return false;
    }
    return true;
  }

  /// Calculates the shortest angular distance from heading [from] to [to] in degrees (-180..180).
  static double headingDelta(double from, double to) =>
      ((to - from + 540) % 360) - 180;

  /// Interpolates heading smoothly over the shortest arc.
  static double interpolateHeading(double from, double to, double t) =>
      (from + headingDelta(from, to) * t + 360) % 360;

  /// Determines whether an incoming telemetry packet should be accepted over the previous observation.
  ///
  /// Ordering rules:
  /// 1. Epoch takes highest precedence (higher epoch always accepted; lower rejected).
  /// 2. Reject packets whose timestamps are older than the previous accepted observation.
  /// 3. Within the same epoch, packets must have strictly increasing sequence numbers or represent a valid sequence reset.
  /// 4. Duplicate sequences and out-of-order packets are rejected.
  static bool shouldAcceptPacket({
    int? previousEpoch,
    int? incomingEpoch,
    required int? previousSequence,
    required DateTime previousTimestamp,
    required int? incomingSequence,
    required DateTime incomingTimestamp,
  }) {
    if (previousEpoch != null && incomingEpoch != null) {
      if (incomingEpoch < previousEpoch) return false;
      if (incomingEpoch > previousEpoch) return true;
    }

    if (incomingTimestamp.isBefore(previousTimestamp)) return false;

    if (previousSequence != null && incomingSequence != null) {
      if (incomingSequence > previousSequence) return true;
      if (incomingSequence == previousSequence) return false;

      // In the same epoch, sequences are strictly monotonic and cannot decrease.
      if (previousEpoch != null &&
          incomingEpoch != null &&
          incomingEpoch <= previousEpoch) {
        return false;
      }

      // If epochs are omitted, allow sequence reset only on initial sequence (seq == 1)
      // with a strictly advancing timestamp.
      return incomingSequence == 1 &&
          incomingTimestamp.isAfter(previousTimestamp);
    }

    if (previousSequence == null && incomingSequence != null) {
      // Initial observation establishing sequence tracking.
      return !incomingTimestamp.isBefore(previousTimestamp);
    }

    // Sequence numbers absent or unchanged; reject duplicate timestamps.
    return incomingTimestamp.isAfter(previousTimestamp);
  }

  /// True if [incomingSequence] is strictly less than [previousSequence], indicating a reset.
  static bool isSequenceReset(int? previousSequence, int? incomingSequence) =>
      previousSequence != null &&
      incomingSequence != null &&
      incomingSequence < previousSequence;

  /// True if [incomingEpoch] indicates a device restart / reboot session increment.
  static bool isEpochReset(int? previousEpoch, int? incomingEpoch) =>
      incomingEpoch != null &&
      (previousEpoch == null || incomingEpoch > previousEpoch);

  /// Linearly interpolates between geographic points [from] and [to] with fraction [t].
  static GeoPoint interpolatePoint(GeoPoint from, GeoPoint to, double t) =>
      GeoPoint(
        latitude: from.latitude + (to.latitude - from.latitude) * t,
        longitude: from.longitude + (to.longitude - from.longitude) * t,
      );

  /// Calculates smooth animation duration bounded between [minAnimationCadence] and [maxAnimationCadence].
  static Duration animationDuration(Duration cadence) => Duration(
    milliseconds:
        cadence.inMilliseconds
            .clamp(
              minAnimationCadence.inMilliseconds,
              maxAnimationCadence.inMilliseconds,
            )
            .toInt(),
  );

  /// True if spatial distance between [from] and [to] exceeds [largeJumpThresholdMeters].
  static bool isLargeJump(GeoPoint from, GeoPoint to) =>
      distanceMeters(from, to) > largeJumpThresholdMeters;

  /// Great-circle Haversine distance in meters between two coordinates.
  static double distanceMeters(GeoPoint from, GeoPoint to) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLat = lat2 - lat1;
    final dLng = (to.longitude - from.longitude) * math.pi / 180;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final distance =
        earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return distance;
  }
}
