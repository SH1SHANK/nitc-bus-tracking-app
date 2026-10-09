import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_position.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/scheduled_departure.dart';
import 'package:tracklet/data/transit/stop.dart';
import 'package:tracklet/features/home/home_transit_logic.dart';

void main() {
  const stop = Stop(
    id: 'stop-a',
    name: 'Main Gate',
    code: 'MG',
    location: GeoPoint(latitude: 11.3216, longitude: 75.9337),
  );
  const route = BusRoute(
    id: 'route-a',
    name: 'Campus Express',
    code: 'CE-1',
    stopIds: ['stop-a'],
  );

  Bus bus({
    required String id,
    required GeoPoint point,
    required BusStatus status,
    double speedKmH = 20,
    String routeId = 'route-a',
  }) => Bus(
    id: id,
    numberPlate: id,
    name: id,
    routeId: routeId,
    status: status,
    position: BusPosition(
      point: point,
      speedKmH: speedKmH,
      timestamp: DateTime(2026),
    ),
    lastUpdated: DateTime(2026),
  );

  group('estimateNextBus', () {
    test(
      'selects the closest serving bus and estimates at least one minute',
      () {
        final arrival = estimateNextBus(
          stop: stop,
          buses: [
            bus(
              id: 'far',
              point: const GeoPoint(latitude: 11.325, longitude: 75.938),
              status: BusStatus.live,
            ),
            bus(
              id: 'near',
              point: const GeoPoint(latitude: 11.3217, longitude: 75.9338),
              status: BusStatus.live,
            ),
          ],
          routes: [route],
        );

        expect(arrival?.bus.id, 'near');
        expect(arrival?.route, route);
        expect(arrival!.etaMinutes, 1);
      },
    );

    test(
      'ignores offline buses and buses on routes that do not serve the stop',
      () {
        final unrelatedRoute = route.copyWith(
          id: 'route-b',
          stopIds: const ['stop-b'],
        );
        final arrival = estimateNextBus(
          stop: stop,
          buses: [
            bus(id: 'offline', point: stop.location, status: BusStatus.offline),
            bus(
              id: 'unrelated',
              point: stop.location,
              status: BusStatus.live,
              routeId: 'route-b',
            ),
          ],
          routes: [route, unrelatedRoute],
        );

        expect(arrival, isNull);
      },
    );

    test('returns no estimate if there are no known routes or buses', () {
      expect(
        estimateNextBus(stop: stop, buses: const [], routes: const []),
        isNull,
      );
    });
  });

  group('nearestStopTo', () {
    test('returns the closest stop from the supplied list', () {
      const fartherStop = Stop(
        id: 'stop-far',
        name: 'Far stop',
        code: 'FAR',
        location: GeoPoint(latitude: 11.33, longitude: 75.94),
      );
      const closerStop = Stop(
        id: 'stop-close',
        name: 'Close stop',
        code: 'CLS',
        location: GeoPoint(latitude: 11.3217, longitude: 75.9338),
      );

      expect(
        nearestStopTo(stop.location, [fartherStop, closerStop]),
        closerStop,
      );
      expect(nearestStopTo(stop.location, const <Stop>[]), isNull);
    });

    test('only returns a campus stop within walking range', () {
      const farAway = GeoPoint(latitude: 40.7128, longitude: -74.006);

      expect(nearestCampusStopTo(stop.location, [stop]), stop);
      expect(nearestCampusStopTo(farAway, [stop]), isNull);
      expect(nearestCampusStopTo(stop.location, const <Stop>[]), isNull);
    });
  });

  group('upcomingDeparturesForStop', () {
    test('filters to future departures on routes serving the stop', () {
      const otherRoute = BusRoute(
        id: 'route-b',
        name: 'Other route',
        code: 'OR',
        stopIds: ['stop-b'],
      );
      const departures = [
        ScheduledDeparture(id: 'past', routeId: 'route-a', hour: 8, minute: 59),
        ScheduledDeparture(
          id: 'later',
          routeId: 'route-a',
          hour: 9,
          minute: 30,
          sortOrder: 2,
        ),
        ScheduledDeparture(
          id: 'earlier',
          routeId: 'route-a',
          hour: 9,
          minute: 10,
          sortOrder: 1,
        ),
        ScheduledDeparture(
          id: 'unserved',
          routeId: 'route-b',
          hour: 9,
          minute: 5,
        ),
      ];

      final upcoming = upcomingDeparturesForStop(
        stop: stop,
        departures: departures,
        routes: [route, otherRoute],
        now: DateTime(2026, 7, 21, 9),
      );

      expect(upcoming.map((departure) => departure.id), ['earlier', 'later']);
    });
  });

  group('estimateWalkMinutes', () {
    test(
      'converts straight-line distance to a minimum one-minute estimate',
      () {
        expect(estimateWalkMinutes(0), 1);
        expect(estimateWalkMinutes(80), 1);
        expect(estimateWalkMinutes(81), 2);
      },
    );
  });

  group('routeProgressFraction', () {
    test('maps the nearest route point to its normalized sequence', () {
      const pathRoute = BusRoute(
        id: 'route-path',
        name: 'Campus Express',
        code: 'CE-1',
        path: [
          GeoPoint(latitude: 11.0, longitude: 75.0),
          GeoPoint(latitude: 11.1, longitude: 75.1),
          GeoPoint(latitude: 11.2, longitude: 75.2),
        ],
      );

      expect(
        routeProgressFraction(
          route: pathRoute,
          point: const GeoPoint(latitude: 11.1, longitude: 75.1),
        ),
        0.5,
      );
    });

    test('returns null when route geometry or bus position is unavailable', () {
      expect(routeProgressFraction(route: route, point: stop.location), isNull);
      expect(routeProgressFraction(route: route, point: null), isNull);
    });
  });
}
