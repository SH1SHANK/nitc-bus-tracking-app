import 'dart:math' as math;

import '../../core/geo/geo_point.dart';

/// Small, deterministic rules shared by the map's telemetry marker layer.
abstract final class BusTelemetry {
  static const Duration staleAfter = Duration(seconds: 90);

  static bool isValidPoint(GeoPoint point) =>
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude >= -90 &&
      point.latitude <= 90 &&
      point.longitude >= -180 &&
      point.longitude <= 180;

  static double headingDelta(double from, double to) =>
      ((to - from + 540) % 360) - 180;

  static double interpolateHeading(double from, double to, double t) =>
      (from + headingDelta(from, to) * t + 360) % 360;

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
    if (previousSequence == null || incomingSequence == null) {
      return incomingTimestamp.isAfter(previousTimestamp);
    }
    return incomingSequence != previousSequence;
  }

  static bool isSequenceReset(int? previousSequence, int? incomingSequence) =>
      previousSequence != null &&
      incomingSequence != null &&
      incomingSequence < previousSequence;

  static bool isEpochReset(int? previousEpoch, int? incomingEpoch) =>
      incomingEpoch != null &&
      (previousEpoch == null || incomingEpoch > previousEpoch);

  static GeoPoint interpolatePoint(GeoPoint from, GeoPoint to, double t) =>
      GeoPoint(
        latitude: from.latitude + (to.latitude - from.latitude) * t,
        longitude: from.longitude + (to.longitude - from.longitude) * t,
      );

  static Duration animationDuration(Duration cadence) =>
      Duration(milliseconds: cadence.inMilliseconds.clamp(500, 3000).toInt());

  static bool isLargeJump(GeoPoint from, GeoPoint to) {
    return distanceMeters(from, to) > 300;
  }

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
