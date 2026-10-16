import 'dart:math' as math;

import '../../core/geo/geo_point.dart';
import 'bus_stop_progress.dart';
import 'bus.dart';
import 'bus_telemetry.dart';
import 'route_stop_occurrence.dart';

enum BusEtaStatus {
  valid,
  staleTelemetry,
  offRoute,
  unresolvedStopProgress,
  dwellingAtStop,
  stationary,
  invalidGeometry,
  invalidCoordinate,
  stopProjectionUnavailable,
  ambiguousProjection,
  invalidSpeed,
}

class BusEtaResult {
  const BusEtaResult._(
    this.status, {
    this.minutes,
    this.distanceMeters,
    this.busProgressMeters,
    this.smoothedSpeedMetersPerSecond,
    this.stopsAway,
    this.targetStopName,
  });

  const BusEtaResult.unavailable(BusEtaStatus reason) : this._(reason);

  const BusEtaResult.valid({
    required int minutes,
    required double distanceMeters,
    required double busProgressMeters,
    required double smoothedSpeedMetersPerSecond,
    int? stopsAway,
    String? targetStopName,
  }) : this._(
         BusEtaStatus.valid,
         minutes: minutes,
         distanceMeters: distanceMeters,
         busProgressMeters: busProgressMeters,
         smoothedSpeedMetersPerSecond: smoothedSpeedMetersPerSecond,
         stopsAway: stopsAway,
         targetStopName: targetStopName,
       );

  final BusEtaStatus status;
  final int? minutes;
  final double? distanceMeters;
  final double? busProgressMeters;
  final double? smoothedSpeedMetersPerSecond;
  final int? stopsAway;
  final String? targetStopName;

  bool get isValid => status == BusEtaStatus.valid;
  String get displayValue => isValid ? '$minutes min' : 'Unavailable';

  BusEtaResult copyWith({
    BusEtaStatus? status,
    int? minutes,
    double? distanceMeters,
    double? busProgressMeters,
    double? smoothedSpeedMetersPerSecond,
    int? stopsAway,
    String? targetStopName,
  }) {
    return BusEtaResult._(
      status ?? this.status,
      minutes: minutes ?? this.minutes,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      busProgressMeters: busProgressMeters ?? this.busProgressMeters,
      smoothedSpeedMetersPerSecond:
          smoothedSpeedMetersPerSecond ?? this.smoothedSpeedMetersPerSecond,
      stopsAway: stopsAway ?? this.stopsAway,
      targetStopName: targetStopName ?? this.targetStopName,
    );
  }
}

class RouteProjection {
  const RouteProjection({
    required this.alongMeters,
    required this.offsetMeters,
    required this.segmentIndex,
    required this.bearing,
  });

  final double alongMeters;
  final double offsetMeters;
  final int segmentIndex;
  final double bearing;
}

/// Projects in a local tangent plane per segment, then measures route length
/// with haversine arcs. Route coordinates remain in canonical sequence.
abstract final class RouteProgressProjector {
  static const double maxOffRouteMeters = 150;
  static const double _earthRadiusMeters = 6371000;

  static List<RouteProjection> candidates(
    List<GeoPoint> route,
    GeoPoint point,
  ) {
    if (route.length < 2 ||
        !BusTelemetry.isValidPoint(point) ||
        route.any((p) => !BusTelemetry.isValidPoint(p))) {
      return const [];
    }
    final lengths = <double>[];
    for (var i = 0; i < route.length - 1; i++) {
      lengths.add(route[i].distanceToMeters(route[i + 1]));
    }
    if (lengths.every((length) => length < 0.01)) {
      return const [];
    }
    final cumulative = List<double>.filled(route.length, 0);
    for (var i = 0; i < lengths.length; i++) {
      cumulative[i + 1] = cumulative[i] + lengths[i];
    }
    final results = <RouteProjection>[];
    for (var i = 0; i < lengths.length; i++) {
      final length = lengths[i];
      if (length < 0.01) continue;
      final a = route[i];
      final b = route[i + 1];
      final lat0 =
          (a.latitude + b.latitude + point.latitude) / 3 * math.pi / 180;
      final cosLat = math.cos(lat0);
      double x(GeoPoint p) =>
          (p.longitude - a.longitude) *
          math.pi /
          180 *
          _earthRadiusMeters *
          cosLat;
      double y(GeoPoint p) =>
          (p.latitude - a.latitude) * math.pi / 180 * _earthRadiusMeters;
      final dx = x(b), dy = y(b);
      final denominator = dx * dx + dy * dy;
      if (denominator <= 1e-8) continue;
      final t = ((x(point) * dx + y(point) * dy) / denominator).clamp(0.0, 1.0);
      final px = t * dx, py = t * dy;
      final offset = math.sqrt(
        math.pow(x(point) - px, 2) + math.pow(y(point) - py, 2),
      );
      results.add(
        RouteProjection(
          alongMeters: cumulative[i] + t * length,
          offsetMeters: offset,
          segmentIndex: i,
          bearing: a.bearingTo(b),
        ),
      );
    }
    return results;
  }

  static double? forwardDistance({
    required RouteProjection bus,
    required RouteProjection stop,
    required double routeLengthMeters,
    required bool isLoop,
    required bool reverse,
  }) {
    final delta =
        reverse
            ? bus.alongMeters - stop.alongMeters
            : stop.alongMeters - bus.alongMeters;
    if (delta >= 0) return delta;
    if (isLoop) return routeLengthMeters + delta;
    return null;
  }
}

abstract final class BusEtaCalculator {
  // Existing stale threshold is 90 seconds; stationary means below 2 km/h.
  // A 3.5 m/s fallback is allowed only 20-120 s after a departure event on a
  // live trip; arrived/due/offline buses never use it. Dwell is 120 seconds.
  static const double stationarySpeedMetersPerSecond = 2 / 3.6;
  static const Duration stationaryDuration = Duration(seconds: 120);
  static const Duration transientPauseMin = Duration(seconds: 20);
  static const Duration transientPauseMax = Duration(seconds: 120);
  static const double transientFallbackMetersPerSecond = 3.5;
  static const int minMinutes = 1;
  static const int maxMinutes = 45;

  static BusEtaResult calculate({
    required Bus bus,
    required List<GeoPoint> route,
    required BusStopProgress? progress,
    required DateTime Function() clock,
    double? previousProgressMeters,
    double? previousSpeedMetersPerSecond,
  }) {
    final now = clock();
    final age = now.difference(bus.position.timestamp);
    if (bus.isStale ||
        bus.status == BusStatus.offline ||
        age.isNegative ||
        age > BusTelemetry.staleAfter) {
      return const BusEtaResult.unavailable(BusEtaStatus.staleTelemetry);
    }
    if (route.length < 2) {
      return const BusEtaResult.unavailable(BusEtaStatus.invalidGeometry);
    }
    if (!BusTelemetry.isValidPoint(bus.position.point) ||
        route.any((point) => !BusTelemetry.isValidPoint(point))) {
      return const BusEtaResult.unavailable(BusEtaStatus.invalidCoordinate);
    }
    if (progress?.nextStop?.stop?.location == null) {
      return const BusEtaResult.unavailable(
        BusEtaStatus.unresolvedStopProgress,
      );
    }
    if (progress!.currentStopId != null) {
      final arrivedAt = progress.lastEventAt;
      if (arrivedAt != null && now.difference(arrivedAt) < stationaryDuration) {
        return const BusEtaResult.unavailable(BusEtaStatus.dwellingAtStop);
      }
      return const BusEtaResult.unavailable(BusEtaStatus.stationary);
    }
    if (!bus.position.hasSpeed) {
      return const BusEtaResult.unavailable(BusEtaStatus.invalidSpeed);
    }
    // Two-sample EMA (alpha 0.5) dampens single-tick speed noise.
    final rawSpeed = bus.position.speedMetersPerSecond;
    final speed =
        previousSpeedMetersPerSecond != null &&
                previousSpeedMetersPerSecond.isFinite &&
                previousSpeedMetersPerSecond >= 0 &&
                rawSpeed.isFinite &&
                rawSpeed >= 0
            ? (previousSpeedMetersPerSecond + rawSpeed) / 2
            : rawSpeed;
    var effectiveSpeed = speed;
    if (!speed.isFinite || speed < 0) {
      return const BusEtaResult.unavailable(BusEtaStatus.invalidSpeed);
    }
    if (speed < stationarySpeedMetersPerSecond) {
      final sinceEvent =
          progress.lastEventAt == null
              ? null
              : now.difference(progress.lastEventAt!);
      final transient =
          bus.status == BusStatus.live &&
          progress.lastEventType == 'departed' &&
          sinceEvent != null &&
          sinceEvent >= transientPauseMin &&
          sinceEvent <= transientPauseMax;
      if (!transient) {
        return const BusEtaResult.unavailable(BusEtaStatus.stationary);
      }
      effectiveSpeed = transientFallbackMetersPerSecond;
    }
    final routeLengths = <double>[];
    for (var i = 0; i < route.length - 1; i++) {
      routeLengths.add(route[i].distanceToMeters(route[i + 1]));
    }
    final routeLength = routeLengths.fold<double>(0, (sum, d) => sum + d);
    if (routeLength <= 0.01) {
      return const BusEtaResult.unavailable(BusEtaStatus.invalidGeometry);
    }
    var busCandidates =
        RouteProgressProjector.candidates(route, bus.position.point)
            .where(
              (projection) =>
                  projection.offsetMeters <=
                  RouteProgressProjector.maxOffRouteMeters,
            )
            .toList();
    if (busCandidates.isEmpty) {
      return const BusEtaResult.unavailable(BusEtaStatus.offRoute);
    }
    var stopCandidates = RouteProgressProjector.candidates(
      route,
      progress.nextStop!.stop!.location,
    );
    final knownStopDistance = progress.nextStop!.distanceFromStart;
    final isClosedPath = route.first.distanceToMeters(route.last) <= 10;
    final isOutAndBack =
        progress.isOutAndBack || (!progress.isLoopRoute && isClosedPath);
    final isLoop = (progress.isLoopRoute || isClosedPath) && !isOutAndBack;
    final isLoopSeamStop =
        isLoop &&
        knownStopDistance != null &&
        knownStopDistance <= 50 &&
        progress.nextStop!.stop!.location.distanceToMeters(route.first) <= 50;

    final isReturnLeg =
        progress.direction.toLowerCase() == 'reverse' ||
        progress.direction.toLowerCase() == 'backward';

    if (isOutAndBack) {
      final half = routeLength / 2;
      final filteredBus =
          isReturnLeg
              ? busCandidates.where((c) => c.alongMeters >= half - 100).toList()
              : busCandidates
                  .where((c) => c.alongMeters <= half + 100)
                  .toList();
      if (filteredBus.isNotEmpty) {
        busCandidates = filteredBus;
      }
      final filteredStop =
          isReturnLeg
              ? stopCandidates
                  .where((c) => c.alongMeters >= half - 100)
                  .toList()
              : stopCandidates
                  .where((c) => c.alongMeters <= half + 100)
                  .toList();
      if (filteredStop.isNotEmpty) {
        stopCandidates = filteredStop;
      }
    }

    if (knownStopDistance != null && knownStopDistance >= 0) {
      stopCandidates =
          stopCandidates
              .where(
                (candidate) =>
                    (candidate.alongMeters - knownStopDistance).abs() <= 50 ||
                    (isLoopSeamStop &&
                        (candidate.alongMeters <= 50 ||
                            routeLength - candidate.alongMeters <= 50)),
              )
              .toList();
    } else {
      stopCandidates =
          stopCandidates
              .where(
                (candidate) =>
                    candidate.offsetMeters <=
                    RouteProgressProjector.maxOffRouteMeters,
              )
              .toList();
    }
    if (stopCandidates.isEmpty) {
      return const BusEtaResult.unavailable(
        BusEtaStatus.stopProjectionUnavailable,
      );
    }
    final reverse = !isOutAndBack && isReturnLeg;
    final pairs =
        <
          ({
            double distance,
            RouteProjection bus,
            RouteProjection stop,
            double score,
          })
        >[];
    for (final busProjection in busCandidates) {
      for (final stopProjection in stopCandidates) {
        final distance = RouteProgressProjector.forwardDistance(
          bus: busProjection,
          stop: stopProjection,
          routeLengthMeters: routeLength,
          isLoop: isLoop,
          reverse: reverse,
        );
        if (distance == null || distance < 0.5) continue;
        var progressionPenalty = 0.0;
        if (previousProgressMeters != null) {
          var forwardDelta =
              reverse
                  ? previousProgressMeters - busProjection.alongMeters
                  : busProjection.alongMeters - previousProgressMeters;
          if (forwardDelta < -10 && isLoop) forwardDelta += routeLength;
          progressionPenalty =
              forwardDelta < -10
                  ? 1000 + forwardDelta.abs()
                  : forwardDelta.abs();
        }
        final heading = bus.position.heading;
        final headingPenalty =
            speed < stationarySpeedMetersPerSecond ||
                    !heading.isFinite ||
                    heading < 0 ||
                    heading >= 360
                ? 0.0
                : BusTelemetry.headingDelta(
                      (busProjection.bearing + (reverse ? 180 : 0)) % 360,
                      heading,
                    ).abs() *
                    0.5;
        pairs.add((
          distance: distance,
          bus: busProjection,
          stop: stopProjection,
          score:
              busProjection.offsetMeters +
              stopProjection.offsetMeters +
              progressionPenalty +
              headingPenalty,
        ));
      }
    }
    if (pairs.isEmpty) {
      return const BusEtaResult.unavailable(BusEtaStatus.ambiguousProjection);
    }
    pairs.sort(
      (a, b) =>
          isLoopSeamStop
              ? a.distance.compareTo(b.distance)
              : a.score.compareTo(b.score),
    );
    if (!isLoopSeamStop &&
        pairs.length > 1 &&
        pairs[1].score - pairs[0].score < 5 &&
        (pairs[1].distance - pairs[0].distance).abs() > 20) {
      return const BusEtaResult.unavailable(BusEtaStatus.ambiguousProjection);
    }
    final rawMinutes = pairs.first.distance / effectiveSpeed / 60;
    final roundedMinutes = rawMinutes.round().clamp(minMinutes, maxMinutes);
    return BusEtaResult.valid(
      minutes: roundedMinutes,
      distanceMeters: pairs.first.distance,
      busProgressMeters: pairs.first.bus.alongMeters,
      smoothedSpeedMetersPerSecond: speed,
      stopsAway: 1,
      targetStopName: progress.nextStop?.stop?.name,
    );
  }

  /// Calculates ETA for any target stop along the bus's active route journey.
  /// If [targetStopId] is the immediate next stop, returns direct map-matched ETA.
  /// If [targetStopId] is further along [upcomingStops], incorporates the inter-stop
  /// journey duration and stops-away count.
  static BusEtaResult calculateForStop({
    required Bus bus,
    required List<GeoPoint> route,
    required BusStopProgress? progress,
    required String targetStopId,
    required List<RouteStopOccurrence> stopOccurrences,
    DateTime Function()? clock,
    double? previousProgressMeters,
    double? previousSpeedMetersPerSecond,
  }) {
    if (progress == null || progress.nextStop == null) {
      return const BusEtaResult.unavailable(
        BusEtaStatus.unresolvedStopProgress,
      );
    }

    // 1. Calculate base ETA to the bus's immediate next stop
    final baseEta = calculate(
      bus: bus,
      route: route,
      progress: progress,
      clock: clock ?? DateTime.now,
      previousProgressMeters: previousProgressMeters,
      previousSpeedMetersPerSecond: previousSpeedMetersPerSecond,
    );

    // If base ETA is unavailable, we cannot project further stops
    if (!baseEta.isValid) {
      return baseEta;
    }

    final nextStop = progress.nextStop!;

    // Case A: Target stop IS the immediate next stop
    if (nextStop.stopId == targetStopId) {
      return baseEta.copyWith(
        stopsAway: 1,
        targetStopName: nextStop.stop?.name,
      );
    }

    // Case B: Target stop is in the upcoming stops sequence
    final upcomingIndex = progress.upcomingStops.indexWhere(
      (occurrence) => occurrence.stopId == targetStopId,
    );

    if (upcomingIndex < 0) {
      // The bus has either already passed this stop or is on the opposing leg
      return const BusEtaResult.unavailable(
        BusEtaStatus.unresolvedStopProgress,
      );
    }

    final targetOccurrence = progress.upcomingStops[upcomingIndex];
    final stopsAway =
        upcomingIndex +
        1; // 1-based count since upcomingStops starts at nextStop

    // Calculate additional distance and duration between nextStop and targetStop
    double additionalDistance = 0.0;
    int additionalSeconds = 0;

    // Use distanceFromStart or pairwise distance
    if (nextStop.distanceFromStart != null &&
        targetOccurrence.distanceFromStart != null &&
        targetOccurrence.distanceFromStart! >= nextStop.distanceFromStart!) {
      additionalDistance =
          targetOccurrence.distanceFromStart! - nextStop.distanceFromStart!;
    } else {
      // Approximate from haversine distance along intermediate stops
      var prevLoc = nextStop.stop?.location;
      for (var i = 0; i <= upcomingIndex; i++) {
        final loc = progress.upcomingStops[i].stop?.location;
        if (prevLoc != null && loc != null) {
          additionalDistance += prevLoc.distanceToMeters(loc);
        }
        prevLoc = loc;
      }
    }

    // Estimated duration from timetable metadata or average campus transit speed (18 km/h = 5 m/s)
    if (nextStop.estimatedDurationSec != null &&
        targetOccurrence.estimatedDurationSec != null &&
        targetOccurrence.estimatedDurationSec! >=
            nextStop.estimatedDurationSec!) {
      additionalSeconds =
          targetOccurrence.estimatedDurationSec! -
          nextStop.estimatedDurationSec!;
    } else {
      final speed = math.max(4.0, baseEta.smoothedSpeedMetersPerSecond ?? 5.0);
      additionalSeconds = (additionalDistance / speed).round();
      // Add dwell time per intermediate stop (~30 seconds each)
      additionalSeconds += upcomingIndex * 30;
    }

    final additionalMinutes = (additionalSeconds / 60).round();
    final totalMinutes = (baseEta.minutes! + additionalMinutes).clamp(
      minMinutes,
      maxMinutes,
    );

    return BusEtaResult.valid(
      minutes: totalMinutes,
      distanceMeters: (baseEta.distanceMeters ?? 0) + additionalDistance,
      busProgressMeters: baseEta.busProgressMeters ?? 0,
      smoothedSpeedMetersPerSecond: baseEta.smoothedSpeedMetersPerSecond ?? 5.0,
      stopsAway: stopsAway,
      targetStopName: targetOccurrence.stop?.name,
    );
  }
}
