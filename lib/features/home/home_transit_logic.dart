import '../../core/geo/geo_point.dart';
import '../../data/transit/bus_eta.dart';
import '../../data/transit/bus.dart';
import '../../data/transit/bus_route.dart';
import '../../data/transit/scheduled_departure.dart';
import '../../data/transit/stop.dart';

import '../../data/transit/bus_stop_progress.dart';
import '../../data/transit/bus_telemetry.dart';
import '../../core/formatting/transit_formatter.dart';

enum BusStopRelevance {
  atStop,
  confirmedApproaching,
  estimatedApproaching,
  passed,
  routeUncertain,
  incompatibleRoute,
}

class BusArrivalEstimate {
  const BusArrivalEstimate({
    required this.bus,
    required this.route,
    required this.eta,
    this.stopsAway,
    this.nextStopName,
    this.relevance = BusStopRelevance.confirmedApproaching,
    this.currentPositionText,
    this.locationSubtitle,
    this.previousStopName,
    this.progress,
    this.progressDetails,
  });

  final Bus bus;
  final BusRoute route;
  final BusEtaResult eta;
  final int? stopsAway;
  final String? nextStopName;
  final BusStopRelevance relevance;
  final String? currentPositionText;
  final String? locationSubtitle;
  final String? previousStopName;
  final BusStopProgress? progress;
  final BusRouteProgressDetails? progressDetails;

  int? get resolvedStopsAway => stopsAway ?? eta.stopsAway;
  bool get isAtStop => relevance == BusStopRelevance.atStop;
  bool get isConfirmed =>
      relevance == BusStopRelevance.confirmedApproaching ||
      relevance == BusStopRelevance.atStop;
  bool get isEstimated => relevance == BusStopRelevance.estimatedApproaching;
  bool get isRouteUncertain => relevance == BusStopRelevance.routeUncertain;
}

/// Detailed real-time along-route progress of a bus along its stop occurrences.
class BusRouteProgressDetails {
  const BusRouteProgressDetails({
    required this.orderedStops,
    required this.currentStopIndex,
    required this.continuousProgressIndex,
    required this.isAtStop,
    this.currentStop,
    this.previousStop,
    this.nextStop,
    this.distanceToNextStopMeters,
    this.distanceFromPreviousStopMeters,
    this.segmentProgressFraction = 0.0,
  });

  final List<Stop> orderedStops;
  final int currentStopIndex;
  final double continuousProgressIndex;
  final bool isAtStop;
  final Stop? currentStop;
  final Stop? previousStop;
  final Stop? nextStop;
  final double? distanceToNextStopMeters;
  final double? distanceFromPreviousStopMeters;
  final double segmentProgressFraction;
}

Stop? nearestStopTo(GeoPoint point, Iterable<Stop> stops) {
  Stop? nearest;
  var nearestDistance = double.infinity;
  for (final stop in stops) {
    final distance = point.distanceToMeters(stop.location);
    if (distance < nearestDistance) {
      nearest = stop;
      nearestDistance = distance;
    }
  }
  return nearest;
}

const campusStopWalkingRangeMeters = BusTelemetry.campusStopWalkingRangeMeters;

/// Returns a campus stop only when the location is within a useful walking range.
Stop? nearestCampusStopTo(GeoPoint point, Iterable<Stop> stops) {
  final nearest = nearestStopTo(point, stops);
  if (nearest == null) return null;
  if (point.distanceToMeters(nearest.location) >
      BusTelemetry.campusStopWalkingRangeMeters) {
    return null;
  }
  return nearest;
}

/// Rough walking-time estimate from straight-line distance, not a pedestrian route.
int estimateWalkMinutes(double distanceMeters) {
  if (distanceMeters <= 0) return 1;
  return (distanceMeters / BusTelemetry.walkingMetersPerMinute).ceil();
}

/// Returns today's upcoming scheduled route departures that serve [stop].
/// These are route departure times, not predicted arrival times at [stop].
List<ScheduledDeparture> upcomingDeparturesForStop({
  required Stop stop,
  required List<ScheduledDeparture> departures,
  required List<BusRoute> routes,
  required DateTime now,
}) {
  final servingRouteIds =
      routes
          .where((route) => route.stopIds.contains(stop.id))
          .map((route) => route.id)
          .toSet();
  final upcoming =
      departures
          .where(
            (departure) =>
                servingRouteIds.contains(departure.routeId) &&
                !departure.onDate(now).isBefore(now),
          )
          .toList();
  upcoming.sort((a, b) {
    final timeCompare = a.secondsAfterMidnight.compareTo(
      b.secondsAfterMidnight,
    );
    if (timeCompare != 0) return timeCompare;
    return a.sortOrder.compareTo(b.sortOrder);
  });
  return upcoming;
}

double? routeProgressFraction({
  required BusRoute? route,
  required GeoPoint? point,
}) {
  final path = route?.path ?? const <GeoPoint>[];
  if (point == null || path.length < 2) return null;

  var closestIndex = 0;
  var closestDistance = double.infinity;
  for (var index = 0; index < path.length; index++) {
    final distance = point.distanceToMeters(path[index]);
    if (distance < closestDistance) {
      closestDistance = distance;
      closestIndex = index;
    }
  }

  return closestIndex / (path.length - 1);
}

/// Calculates continuous along-route progress of a bus along ordered stop occurrences.
BusRouteProgressDetails calculateRouteProgressDetails({
  required BusRoute? route,
  required Bus bus,
  required List<Stop> allStops,
  BusStopProgress? progress,
}) {
  final stopMap = {for (final s in allStops) s.id: s};
  final occurrences = [...?route?.stopOccurrences]
    ..sort((a, b) => a.sequence.compareTo(b.sequence));

  final orderedStops = <Stop>[];
  if (occurrences.isNotEmpty) {
    for (final occ in occurrences) {
      final resolved = occ.stop ?? stopMap[occ.stopId];
      if (resolved != null) orderedStops.add(resolved);
    }
  } else if (route?.stopIds.isNotEmpty == true) {
    for (final id in route!.stopIds) {
      final resolved = stopMap[id];
      if (resolved != null) orderedStops.add(resolved);
    }
  }

  if (orderedStops.isEmpty) {
    return const BusRouteProgressDetails(
      orderedStops: [],
      currentStopIndex: 0,
      continuousProgressIndex: 0.0,
      isAtStop: false,
    );
  }

  if (orderedStops.length == 1) {
    return BusRouteProgressDetails(
      orderedStops: orderedStops,
      currentStopIndex: 0,
      continuousProgressIndex: 0.0,
      isAtStop: true,
      currentStop: orderedStops.first,
    );
  }

  final n = orderedStops.length;
  final path =
      (route?.path.isNotEmpty == true && route!.path.length >= 2)
          ? route.path
          : orderedStops.map((s) => s.location).toList();

  // 1. Calculate cumulative along-path distances for each stop occurrence
  final stopDistances = <double>[];
  var lastAlong = 0.0;
  for (var i = 0; i < n; i++) {
    if (i == 0) {
      stopDistances.add(0.0);
      continue;
    }
    final stopLoc = orderedStops[i].location;
    final candidates = RouteProgressProjector.candidates(path, stopLoc);
    double? along;
    if (candidates.isNotEmpty) {
      final forward =
          candidates.where((c) => c.alongMeters >= lastAlong - 15.0).toList();
      if (forward.isNotEmpty) {
        forward.sort((a, b) => a.offsetMeters.compareTo(b.offsetMeters));
        along = forward.first.alongMeters;
      } else {
        candidates.sort((a, b) => a.offsetMeters.compareTo(b.offsetMeters));
        along = candidates.first.alongMeters;
      }
    }
    if (along == null || along <= lastAlong) {
      along =
          lastAlong + orderedStops[i - 1].location.distanceToMeters(stopLoc);
    }
    stopDistances.add(along);
    lastAlong = along;
  }

  // 2. Project bus position
  final hasValidPoint = BusTelemetry.isValidPoint(bus.position.point);
  if (!hasValidPoint) {
    int fallbackIdx = -1;
    if (progress?.currentStopId != null) {
      fallbackIdx = orderedStops.indexWhere(
        (s) => s.id == progress!.currentStopId,
      );
    }
    if (fallbackIdx == -1 && progress?.nextStop != null) {
      final nextIdx = orderedStops.indexWhere(
        (s) => s.id == progress!.nextStop!.stopId,
      );
      if (nextIdx > 0) fallbackIdx = nextIdx - 1;
    }
    final cIdx = (fallbackIdx >= 0) ? fallbackIdx : 0;
    return BusRouteProgressDetails(
      orderedStops: orderedStops,
      currentStopIndex: cIdx,
      continuousProgressIndex: cIdx.toDouble(),
      isAtStop: progress?.lastEventType == 'arrived',
      currentStop: orderedStops[cIdx],
      previousStop: cIdx > 0 ? orderedStops[cIdx - 1] : null,
      nextStop: cIdx + 1 < n ? orderedStops[cIdx + 1] : null,
    );
  }

  final busPoint = bus.position.point;
  final busCandidates = RouteProgressProjector.candidates(path, busPoint);
  double busAlong;

  if (busCandidates.isEmpty) {
    final nearest = nearestStopTo(busPoint, orderedStops);
    final idx =
        nearest != null
            ? orderedStops.indexWhere((s) => s.id == nearest.id)
            : 0;
    final cIdx = (idx >= 0) ? idx : 0;
    final distToNearest =
        nearest != null
            ? busPoint.distanceToMeters(nearest.location)
            : double.infinity;
    final isDwelling =
        distToNearest <= BusTelemetry.atStopThresholdMeters &&
        bus.position.speedKmH <= BusTelemetry.stopDwellingSpeedThresholdKmH;
    return BusRouteProgressDetails(
      orderedStops: orderedStops,
      currentStopIndex: cIdx,
      continuousProgressIndex: cIdx.toDouble(),
      isAtStop: isDwelling,
      currentStop: isDwelling ? orderedStops[cIdx] : null,
      previousStop: cIdx > 0 ? orderedStops[cIdx - 1] : null,
      nextStop: cIdx + 1 < n ? orderedStops[cIdx + 1] : null,
    );
  } else {
    var candidates = busCandidates;
    if (progress != null && orderedStops.length >= 5) {
      int? turnaroundIdx;
      for (var i = 1; i < orderedStops.length - 1; i++) {
        if (orderedStops[i - 1].id == orderedStops[i + 1].id) {
          turnaroundIdx = i;
          break;
        }
      }
      if (turnaroundIdx != null && turnaroundIdx < stopDistances.length) {
        final turnaroundDist = stopDistances[turnaroundIdx];
        final legCandidates =
            progress.direction == 'reverse'
                ? busCandidates
                    .where((c) => c.alongMeters >= turnaroundDist - 25.0)
                    .toList()
                : busCandidates
                    .where((c) => c.alongMeters <= turnaroundDist + 25.0)
                    .toList();
        if (legCandidates.isNotEmpty) {
          candidates = legCandidates;
        }
      }
    }

    final heading = bus.position.heading;
    if (heading > 0) {
      final headingMatches =
          candidates.where((c) {
            final diff = ((heading - c.bearing + 540) % 360) - 180;
            return diff.abs() <= 75;
          }).toList();
      if (headingMatches.isNotEmpty) {
        headingMatches.sort((a, b) => a.offsetMeters.compareTo(b.offsetMeters));
        busAlong = headingMatches.first.alongMeters;
      } else {
        candidates.sort((a, b) => a.offsetMeters.compareTo(b.offsetMeters));
        busAlong = candidates.first.alongMeters;
      }
    } else {
      candidates.sort((a, b) => a.offsetMeters.compareTo(b.offsetMeters));
      busAlong = candidates.first.alongMeters;
    }
  }

  // 3. Find segment between stops
  int segIndex = 0;
  double fraction = 0.0;

  if (busAlong <= stopDistances.first) {
    segIndex = 0;
    fraction = 0.0;
  } else if (busAlong >= stopDistances.last) {
    segIndex = n - 2;
    fraction = 1.0;
  } else {
    for (var i = 0; i < n - 1; i++) {
      if (busAlong >= stopDistances[i] && busAlong <= stopDistances[i + 1]) {
        segIndex = i;
        final segLen = stopDistances[i + 1] - stopDistances[i];
        fraction =
            segLen > 1.0
                ? ((busAlong - stopDistances[i]) / segLen).clamp(0.0, 1.0)
                : 0.0;
        break;
      }
    }
  }

  final continuousIndex = (segIndex + fraction).clamp(0.0, (n - 1).toDouble());

  // 4. Check if dwelling/arrived at stop
  final distPrev = busPoint.distanceToMeters(orderedStops[segIndex].location);
  final distNext = busPoint.distanceToMeters(
    orderedStops[segIndex + 1].location,
  );
  const atStopThresholdMeters = BusTelemetry.atStopThresholdMeters;
  final isStopped =
      bus.position.speedKmH <= BusTelemetry.stopDwellingSpeedThresholdKmH;

  final bool isAtStop;
  final int currentStopIndex;
  final Stop? currentStop;
  final Stop? previousStop;
  final Stop? nextStop;
  final double? distToNext;
  final double? distFromPrev;

  final hasDepartedPrev =
      progress != null &&
      progress.lastEventType == 'departed' &&
      progress.currentStopId == orderedStops[segIndex].id;

  if (!hasDepartedPrev &&
      isStopped &&
      (distPrev <= atStopThresholdMeters ||
          (fraction < 0.08 && distPrev <= 50.0))) {
    isAtStop = true;
    currentStopIndex = segIndex;
    currentStop = orderedStops[segIndex];
    previousStop = segIndex > 0 ? orderedStops[segIndex - 1] : null;
    nextStop = segIndex + 1 < n ? orderedStops[segIndex + 1] : null;
    distToNext = stopDistances[segIndex + 1] - stopDistances[segIndex];
    distFromPrev = 0.0;
  } else if (isStopped &&
      (distNext <= atStopThresholdMeters ||
          (fraction > 0.92 && distNext <= 50.0))) {
    isAtStop = true;
    currentStopIndex = segIndex + 1;
    currentStop = orderedStops[segIndex + 1];
    previousStop = orderedStops[segIndex];
    nextStop = segIndex + 2 < n ? orderedStops[segIndex + 2] : null;
    distToNext =
        (segIndex + 2 < n)
            ? stopDistances[segIndex + 2] - stopDistances[segIndex + 1]
            : 0.0;
    distFromPrev = stopDistances[segIndex + 1] - stopDistances[segIndex];
  } else {
    isAtStop = false;
    currentStopIndex = segIndex;
    currentStop = null;
    previousStop = orderedStops[segIndex];
    nextStop = orderedStops[segIndex + 1];
    distToNext = (stopDistances[segIndex + 1] - busAlong).clamp(
      0.0,
      double.infinity,
    );
    distFromPrev = (busAlong - stopDistances[segIndex]).clamp(
      0.0,
      double.infinity,
    );
  }

  return BusRouteProgressDetails(
    orderedStops: orderedStops,
    currentStopIndex: currentStopIndex,
    continuousProgressIndex: continuousIndex,
    isAtStop: isAtStop,
    currentStop: currentStop,
    previousStop: previousStop,
    nextStop: nextStop,
    distanceToNextStopMeters: distToNext,
    distanceFromPreviousStopMeters: distFromPrev,
    segmentProgressFraction: fraction,
  );
}

/// Evaluates and filters candidate buses serving [boardingStop],
/// distinguishing confirmed upcoming, at stop, estimated, and passed buses.
List<BusArrivalEstimate> filterRelevantBusesForStop({
  required Stop boardingStop,
  required List<Bus> buses,
  required Map<String, BusRoute> routesById,
  required Map<String, BusStopProgress?> progressByBusId,
  DateTime Function()? clock,
}) {
  final nowClock = clock ?? DateTime.now;
  final results = <BusArrivalEstimate>[];

  for (final rawBus in buses) {
    final route = routesById[rawBus.routeId];
    if (route == null || !route.stopIds.contains(boardingStop.id)) {
      continue;
    }

    // Bus position must be a valid GPS coordinate
    if (!rawBus.hasValidLocation) {
      continue;
    }

    final telemetryAge = nowClock().difference(rawBus.lastUpdated);
    final isClockSkewAnomalous =
        telemetryAge.isNegative &&
        telemetryAge.inSeconds < -BusTelemetry.clockSkewTolerance.inSeconds;
    final isStaleDynamic =
        rawBus.isStale ||
        telemetryAge > BusTelemetry.staleAfter ||
        isClockSkewAnomalous;
    final bus =
        isStaleDynamic && !rawBus.isStale
            ? rawBus.copyWith(isStale: true)
            : rawBus;

    final progress = progressByBusId[bus.id];
    final allRouteStops =
        route.stopOccurrences.map((o) => o.stop).whereType<Stop>().toList();
    final stopsList = allRouteStops.isNotEmpty ? allRouteStops : [boardingStop];

    // 1. Calculate actual along-route progress details from live GPS & route geometry
    final progressDetails = calculateRouteProgressDetails(
      route: route,
      bus: bus,
      allStops: stopsList,
      progress: progress,
    );

    // 2. Check off-route status
    final busProjections =
        route.path.length >= 2
            ? RouteProgressProjector.candidates(route.path, bus.position.point)
            : const <RouteProjection>[];
    final bestProjection =
        busProjections.isNotEmpty
            ? busProjections.reduce(
              (a, b) => a.offsetMeters < b.offsetMeters ? a : b,
            )
            : null;
    final isOffRoute =
        route.path.length >= 2 &&
        (bestProjection == null ||
            bestProjection.offsetMeters > BusTelemetry.maxOffRouteMeters);

    // 3. Determine whether bus is physically dwelling at the selected boarding stop
    // Precedence: Verified stop event confirms arrival; live GPS confirms physical presence.
    // Projection alone does not claim stop-arrival without verified events.
    final hasVerifiedArrival =
        progress != null &&
        progress.currentStopId == boardingStop.id &&
        progress.lastEventType == 'arrived';

    final isAtThisBoardingStop =
        !bus.isStale &&
        !isOffRoute &&
        hasVerifiedArrival &&
        progressDetails.isAtStop &&
        progressDetails.currentStop?.id == boardingStop.id;

    // 4. Determine relevance (relationship to selected boarding stop)
    BusStopRelevance relevance;
    if (isOffRoute || bus.isStale) {
      relevance = BusStopRelevance.routeUncertain;
    } else if (isAtThisBoardingStop) {
      relevance = BusStopRelevance.atStop;
    } else {
      // Check if boarding stop is upcoming on the remaining portion of the trip
      final isCurrentlyAtBoarding =
          progressDetails.currentStop?.id == boardingStop.id;
      final checkFromIndex =
          isCurrentlyAtBoarding
              ? progressDetails.currentStopIndex
              : progressDetails.currentStopIndex +
                  (progressDetails.isAtStop ? 1 : 0);
      final remainingStops =
          progressDetails.orderedStops.length > checkFromIndex
              ? progressDetails.orderedStops.sublist(checkFromIndex)
              : <Stop>[];
      final isUpcomingOnTrip = remainingStops.any(
        (s) => s.id == boardingStop.id,
      );

      if (isUpcomingOnTrip) {
        relevance =
            progress != null
                ? BusStopRelevance.confirmedApproaching
                : BusStopRelevance.estimatedApproaching;
      } else {
        // Bus has already passed all occurrences of boardingStop on this trip
        relevance = BusStopRelevance.passed;
        continue;
      }
    }

    // 5. Build physical location text (where the bus ACTUALLY is)
    String currentPositionText;
    if (bus.isStale) {
      final near = progressDetails.currentStop ?? progressDetails.previousStop;
      currentPositionText =
          near != null
              ? 'Stale location · Near ${near.name}'
              : 'Stale location · ${route.name}';
    } else if (isOffRoute) {
      currentPositionText = 'GPS position off expected route';
    } else if (progressDetails.isAtStop &&
        progressDetails.currentStop != null) {
      currentPositionText = 'At ${progressDetails.currentStop!.name}';
    } else if (progressDetails.nextStop != null) {
      if (progressDetails.distanceToNextStopMeters != null &&
          progressDetails.distanceToNextStopMeters! < 80.0) {
        currentPositionText = 'Approaching ${progressDetails.nextStop!.name}';
      } else {
        currentPositionText = 'En route to ${progressDetails.nextStop!.name}';
      }
    } else if (progressDetails.previousStop != null) {
      currentPositionText = 'Passed ${progressDetails.previousStop!.name}';
    } else {
      currentPositionText = 'En route · ${route.name}';
    }

    // 6. Build boarding relationship subtitle
    String locationSubtitle;
    if (isAtThisBoardingStop) {
      locationSubtitle = 'Bus is at your boarding stop';
    } else if (bus.isStale) {
      locationSubtitle =
          'Last reported ${TransitFormatter.formatLastUpdated(bus.lastUpdated)}';
    } else if (isOffRoute) {
      locationSubtitle = 'Location available · Route progress uncertain';
    } else if (progressDetails.nextStop?.id == boardingStop.id) {
      final meters = progressDetails.distanceToNextStopMeters?.round();
      locationSubtitle =
          meters != null
              ? '${boardingStop.name} is the next stop · ${meters}m away'
              : 'Approaching ${boardingStop.name}';
    } else if (progressDetails.previousStop != null &&
        progressDetails.nextStop != null &&
        !progressDetails.isAtStop &&
        progressDetails.distanceToNextStopMeters != null) {
      locationSubtitle =
          'Passed ${progressDetails.previousStop!.name} · ${progressDetails.distanceToNextStopMeters!.round()}m to ${progressDetails.nextStop!.name}';
    } else if (progress?.direction == 'forward' &&
        _isReturnStop(boardingStop.id, route)) {
      locationSubtitle = '${boardingStop.name} is ahead on return leg';
    } else {
      locationSubtitle = '${boardingStop.name} is ahead on this trip';
    }

    // 7. Calculate ETA
    final calculatedEta = BusEtaCalculator.calculateForStop(
      bus: bus,
      route: route.path,
      progress: progress,
      targetStopId: boardingStop.id,
      stopOccurrences: route.stopOccurrences,
      clock: nowClock,
    );

    final previousStopName =
        progressDetails.previousStop?.name ??
        (progress?.visitedStopIds.isNotEmpty == true
            ? route.stopOccurrences
                .where((o) => progress!.visitedStopIds.contains(o.stopId))
                .lastOrNull
                ?.stop
                ?.name
            : route.stopOccurrences.firstOrNull?.stop?.name);

    final nextStopName =
        progressDetails.nextStop?.name ??
        progress?.nextStop?.stop?.name ??
        progress?.nextStop?.stopId;

    int? resolvedStopsAway = calculatedEta.stopsAway;
    if (resolvedStopsAway == null && !isAtThisBoardingStop) {
      if (progress?.nextStop?.stopId == boardingStop.id) {
        resolvedStopsAway = 1;
      } else if (progress != null && progress.upcomingStops.isNotEmpty) {
        final upIdx = progress.upcomingStops.indexWhere(
          (o) => o.stopId == boardingStop.id,
        );
        if (upIdx >= 0) {
          resolvedStopsAway = upIdx + 1;
        }
      } else {
        final checkFromIndex =
            progressDetails.currentStopIndex +
            (progressDetails.isAtStop ? 1 : 0);
        final rem =
            progressDetails.orderedStops.length > checkFromIndex
                ? progressDetails.orderedStops.sublist(checkFromIndex)
                : <Stop>[];
        final remIdx = rem.indexWhere((s) => s.id == boardingStop.id);
        if (remIdx >= 0) {
          resolvedStopsAway = remIdx + 1;
        }
      }
    }

    results.add(
      BusArrivalEstimate(
        bus: bus,
        route: route,
        eta: calculatedEta,
        stopsAway: resolvedStopsAway,
        nextStopName: nextStopName,
        relevance: relevance,
        currentPositionText: currentPositionText,
        locationSubtitle: locationSubtitle,
        previousStopName: previousStopName,
        progress: progress,
        progressDetails: progressDetails,
      ),
    );
  }

  results.sort((a, b) {
    if (a.isAtStop != b.isAtStop) {
      return a.isAtStop ? -1 : 1;
    }
    if (a.isConfirmed != b.isConfirmed) {
      return a.isConfirmed ? -1 : 1;
    }
    if (a.eta.isValid && b.eta.isValid) {
      final etaCmp = a.eta.minutes!.compareTo(b.eta.minutes!);
      if (etaCmp != 0) return etaCmp;
    }
    if (a.eta.isValid != b.eta.isValid) {
      return a.eta.isValid ? -1 : 1;
    }
    final aStops = a.resolvedStopsAway;
    final bStops = b.resolvedStopsAway;
    if (aStops != null && bStops != null && aStops != bStops) {
      return aStops.compareTo(bStops);
    }
    return b.bus.lastUpdated.compareTo(a.bus.lastUpdated);
  });

  return results;
}

bool _isReturnStop(String stopId, BusRoute route) {
  final occurrences = route.stopOccurrences;
  if (occurrences.length < 5) return false;
  int? turnaroundIdx;
  for (var i = 1; i < occurrences.length - 1; i++) {
    if (occurrences[i - 1].stopId == occurrences[i + 1].stopId) {
      turnaroundIdx = i;
      break;
    }
  }
  if (turnaroundIdx == null) return false;
  return occurrences.sublist(turnaroundIdx).any((o) => o.stopId == stopId);
}
