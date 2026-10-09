import '../../core/geo/geo_point.dart';
import '../../data/transit/bus.dart';
import '../../data/transit/bus_route.dart';
import '../../data/transit/scheduled_departure.dart';
import '../../data/transit/stop.dart';

class BusArrivalEstimate {
  const BusArrivalEstimate({
    required this.bus,
    required this.route,
    required this.etaMinutes,
  });

  final Bus bus;
  final BusRoute route;
  final int etaMinutes;
}

/// Estimates arrivals only from active buses whose route serves [stop].
/// The straight-line estimate is intentionally labeled approximate in the UI.
BusArrivalEstimate? estimateNextBus({
  required Stop stop,
  required List<Bus> buses,
  required List<BusRoute> routes,
}) {
  final estimates = <BusArrivalEstimate>[];
  for (final bus in buses) {
    if (bus.status == BusStatus.offline || bus.routeId == null) continue;

    final route = routes.where((item) => item.id == bus.routeId).firstOrNull;
    if (route == null || !route.stopIds.contains(stop.id)) continue;

    final speedMetersPerMinute =
        (bus.position.speedKmH > 2 ? bus.position.speedKmH : 12.0) * 1000 / 60;
    final distanceMeters = _distanceToStop(bus.position.point, stop.location);
    estimates.add(
      BusArrivalEstimate(
        bus: bus,
        route: route,
        etaMinutes: (distanceMeters / speedMetersPerMinute).ceil().clamp(1, 60),
      ),
    );
  }

  if (estimates.isEmpty) return null;
  estimates.sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));
  return estimates.first;
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

const campusStopWalkingRangeMeters = 3000.0;

/// Returns a campus stop only when the location is within a useful walking range.
Stop? nearestCampusStopTo(GeoPoint point, Iterable<Stop> stops) {
  final nearest = nearestStopTo(point, stops);
  if (nearest == null) return null;
  if (point.distanceToMeters(nearest.location) > campusStopWalkingRangeMeters) {
    return null;
  }
  return nearest;
}

/// Rough walking-time estimate from straight-line distance, not a pedestrian route.
int estimateWalkMinutes(double distanceMeters) {
  if (distanceMeters <= 0) return 1;
  return (distanceMeters / 80).ceil();
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

double _distanceToStop(GeoPoint from, GeoPoint to) => from.distanceToMeters(to);
