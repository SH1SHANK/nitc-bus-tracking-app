import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/formatting/transit_formatter.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_eta.dart';
import 'package:tracklet/data/transit/bus_position.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/bus_stop_event.dart';
import 'package:tracklet/data/transit/bus_stop_progress.dart';
import 'package:tracklet/data/transit/route_stop_occurrence.dart';
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

  group('BusArrivalEstimate and multi-stop ETA', () {
    test(
      'BusArrivalEstimate properly resolves stopsAway and formatted status',
      () {
        final bus = Bus(
          id: 'bus-1',
          numberPlate: 'KL-11-BH-1234',
          name: 'Bus 1',
          status: BusStatus.live,
          position: BusPosition(
            point: stop.location,
            timestamp: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );
        final estimate = BusArrivalEstimate(
          bus: bus,
          route: route,
          stopsAway: 3,
          nextStopName: 'East Campus',
          eta: const BusEtaResult.unavailable(
            BusEtaStatus.unresolvedStopProgress,
          ),
        );

        expect(estimate.stopsAway, 3);
        expect(estimate.resolvedStopsAway, 3);
        expect(estimate.nextStopName, 'East Campus');
      },
    );
  });

  group('filterRelevantBusesForStop', () {
    const stopMainGate = Stop(
      id: 'main-gate',
      name: 'Main Gate',
      code: 'MG',
      location: GeoPoint(latitude: 11.3216, longitude: 75.9337),
    );
    const stopLibrary = Stop(
      id: 'library',
      name: 'Library',
      code: 'LIB',
      location: GeoPoint(latitude: 11.3225, longitude: 75.9345),
    );
    const stopEastCampus = Stop(
      id: 'east-campus',
      name: 'East Campus',
      code: 'EC',
      location: GeoPoint(latitude: 11.3250, longitude: 75.9360),
    );

    const linearRoute = BusRoute(
      id: 'route-linear',
      name: 'Main Gate to East Campus',
      code: 'R1',
      stopIds: ['main-gate', 'library', 'east-campus'],
      path: [
        GeoPoint(latitude: 11.3216, longitude: 75.9337),
        GeoPoint(latitude: 11.3225, longitude: 75.9345),
        GeoPoint(latitude: 11.3250, longitude: 75.9360),
      ],
      stopOccurrences: [
        RouteStopOccurrence(
          routeId: 'route-linear',
          stopId: 'main-gate',
          sequence: 0,
          stop: stopMainGate,
        ),
        RouteStopOccurrence(
          routeId: 'route-linear',
          stopId: 'library',
          sequence: 1,
          stop: stopLibrary,
        ),
        RouteStopOccurrence(
          routeId: 'route-linear',
          stopId: 'east-campus',
          sequence: 2,
          stop: stopEastCampus,
        ),
      ],
    );

    const loopRoute = BusRoute(
      id: 'route-loop',
      name: 'Campus Loop',
      code: 'CL',
      stopIds: ['main-gate', 'library', 'east-campus', 'main-gate'],
      path: [
        GeoPoint(latitude: 11.3216, longitude: 75.9337),
        GeoPoint(latitude: 11.3225, longitude: 75.9345),
        GeoPoint(latitude: 11.3250, longitude: 75.9360),
        GeoPoint(latitude: 11.3216, longitude: 75.9337),
      ],
      stopOccurrences: [
        RouteStopOccurrence(
          routeId: 'route-loop',
          stopId: 'main-gate',
          sequence: 0,
          stop: stopMainGate,
        ),
        RouteStopOccurrence(
          routeId: 'route-loop',
          stopId: 'library',
          sequence: 1,
          stop: stopLibrary,
        ),
        RouteStopOccurrence(
          routeId: 'route-loop',
          stopId: 'east-campus',
          sequence: 2,
          stop: stopEastCampus,
        ),
        RouteStopOccurrence(
          routeId: 'route-loop',
          stopId: 'main-gate',
          sequence: 3,
          stop: stopMainGate,
        ),
      ],
    );

    test(
      'includes bus approaching the target stop with confirmed progress',
      () {
        final bus = Bus(
          id: 'bus-1',
          numberPlate: 'KL-11-0001',
          name: 'Campus Bus 1',
          routeId: 'route-linear',
          tripId: 'trip-1',
          status: BusStatus.live,
          position: BusPosition(
            point: stopMainGate.location,
            speedKmH: 15,
            timestamp: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );

        final progress = resolveBusStopProgress(
          routeStops: linearRoute.stopOccurrences,
          events: [
            BusStopEvent(
              stopId: 'main-gate',
              type: 'departed',
              occurredAt: DateTime.now().subtract(const Duration(minutes: 1)),
            ),
          ],
          direction: 'forward',
        );

        final results = filterRelevantBusesForStop(
          boardingStop: stopEastCampus,
          buses: [bus],
          routesById: {linearRoute.id: linearRoute},
          progressByBusId: {bus.id: progress},
        );

        expect(results.length, 1);
        expect(results.first.bus.id, 'bus-1');
        expect(results.first.relevance, BusStopRelevance.confirmedApproaching);
        expect(results.first.nextStopName, 'Library');
        expect(results.first.currentPositionText, 'En route to Library');
      },
    );

    test(
      'excludes bus that has already passed the target stop on linear route',
      () {
        final bus = Bus(
          id: 'bus-past',
          numberPlate: 'KL-11-0002',
          name: 'Campus Bus 2',
          routeId: 'route-linear',
          tripId: 'trip-2',
          status: BusStatus.live,
          position: BusPosition(
            point: stopEastCampus.location,
            speedKmH: 15,
            timestamp: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );

        final progress = resolveBusStopProgress(
          routeStops: linearRoute.stopOccurrences,
          events: [
            BusStopEvent(
              stopId: 'main-gate',
              type: 'arrived',
              occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
            ),
            BusStopEvent(
              stopId: 'main-gate',
              type: 'departed',
              occurredAt: DateTime.now().subtract(const Duration(minutes: 4)),
            ),
            BusStopEvent(
              stopId: 'library',
              type: 'arrived',
              occurredAt: DateTime.now().subtract(const Duration(minutes: 2)),
            ),
            BusStopEvent(
              stopId: 'library',
              type: 'departed',
              occurredAt: DateTime.now().subtract(const Duration(minutes: 1)),
            ),
          ],
          direction: 'forward',
        );

        // Boarding stop is Main Gate, but bus is already past Library towards East Campus
        final results = filterRelevantBusesForStop(
          boardingStop: stopMainGate,
          buses: [bus],
          routesById: {linearRoute.id: linearRoute},
          progressByBusId: {bus.id: progress},
        );

        expect(results, isEmpty);
      },
    );

    test('flags bus dwelling at target stop as atStop', () {
      final bus = Bus(
        id: 'bus-dwelling',
        numberPlate: 'KL-11-0003',
        name: 'Campus Bus 3',
        routeId: 'route-linear',
        tripId: 'trip-3',
        status: BusStatus.due,
        position: BusPosition(
          point: stopLibrary.location,
          speedKmH: 0,
          timestamp: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      final progress = resolveBusStopProgress(
        routeStops: linearRoute.stopOccurrences,
        events: [
          BusStopEvent(
            stopId: 'main-gate',
            type: 'departed',
            occurredAt: DateTime.now().subtract(const Duration(minutes: 2)),
          ),
          BusStopEvent(
            stopId: 'library',
            type: 'arrived',
            occurredAt: DateTime.now().subtract(const Duration(seconds: 30)),
          ),
        ],
        direction: 'forward',
      );

      final results = filterRelevantBusesForStop(
        boardingStop: stopLibrary,
        buses: [bus],
        routesById: {linearRoute.id: linearRoute},
        progressByBusId: {bus.id: progress},
      );

      expect(results.length, 1);
      expect(results.first.isAtStop, isTrue);
      expect(results.first.currentPositionText, 'At Library');
      expect(results.first.locationSubtitle, 'Bus is at your boarding stop');
    });

    test('excludes buses on incompatible routes and invalid GPS points', () {
      final incompatibleBus = Bus(
        id: 'bus-other',
        numberPlate: 'KL-11-0004',
        name: 'Other Bus',
        routeId: 'route-other',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.32, longitude: 75.93),
          timestamp: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      final unassignedBus = Bus(
        id: 'bus-unassigned',
        numberPlate: 'KL-11-0005',
        name: 'Unassigned Bus',
        routeId: null,
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.3216, longitude: 75.9337),
          timestamp: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      final results = filterRelevantBusesForStop(
        boardingStop: stopLibrary,
        buses: [incompatibleBus, unassignedBus],
        routesById: {linearRoute.id: linearRoute},
        progressByBusId: {},
      );

      expect(results, isEmpty);
    });

    test('handles loop routes appropriately for upcoming stops in cycle', () {
      final bus = Bus(
        id: 'bus-loop',
        numberPlate: 'KL-11-0006',
        name: 'Loop Bus',
        routeId: 'route-loop',
        tripId: 'trip-loop',
        status: BusStatus.live,
        position: BusPosition(
          point: stopLibrary.location,
          speedKmH: 10,
          timestamp: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      final progress = resolveBusStopProgress(
        routeStops: loopRoute.stopOccurrences,
        events: [
          BusStopEvent(
            stopId: 'main-gate',
            type: 'departed',
            occurredAt: DateTime.now().subtract(const Duration(minutes: 2)),
          ),
          BusStopEvent(
            stopId: 'library',
            type: 'departed',
            occurredAt: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
        ],
        direction: 'forward',
      );

      final results = filterRelevantBusesForStop(
        boardingStop: stopEastCampus,
        buses: [bus],
        routesById: {loopRoute.id: loopRoute},
        progressByBusId: {bus.id: progress},
      );

      expect(results.length, 1);
      expect(results.first.relevance, BusStopRelevance.confirmedApproaching);
    });

    test(
      'multi-occurrence loop correctly presents initial stop as upcoming for return leg',
      () {
        const multiOccurrenceLoop = BusRoute(
          id: 'route-multi-loop',
          name: 'Campus Circular',
          code: 'CC-1',
          stopIds: ['main-gate', 'library', 'east-campus', 'main-gate'],
          path: [
            GeoPoint(latitude: 11.3216, longitude: 75.9337),
            GeoPoint(latitude: 11.3225, longitude: 75.9345),
            GeoPoint(latitude: 11.3250, longitude: 75.9360),
            GeoPoint(latitude: 11.3216, longitude: 75.9337),
          ],
          stopOccurrences: [
            RouteStopOccurrence(
              routeId: 'route-multi-loop',
              stopId: 'main-gate',
              sequence: 1,
              stop: stopMainGate,
            ),
            RouteStopOccurrence(
              routeId: 'route-multi-loop',
              stopId: 'library',
              sequence: 2,
              stop: stopLibrary,
            ),
            RouteStopOccurrence(
              routeId: 'route-multi-loop',
              stopId: 'east-campus',
              sequence: 3,
              stop: stopEastCampus,
            ),
            RouteStopOccurrence(
              routeId: 'route-multi-loop',
              stopId: 'main-gate',
              sequence: 4,
              stop: stopMainGate,
            ),
          ],
        );

        final bus = Bus(
          id: 'bus-multi-loop',
          numberPlate: 'KL-11-0007',
          name: 'Circular Bus',
          routeId: 'route-multi-loop',
          tripId: 'trip-multi-loop',
          status: BusStatus.live,
          position: BusPosition(
            point: stopLibrary.location,
            speedKmH: 12,
            timestamp: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );

        // Bus has departed Main Gate (seq 1) and Library (seq 2)
        final progress = resolveBusStopProgress(
          routeStops: multiOccurrenceLoop.stopOccurrences,
          events: [
            BusStopEvent(
              stopId: 'main-gate',
              type: 'departed',
              occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
            ),
            BusStopEvent(
              stopId: 'library',
              type: 'departed',
              occurredAt: DateTime.now().subtract(const Duration(minutes: 2)),
            ),
          ],
          direction: 'forward',
        );

        // Rider is waiting at Main Gate for the return leg
        final results = filterRelevantBusesForStop(
          boardingStop: stopMainGate,
          buses: [bus],
          routesById: {multiOccurrenceLoop.id: multiOccurrenceLoop},
          progressByBusId: {bus.id: progress},
        );

        // Even though bus departed the first occurrence of Main Gate,
        // Main Gate at seq 4 is upcoming and must be included!
        expect(results, hasLength(1));
        final estimate = results.first;
        expect(estimate.relevance, BusStopRelevance.confirmedApproaching);
        expect(estimate.stopsAway, 2); // East Campus (seq 3), Main Gate (seq 4)
      },
    );

    test('dynamically flags future clock-skewed telemetry as stale', () {
      final fixedNow = DateTime(2026, 7, 21, 12, 0, 0);

      // Bus with telemetry timestamp 30 seconds in the future
      final futureBus = Bus(
        id: 'bus-future',
        numberPlate: 'KL-11-0008',
        name: 'Future Bus',
        routeId: 'route-linear',
        status: BusStatus.live,
        position: BusPosition(
          point: stopMainGate.location,
          speedKmH: 15,
          timestamp: fixedNow.add(const Duration(seconds: 30)),
        ),
        lastUpdated: fixedNow.add(const Duration(seconds: 30)),
        isStale: false,
      );

      final results = filterRelevantBusesForStop(
        boardingStop: stopLibrary,
        buses: [futureBus],
        routesById: {linearRoute.id: linearRoute},
        progressByBusId: {},
        clock: () => fixedNow,
      );

      expect(results, hasLength(1));
      expect(results.first.bus.isStale, isTrue);
    });

    test(
      'tolerates mild future timestamp jitter within 15 seconds without marking stale',
      () {
        final fixedNow = DateTime(2026, 7, 21, 12, 0, 0);

        final jitterBus = Bus(
          id: 'bus-jitter',
          numberPlate: 'KL-11-0009',
          name: 'Jitter Bus',
          routeId: 'route-linear',
          status: BusStatus.live,
          position: BusPosition(
            point: stopMainGate.location,
            speedKmH: 15,
            timestamp: fixedNow.add(const Duration(seconds: 5)),
          ),
          lastUpdated: fixedNow.add(const Duration(seconds: 5)),
          isStale: false,
        );

        final results = filterRelevantBusesForStop(
          boardingStop: stopLibrary,
          buses: [jitterBus],
          routesById: {linearRoute.id: linearRoute},
          progressByBusId: {},
          clock: () => fixedNow,
        );

        expect(results, hasLength(1));
        expect(results.first.bus.isStale, isFalse);
      },
    );
  });

  group('TransitFormatter.formatLastUpdated', () {
    final fixedNow = DateTime(2026, 7, 21, 12, 0, 0);

    test('formats recent timestamps and handles future timestamps safely', () {
      expect(
        TransitFormatter.formatLastUpdated(
          fixedNow.subtract(const Duration(seconds: 5)),
          now: fixedNow,
        ),
        'just now',
      );
      expect(
        TransitFormatter.formatLastUpdated(
          fixedNow.add(const Duration(seconds: 10)),
          now: fixedNow,
        ),
        'just now',
      );
      expect(
        TransitFormatter.formatLastUpdated(
          fixedNow.subtract(const Duration(seconds: 45)),
          now: fixedNow,
        ),
        '45s ago',
      );
      expect(
        TransitFormatter.formatLastUpdated(
          fixedNow.subtract(const Duration(minutes: 5)),
          now: fixedNow,
        ),
        '5m ago',
      );
      expect(
        TransitFormatter.formatLastUpdated(
          fixedNow.subtract(const Duration(hours: 2)),
          now: fixedNow,
        ),
        '2h ago',
      );
    });
  });

  group('calculateRouteProgressDetails', () {
    const stopA = Stop(
      id: 'stop-a',
      name: 'Stop A',
      location: GeoPoint(latitude: 11.317, longitude: 75.937),
    );
    const stopB = Stop(
      id: 'stop-b',
      name: 'Stop B',
      location: GeoPoint(latitude: 11.321, longitude: 75.934),
    );
    const stopC = Stop(
      id: 'stop-c',
      name: 'Stop C',
      location: GeoPoint(latitude: 11.323, longitude: 75.937),
    );

    const route = BusRoute(
      id: 'route-loop',
      name: 'Loop Route',
      code: 'R1',
      path: [
        GeoPoint(latitude: 11.317, longitude: 75.937),
        GeoPoint(latitude: 11.319, longitude: 75.9355),
        GeoPoint(latitude: 11.321, longitude: 75.934),
        GeoPoint(latitude: 11.323, longitude: 75.937),
        GeoPoint(latitude: 11.317, longitude: 75.937),
      ],
      stopOccurrences: [
        RouteStopOccurrence(
          routeId: 'route-loop',
          stopId: 'stop-a',
          sequence: 0,
          stop: stopA,
        ),
        RouteStopOccurrence(
          routeId: 'route-loop',
          stopId: 'stop-b',
          sequence: 1,
          stop: stopB,
        ),
        RouteStopOccurrence(
          routeId: 'route-loop',
          stopId: 'stop-c',
          sequence: 2,
          stop: stopC,
        ),
        RouteStopOccurrence(
          routeId: 'route-loop',
          stopId: 'stop-a',
          sequence: 3,
          stop: stopA,
        ),
      ],
      stopIds: ['stop-a', 'stop-b', 'stop-c', 'stop-a'],
    );

    test('detects bus dwelling at stop A', () {
      final bus = Bus(
        id: 'bus-1',
        numberPlate: 'KL-11-0001',
        name: 'Bus 1',
        routeId: 'route-loop',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.317, longitude: 75.937),
          timestamp: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      final details = calculateRouteProgressDetails(
        route: route,
        bus: bus,
        allStops: const [stopA, stopB, stopC],
      );

      expect(details.isAtStop, isTrue);
      expect(details.currentStop?.id, 'stop-a');
      expect(details.currentStopIndex, 0);
      expect(details.continuousProgressIndex, closeTo(0.0, 0.05));
      expect(details.nextStop?.id, 'stop-b');
    });

    test(
      'calculates fractional along-route progress between Stop A and Stop B',
      () {
        // Halfway point along the first segment
        final bus = Bus(
          id: 'bus-1',
          numberPlate: 'KL-11-0001',
          name: 'Bus 1',
          routeId: 'route-loop',
          status: BusStatus.live,
          position: BusPosition(
            point: const GeoPoint(latitude: 11.319, longitude: 75.9355),
            timestamp: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );

        final details = calculateRouteProgressDetails(
          route: route,
          bus: bus,
          allStops: const [stopA, stopB, stopC],
        );

        expect(details.isAtStop, isFalse);
        expect(details.previousStop?.id, 'stop-a');
        expect(details.nextStop?.id, 'stop-b');
        expect(details.currentStopIndex, 0);
        expect(details.continuousProgressIndex, greaterThan(0.2));
        expect(details.continuousProgressIndex, lessThan(0.8));
        expect(details.distanceToNextStopMeters, isNotNull);
        expect(details.distanceToNextStopMeters, greaterThan(0));
      },
    );

    test('progresses across repeated stop occurrence on return leg', () {
      // Near final return segment approaching stop A (sequence 3)
      final bus = Bus(
        id: 'bus-1',
        numberPlate: 'KL-11-0001',
        name: 'Bus 1',
        routeId: 'route-loop',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.318, longitude: 75.937),
          heading: 180, // heading south towards stop A return
          timestamp: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      final details = calculateRouteProgressDetails(
        route: route,
        bus: bus,
        allStops: const [stopA, stopB, stopC],
      );

      expect(details.continuousProgressIndex, greaterThan(2.0));
    });
  });
}
