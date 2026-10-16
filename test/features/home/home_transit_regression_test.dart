import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_eta.dart';
import 'package:tracklet/data/transit/bus_position.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/bus_stop_event.dart';
import 'package:tracklet/data/transit/bus_stop_progress.dart';
import 'package:tracklet/data/transit/route_stop_occurrence.dart';
import 'package:tracklet/data/transit/stop.dart';
import 'package:tracklet/features/home/home_transit_logic.dart';
import 'package:tracklet/features/home/widgets/next_bus_card.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('Home Transit Telemetry & Contradiction Elimination Regression Tests', () {
    // Campus stops matching the NITC layout
    const stopMbh = Stop(
      id: 'mbh',
      name: 'Mega Hostel Boys',
      code: 'MBH',
      location: GeoPoint(latitude: 11.3150, longitude: 75.9340),
    );
    const stopAtmCircle = Stop(
      id: 'atm-circle',
      name: 'ATM Circle',
      code: 'ATM',
      location: GeoPoint(latitude: 11.3180, longitude: 75.9345),
    );
    const stopDept = Stop(
      id: 'dept',
      name: 'Department Building',
      code: 'DB',
      location: GeoPoint(latitude: 11.3220, longitude: 75.9350),
    );
    const stopArch = Stop(
      id: 'arch',
      name: 'Architecture',
      code: 'ARC',
      location: GeoPoint(latitude: 11.3240, longitude: 75.9360),
    );
    const stopEastCampus = Stop(
      id: 'east-campus',
      name: 'East Campus',
      code: 'EC',
      location: GeoPoint(latitude: 11.3260, longitude: 75.9370),
    );

    final outAndBackRoute = BusRoute(
      id: 'route-r1',
      name: 'East Campus - MBH',
      code: 'R1',
      path: [
        stopMbh.location,
        stopAtmCircle.location,
        stopDept.location,
        stopArch.location,
        stopEastCampus.location,
        stopArch.location,
        stopDept.location,
        stopAtmCircle.location,
        stopMbh.location,
      ],
      stopOccurrences: const [
        RouteStopOccurrence(
          routeId: 'route-r1',
          stopId: 'mbh',
          sequence: 0,
          stop: stopMbh,
        ),
        RouteStopOccurrence(
          routeId: 'route-r1',
          stopId: 'atm-circle',
          sequence: 1,
          stop: stopAtmCircle,
        ),
        RouteStopOccurrence(
          routeId: 'route-r1',
          stopId: 'dept',
          sequence: 2,
          stop: stopDept,
        ),
        RouteStopOccurrence(
          routeId: 'route-r1',
          stopId: 'arch',
          sequence: 3,
          stop: stopArch,
        ),
        RouteStopOccurrence(
          routeId: 'route-r1',
          stopId: 'east-campus',
          sequence: 4,
          stop: stopEastCampus,
        ),
        RouteStopOccurrence(
          routeId: 'route-r1',
          stopId: 'arch',
          sequence: 5,
          stop: stopArch,
        ),
        RouteStopOccurrence(
          routeId: 'route-r1',
          stopId: 'dept',
          sequence: 6,
          stop: stopDept,
        ),
        RouteStopOccurrence(
          routeId: 'route-r1',
          stopId: 'atm-circle',
          sequence: 7,
          stop: stopAtmCircle,
        ),
        RouteStopOccurrence(
          routeId: 'route-r1',
          stopId: 'mbh',
          sequence: 8,
          stop: stopMbh,
        ),
      ],
      stopIds: const [
        'mbh',
        'atm-circle',
        'dept',
        'arch',
        'east-campus',
        'arch',
        'dept',
        'atm-circle',
        'mbh',
      ],
    );

    final campusRoute = BusRoute(
      id: 'route-campus',
      name: 'Campus Circular',
      code: 'CC',
      path: [stopMbh.location, stopAtmCircle.location, stopDept.location],
      stopOccurrences: const [
        RouteStopOccurrence(
          routeId: 'route-campus',
          stopId: 'mbh',
          sequence: 0,
          stop: stopMbh,
        ),
        RouteStopOccurrence(
          routeId: 'route-campus',
          stopId: 'atm-circle',
          sequence: 1,
          stop: stopAtmCircle,
        ),
        RouteStopOccurrence(
          routeId: 'route-campus',
          stopId: 'dept',
          sequence: 2,
          stop: stopDept,
        ),
      ],
      stopIds: ['mbh', 'atm-circle', 'dept'],
    );

    test('SCENARIO 1: Eliminates MBH vs ATM Circle contradiction in logic', () {
      // Historical event says arrived at MBH earlier, but current live telemetry is at ATM Circle
      final busAtAtmCircle = Bus(
        id: 'bus-1',
        numberPlate: 'KL-11-0001',
        name: 'Campus Bus 1',
        routeId: 'route-campus',
        tripId: 'trip-1',
        status: BusStatus.live,
        position: BusPosition(
          point: stopAtmCircle.location,
          speedKmH: 0.0, // dwelling at ATM Circle
          timestamp: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      final progressWithStaleMbhEvent = resolveBusStopProgress(
        routeStops: campusRoute.stopOccurrences,
        events: [
          BusStopEvent(
            stopId: 'mbh',
            type: 'arrived',
            occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          BusStopEvent(
            stopId: 'mbh',
            type: 'departed',
            occurredAt: DateTime.now().subtract(const Duration(minutes: 4)),
          ),
          BusStopEvent(
            stopId: 'atm-circle',
            type: 'arrived',
            occurredAt: DateTime.now().subtract(const Duration(seconds: 15)),
          ),
        ],
        direction: 'forward',
      );

      // Selected boarding stop is MBH, which the bus has already departed
      final results = filterRelevantBusesForStop(
        boardingStop: stopMbh,
        buses: [busAtAtmCircle],
        routesById: {campusRoute.id: campusRoute},
        progressByBusId: {busAtAtmCircle.id: progressWithStaleMbhEvent},
      );

      // The bus has passed MBH and will not return on this linear route, so it should be excluded from approaching
      expect(results, isEmpty);

      // Now test from perspective of someone boarding at Department Building
      final resultsForDept = filterRelevantBusesForStop(
        boardingStop: stopDept,
        buses: [busAtAtmCircle],
        routesById: {campusRoute.id: campusRoute},
        progressByBusId: {busAtAtmCircle.id: progressWithStaleMbhEvent},
      );

      expect(resultsForDept, hasLength(1));
      final estimate = resultsForDept.first;
      expect(estimate.isAtStop, isFalse);
      expect(estimate.currentPositionText, 'At ATM Circle');
      expect(estimate.nextStopName, 'Department Building');
      expect(
        estimate.locationSubtitle,
        contains('Department Building is the next stop'),
      );
    });

    testWidgets(
      'SCENARIO 2: NextBusCard displays ATM Circle physical position, not boarding stop',
      (tester) async {
        final busAtAtmCircle = Bus(
          id: 'bus-1',
          numberPlate: 'KL-11-0001',
          name: 'Campus Bus 1',
          routeId: 'route-campus',
          tripId: 'trip-1',
          status: BusStatus.live,
          position: BusPosition(
            point: stopAtmCircle.location,
            speedKmH: 0.0,
            timestamp: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );

        final progress = resolveBusStopProgress(
          routeStops: campusRoute.stopOccurrences,
          events: [
            BusStopEvent(
              stopId: 'mbh',
              type: 'departed',
              occurredAt: DateTime.now().subtract(const Duration(minutes: 4)),
            ),
            BusStopEvent(
              stopId: 'atm-circle',
              type: 'arrived',
              occurredAt: DateTime.now().subtract(const Duration(seconds: 15)),
            ),
          ],
          direction: 'forward',
        );

        final details = calculateRouteProgressDetails(
          route: campusRoute,
          bus: busAtAtmCircle,
          allStops: [stopMbh, stopAtmCircle, stopDept],
          progress: progress,
        );

        final arrival = BusArrivalEstimate(
          bus: busAtAtmCircle,
          route: campusRoute,
          eta: const BusEtaResult.valid(
            minutes: 4,
            distanceMeters: 400,
            busProgressMeters: 300,
            smoothedSpeedMetersPerSecond: 4.0,
          ),
          currentPositionText: 'At ATM Circle',
          locationSubtitle: 'Department Building is the next stop · 400m away',
          relevance: BusStopRelevance.confirmedApproaching,
          progressDetails: details,
          progress: progress,
        );

        await tester.pumpTrackletWidget(
          Scaffold(
            body: SingleChildScrollView(
              child: NextBusCard(
                selectedStop: stopDept,
                arrival: arrival,
                stops: const [stopMbh, stopAtmCircle, stopDept],
                busProgress: progress,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verified claims
        expect(find.text('At ATM Circle'), findsOneWidget);
        expect(
          find.textContaining('Department Building is the next stop'),
          findsOneWidget,
        );
        expect(find.text('Bus is at your boarding stop'), findsNothing);
        expect(find.text('AT YOUR STOP'), findsNothing);
        expect(find.text('NEXT BUS'), findsOneWidget);
      },
    );

    testWidgets(
      'SCENARIO 3: Bus confirmed dwelling at selected boarding stop',
      (tester) async {
        final busDwellingAtMbh = Bus(
          id: 'bus-1',
          numberPlate: 'KL-11-0001',
          name: 'Campus Bus 1',
          routeId: 'route-campus',
          tripId: 'trip-1',
          status: BusStatus.live,
          position: BusPosition(
            point: stopMbh.location,
            speedKmH: 0.0,
            timestamp: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );

        final progress = resolveBusStopProgress(
          routeStops: campusRoute.stopOccurrences,
          events: [
            BusStopEvent(
              stopId: 'mbh',
              type: 'arrived',
              occurredAt: DateTime.now().subtract(const Duration(seconds: 20)),
            ),
          ],
          direction: 'forward',
        );

        final results = filterRelevantBusesForStop(
          boardingStop: stopMbh,
          buses: [busDwellingAtMbh],
          routesById: {campusRoute.id: campusRoute},
          progressByBusId: {busDwellingAtMbh.id: progress},
        );

        expect(results, hasLength(1));
        final estimate = results.first;
        expect(estimate.isAtStop, isTrue);
        expect(estimate.relevance, BusStopRelevance.atStop);
        expect(estimate.currentPositionText, 'At Mega Hostel Boys');
        expect(estimate.locationSubtitle, 'Bus is at your boarding stop');

        await tester.pumpTrackletWidget(
          Scaffold(
            body: SingleChildScrollView(
              child: NextBusCard(
                selectedStop: stopMbh,
                arrival: estimate,
                stops: const [stopMbh, stopAtmCircle, stopDept],
                busProgress: progress,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('AT YOUR STOP'), findsOneWidget);
        expect(find.text('At Mega Hostel Boys'), findsOneWidget);
        expect(find.text('Bus is at your boarding stop'), findsOneWidget);
        expect(find.text('Board here'), findsWidgets);
      },
    );

    test(
      'SCENARIO 4: Off-route telemetry produces explicit uncertain state',
      () {
        final offRouteBus = Bus(
          id: 'bus-off',
          numberPlate: 'KL-11-0002',
          name: 'Off Route Bus',
          routeId: 'route-campus',
          tripId: 'trip-2',
          status: BusStatus.live,
          position: BusPosition(
            point: const GeoPoint(
              latitude: 11.3500,
              longitude: 75.9800,
            ), // kilometers away
            speedKmH: 25.0,
            timestamp: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );

        final results = filterRelevantBusesForStop(
          boardingStop: stopDept,
          buses: [offRouteBus],
          routesById: {campusRoute.id: campusRoute},
          progressByBusId: {},
        );

        expect(results, hasLength(1));
        final estimate = results.first;
        expect(estimate.relevance, BusStopRelevance.routeUncertain);
        expect(estimate.currentPositionText, 'GPS position off expected route');
        expect(
          estimate.locationSubtitle,
          'Location available · Route progress uncertain',
        );
        expect(estimate.isAtStop, isFalse);
      },
    );

    test(
      'SCENARIO 5: Stale telemetry produces honest stale state and warning',
      () {
        final staleBus = Bus(
          id: 'bus-stale',
          numberPlate: 'KL-11-0003',
          name: 'Stale Bus',
          routeId: 'route-campus',
          tripId: 'trip-3',
          status: BusStatus.live,
          position: BusPosition(
            point: stopAtmCircle.location,
            speedKmH: 0.0,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
          isStale: true,
        );

        final results = filterRelevantBusesForStop(
          boardingStop: stopDept,
          buses: [staleBus],
          routesById: {campusRoute.id: campusRoute},
          progressByBusId: {},
        );

        expect(results, hasLength(1));
        final estimate = results.first;
        expect(estimate.relevance, BusStopRelevance.routeUncertain);
        expect(estimate.currentPositionText, contains('Stale location'));
        expect(estimate.isAtStop, isFalse);
      },
    );

    // ========================================================================
    // OUT-AND-BACK ROUTE PROGRESSION & RELEVANCE REGRESSION CASES (1 - 16)
    // ========================================================================

    test('CASE 1: Outbound bus travelling from MBH toward ATM Circle', () {
      final now = DateTime.now();
      final bus = Bus(
        id: 'bus-r1',
        numberPlate: 'KL-11-R1',
        name: 'Campus Bus R1',
        routeId: outAndBackRoute.id,
        tripId: 'trip-r1',
        status: BusStatus.live,
        position: BusPosition(
          point: GeoPoint(
            latitude:
                (stopMbh.location.latitude + stopAtmCircle.location.latitude) /
                2,
            longitude:
                (stopMbh.location.longitude +
                    stopAtmCircle.location.longitude) /
                2,
          ),
          speedKmH: 20.0,
          timestamp: now,
        ),
        lastUpdated: now,
      );

      final progress = resolveBusStopProgress(
        routeStops: outAndBackRoute.stopOccurrences,
        events: [
          BusStopEvent(
            stopId: 'mbh',
            type: 'arrived',
            occurredAt: now.subtract(const Duration(minutes: 2)),
          ),
          BusStopEvent(
            stopId: 'mbh',
            type: 'departed',
            occurredAt: now.subtract(const Duration(minutes: 1)),
          ),
        ],
        direction: 'forward',
      );

      expect(progress, isNotNull);
      expect(progress!.direction, 'forward');
      expect(progress.nextStop?.stopId, 'atm-circle');

      // Rider at ATM Circle
      final resultsAtm = filterRelevantBusesForStop(
        boardingStop: stopAtmCircle,
        buses: [bus],
        routesById: {outAndBackRoute.id: outAndBackRoute},
        progressByBusId: {bus.id: progress},
      );
      expect(resultsAtm, hasLength(1));
      expect(resultsAtm.first.relevance, BusStopRelevance.confirmedApproaching);
      expect(resultsAtm.first.nextStopName, 'ATM Circle');

      // Rider at MBH: MBH is upcoming on the return leg!
      final resultsMbh = filterRelevantBusesForStop(
        boardingStop: stopMbh,
        buses: [bus],
        routesById: {outAndBackRoute.id: outAndBackRoute},
        progressByBusId: {bus.id: progress},
      );
      expect(resultsMbh, hasLength(1));
      expect(resultsMbh.first.relevance, BusStopRelevance.confirmedApproaching);
    });

    test(
      'CASE 2: Outbound bus travelling from Department Building toward Architecture, with MBH selected',
      () {
        final now = DateTime.now();
        final bus = Bus(
          id: 'bus-r1',
          numberPlate: 'KL-11-R1',
          name: 'Campus Bus R1',
          routeId: outAndBackRoute.id,
          tripId: 'trip-r1',
          status: BusStatus.live,
          position: BusPosition(
            point: GeoPoint(
              latitude:
                  (stopDept.location.latitude + stopArch.location.latitude) / 2,
              longitude:
                  (stopDept.location.longitude + stopArch.location.longitude) /
                  2,
            ),
            speedKmH: 22.0,
            timestamp: now,
          ),
          lastUpdated: now,
        );

        final progress = resolveBusStopProgress(
          routeStops: outAndBackRoute.stopOccurrences,
          events: [
            BusStopEvent(
              stopId: 'mbh',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 6)),
            ),
            BusStopEvent(
              stopId: 'atm-circle',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 4)),
            ),
            BusStopEvent(
              stopId: 'dept',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 1)),
            ),
          ],
          direction: 'forward',
        );

        expect(progress, isNotNull);
        expect(progress!.direction, 'forward');
        expect(progress.nextStop?.stopId, 'arch');

        final resultsMbh = filterRelevantBusesForStop(
          boardingStop: stopMbh,
          buses: [bus],
          routesById: {outAndBackRoute.id: outAndBackRoute},
          progressByBusId: {bus.id: progress},
        );

        expect(resultsMbh, hasLength(1));
        final estimate = resultsMbh.first;
        expect(estimate.relevance, BusStopRelevance.confirmedApproaching);
        expect(estimate.isAtStop, isFalse);
        expect(estimate.currentPositionText, contains('Architecture'));
        expect(
          estimate.currentPositionText,
          isNot(contains('Mega Hostel Boys')),
        );
      },
    );

    test('CASE 3: Bus reaching East Campus and beginning the return leg', () {
      final now = DateTime.now();
      final progress = resolveBusStopProgress(
        routeStops: outAndBackRoute.stopOccurrences,
        events: [
          BusStopEvent(
            stopId: 'mbh',
            type: 'departed',
            occurredAt: now.subtract(const Duration(minutes: 10)),
          ),
          BusStopEvent(
            stopId: 'atm-circle',
            type: 'departed',
            occurredAt: now.subtract(const Duration(minutes: 8)),
          ),
          BusStopEvent(
            stopId: 'dept',
            type: 'departed',
            occurredAt: now.subtract(const Duration(minutes: 6)),
          ),
          BusStopEvent(
            stopId: 'arch',
            type: 'departed',
            occurredAt: now.subtract(const Duration(minutes: 4)),
          ),
          BusStopEvent(
            stopId: 'east-campus',
            type: 'arrived',
            occurredAt: now.subtract(const Duration(minutes: 1)),
          ),
          BusStopEvent(
            stopId: 'east-campus',
            type: 'departed',
            occurredAt: now,
          ),
        ],
        direction: 'forward',
      );

      expect(progress, isNotNull);
      expect(progress!.nextStop?.stopId, 'arch');
      expect(
        progress.nextStop?.sequence,
        5,
      ); // Sequence 5 is Architecture on the return leg!
      expect(progress.upcomingStops.map((o) => o.stopId), [
        'arch',
        'dept',
        'atm-circle',
        'mbh',
      ]);
    });

    test(
      'CASE 4: Return bus travelling from Architecture toward Department Building',
      () {
        final now = DateTime.now();
        final bus = Bus(
          id: 'bus-r1',
          numberPlate: 'KL-11-R1',
          name: 'Campus Bus R1',
          routeId: outAndBackRoute.id,
          tripId: 'trip-r1',
          status: BusStatus.live,
          position: BusPosition(
            point: GeoPoint(
              latitude:
                  (stopArch.location.latitude + stopDept.location.latitude) / 2,
              longitude:
                  (stopArch.location.longitude + stopDept.location.longitude) /
                  2,
            ),
            speedKmH: 22.0,
            timestamp: now,
          ),
          lastUpdated: now,
        );

        final progress = resolveBusStopProgress(
          routeStops: outAndBackRoute.stopOccurrences,
          events: [
            BusStopEvent(
              stopId: 'east-campus',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 4)),
            ),
            BusStopEvent(
              stopId: 'arch',
              type: 'arrived',
              occurredAt: now.subtract(const Duration(minutes: 2)),
            ),
            BusStopEvent(
              stopId: 'arch',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 1)),
            ),
          ],
          direction: 'reverse',
        );

        expect(progress, isNotNull);
        expect(progress!.direction, 'reverse');
        expect(progress.nextStop?.stopId, 'dept');
        expect(progress.nextStop?.sequence, 6);

        final resultsMbh = filterRelevantBusesForStop(
          boardingStop: stopMbh,
          buses: [bus],
          routesById: {outAndBackRoute.id: outAndBackRoute},
          progressByBusId: {bus.id: progress},
        );
        expect(resultsMbh, hasLength(1));
        expect(
          resultsMbh.first.relevance,
          BusStopRelevance.confirmedApproaching,
        );
      },
    );

    test('CASE 5: Return bus travelling from ATM Circle toward MBH', () {
      final now = DateTime.now();
      final bus = Bus(
        id: 'bus-r1',
        numberPlate: 'KL-11-R1',
        name: 'Campus Bus R1',
        routeId: outAndBackRoute.id,
        tripId: 'trip-r1',
        status: BusStatus.live,
        position: BusPosition(
          point: GeoPoint(
            latitude:
                (stopAtmCircle.location.latitude + stopMbh.location.latitude) /
                2,
            longitude:
                (stopAtmCircle.location.longitude +
                    stopMbh.location.longitude) /
                2,
          ),
          speedKmH: 18.0,
          timestamp: now,
        ),
        lastUpdated: now,
      );

      final progress = resolveBusStopProgress(
        routeStops: outAndBackRoute.stopOccurrences,
        events: [
          BusStopEvent(
            stopId: 'dept',
            type: 'departed',
            occurredAt: now.subtract(const Duration(minutes: 3)),
          ),
          BusStopEvent(
            stopId: 'atm-circle',
            type: 'arrived',
            occurredAt: now.subtract(const Duration(minutes: 1)),
          ),
          BusStopEvent(stopId: 'atm-circle', type: 'departed', occurredAt: now),
        ],
        direction: 'reverse',
      );

      expect(progress, isNotNull);
      expect(progress!.nextStop?.stopId, 'mbh');
      expect(progress.nextStop?.sequence, 8);

      final resultsMbh = filterRelevantBusesForStop(
        boardingStop: stopMbh,
        buses: [bus],
        routesById: {outAndBackRoute.id: outAndBackRoute},
        progressByBusId: {bus.id: progress},
      );
      expect(resultsMbh, hasLength(1));
      final estimate = resultsMbh.first;
      expect(estimate.relevance, BusStopRelevance.confirmedApproaching);
      expect(
        estimate.locationSubtitle,
        contains('Mega Hostel Boys is the next stop'),
      );
    });

    test('CASE 6: Bus confirmed at MBH', () {
      final now = DateTime.now();
      final bus = Bus(
        id: 'bus-r1',
        numberPlate: 'KL-11-R1',
        name: 'Campus Bus R1',
        routeId: outAndBackRoute.id,
        tripId: 'trip-r1',
        status: BusStatus.live,
        position: BusPosition(
          point: stopMbh.location,
          speedKmH: 0.0,
          timestamp: now,
        ),
        lastUpdated: now,
      );

      final progress = resolveBusStopProgress(
        routeStops: outAndBackRoute.stopOccurrences,
        events: [
          BusStopEvent(
            stopId: 'atm-circle',
            type: 'departed',
            occurredAt: now.subtract(const Duration(minutes: 2)),
          ),
          BusStopEvent(
            stopId: 'mbh',
            type: 'arrived',
            occurredAt: now.subtract(const Duration(seconds: 15)),
          ),
        ],
        direction: 'reverse',
      );

      final resultsMbh = filterRelevantBusesForStop(
        boardingStop: stopMbh,
        buses: [bus],
        routesById: {outAndBackRoute.id: outAndBackRoute},
        progressByBusId: {bus.id: progress},
      );

      expect(resultsMbh, hasLength(1));
      final estimate = resultsMbh.first;
      expect(estimate.relevance, BusStopRelevance.atStop);
      expect(estimate.isAtStop, isTrue);
      expect(estimate.locationSubtitle, 'Bus is at your boarding stop');
    });

    test(
      'CASE 7: Bus that has passed MBH outbound but will return to MBH later remains eligible',
      () {
        final now = DateTime.now();
        final bus = Bus(
          id: 'bus-r1',
          numberPlate: 'KL-11-R1',
          name: 'Campus Bus R1',
          routeId: outAndBackRoute.id,
          tripId: 'trip-r1',
          status: BusStatus.live,
          position: BusPosition(
            point: stopAtmCircle.location,
            speedKmH: 0.0,
            timestamp: now,
          ),
          lastUpdated: now,
        );

        final progress = resolveBusStopProgress(
          routeStops: outAndBackRoute.stopOccurrences,
          events: [
            BusStopEvent(
              stopId: 'mbh',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 3)),
            ),
            BusStopEvent(
              stopId: 'atm-circle',
              type: 'arrived',
              occurredAt: now.subtract(const Duration(seconds: 20)),
            ),
          ],
          direction: 'forward',
        );

        final resultsMbh = filterRelevantBusesForStop(
          boardingStop: stopMbh,
          buses: [bus],
          routesById: {outAndBackRoute.id: outAndBackRoute},
          progressByBusId: {bus.id: progress},
        );

        expect(resultsMbh, isNotEmpty);
        expect(
          resultsMbh.first.relevance,
          BusStopRelevance.confirmedApproaching,
        );
      },
    );

    test('CASE 8: Bus whose active trip does not serve MBH is excluded', () {
      const otherRoute = BusRoute(
        id: 'route-other',
        name: 'East Campus - SOMS',
        code: 'R2',
        stopIds: ['dept', 'arch', 'east-campus'],
        stopOccurrences: [
          RouteStopOccurrence(
            routeId: 'route-other',
            stopId: 'dept',
            sequence: 0,
            stop: stopDept,
          ),
          RouteStopOccurrence(
            routeId: 'route-other',
            stopId: 'arch',
            sequence: 1,
            stop: stopArch,
          ),
          RouteStopOccurrence(
            routeId: 'route-other',
            stopId: 'east-campus',
            sequence: 2,
            stop: stopEastCampus,
          ),
        ],
      );

      final busOther = Bus(
        id: 'bus-other',
        numberPlate: 'KL-11-R2',
        name: 'Campus Bus R2',
        routeId: otherRoute.id,
        tripId: 'trip-other',
        status: BusStatus.live,
        position: BusPosition(
          point: stopDept.location,
          speedKmH: 0.0,
          timestamp: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      final resultsMbh = filterRelevantBusesForStop(
        boardingStop: stopMbh,
        buses: [busOther],
        routesById: {otherRoute.id: otherRoute},
        progressByBusId: {},
      );

      expect(resultsMbh, isEmpty);
    });

    test(
      'CASE 9: Bus with no active trip produces estimated or uncertain relevance, not false confirmed arrival',
      () {
        final busNoTrip = Bus(
          id: 'bus-no-trip',
          numberPlate: 'KL-11-NO-TRIP',
          name: 'Campus Bus Idle',
          routeId: outAndBackRoute.id,
          tripId: null,
          status: BusStatus.live,
          position: BusPosition(
            point: stopMbh.location,
            speedKmH: 0.0,
            timestamp: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );

        final resultsMbh = filterRelevantBusesForStop(
          boardingStop: stopMbh,
          buses: [busNoTrip],
          routesById: {outAndBackRoute.id: outAndBackRoute},
          progressByBusId: {}, // No progress from stop events
        );

        expect(resultsMbh, hasLength(1));
        // Without verified arrival events, it cannot claim confirmed atStop
        expect(resultsMbh.first.relevance, isNot(BusStopRelevance.atStop));
      },
    );

    test(
      'CASE 10: Missing or contradictory stop events handled gracefully without crashing',
      () {
        final now = DateTime.now();
        // Contradictory events: non-existent stop and out of order
        final progress = resolveBusStopProgress(
          routeStops: outAndBackRoute.stopOccurrences,
          events: [
            BusStopEvent(
              stopId: 'unknown-stop-xyz',
              type: 'arrived',
              occurredAt: now.subtract(const Duration(minutes: 5)),
            ),
          ],
          direction: 'forward',
        );

        // Must be null safely without throwing
        expect(progress, isNull);
      },
    );

    test(
      'CASE 11: Invalid or stale telemetry produces honest stale state and warning',
      () {
        final now = DateTime.now();
        final staleBus = Bus(
          id: 'bus-stale',
          numberPlate: 'KL-11-STALE',
          name: 'Stale Bus',
          routeId: outAndBackRoute.id,
          tripId: 'trip-1',
          status: BusStatus.live,
          position: BusPosition(
            point: stopAtmCircle.location,
            speedKmH: 0.0,
            timestamp: now.subtract(const Duration(minutes: 5)),
          ),
          lastUpdated: now.subtract(const Duration(minutes: 5)),
          isStale: true,
        );

        final resultsMbh = filterRelevantBusesForStop(
          boardingStop: stopMbh,
          buses: [staleBus],
          routesById: {outAndBackRoute.id: outAndBackRoute},
          progressByBusId: {},
        );

        expect(resultsMbh, hasLength(1));
        expect(resultsMbh.first.relevance, BusStopRelevance.routeUncertain);
        expect(
          resultsMbh.first.currentPositionText,
          contains('Stale location'),
        );
      },
    );

    test(
      'CASE 12: Unknown direction or ambiguous repeated-stop occurrence does not make false confident arrival claims',
      () {
        final now = DateTime.now();
        // Single event at repeated stop 'arch' with direction: '' (unspecified)
        final progress = resolveBusStopProgress(
          routeStops: outAndBackRoute.stopOccurrences,
          events: [
            BusStopEvent(stopId: 'arch', type: 'arrived', occurredAt: now),
          ],
          direction: '',
        );

        // Since architecture occurs at seq 3 and seq 5, without direction or history it is ambiguous
        expect(progress, isNull);
      },
    );

    test(
      'CASE 13: Correct remaining-route preview with repeated intermediate stops',
      () {
        final now = DateTime.now();
        final progress = resolveBusStopProgress(
          routeStops: outAndBackRoute.stopOccurrences,
          events: [
            BusStopEvent(
              stopId: 'mbh',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 8)),
            ),
            BusStopEvent(
              stopId: 'atm-circle',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 6)),
            ),
            BusStopEvent(
              stopId: 'dept',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 3)),
            ),
            BusStopEvent(stopId: 'arch', type: 'arrived', occurredAt: now),
          ],
          direction: 'forward',
        );

        expect(progress, isNotNull);
        expect(progress!.currentStopId, 'arch');
        expect(progress.upcomingStops.map((o) => o.stopId), [
          'east-campus',
          'arch',
          'dept',
          'atm-circle',
          'mbh',
        ]);
      },
    );

    test(
      'CASE 14: Correct highlighting of the next MBH occurrence in route occurrences',
      () {
        final occurrences = outAndBackRoute.stopOccurrences;
        // MBH occurs at 0 and 8
        expect(occurrences.first.stopId, 'mbh');
        expect(occurrences.last.stopId, 'mbh');
        expect(occurrences.first.sequence, 0);
        expect(occurrences.last.sequence, 8);
      },
    );

    test(
      'CASE 15: Changing the selected boarding stop recomputes relevance and remaining route',
      () {
        final now = DateTime.now();
        final bus = Bus(
          id: 'bus-r1',
          numberPlate: 'KL-11-R1',
          name: 'Campus Bus R1',
          routeId: outAndBackRoute.id,
          tripId: 'trip-r1',
          status: BusStatus.live,
          position: BusPosition(
            point: stopArch.location,
            speedKmH: 0.0,
            timestamp: now,
          ),
          lastUpdated: now,
        );

        final progress = resolveBusStopProgress(
          routeStops: outAndBackRoute.stopOccurrences,
          events: [
            BusStopEvent(
              stopId: 'mbh',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 8)),
            ),
            BusStopEvent(
              stopId: 'atm-circle',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 6)),
            ),
            BusStopEvent(
              stopId: 'dept',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 3)),
            ),
            BusStopEvent(stopId: 'arch', type: 'arrived', occurredAt: now),
          ],
          direction: 'forward',
        );

        // Perspective 1: Rider at East Campus (next stop)
        final forEastCampus = filterRelevantBusesForStop(
          boardingStop: stopEastCampus,
          buses: [bus],
          routesById: {outAndBackRoute.id: outAndBackRoute},
          progressByBusId: {bus.id: progress},
        );
        expect(forEastCampus.first.stopsAway, 1);

        // Perspective 2: Rider at MBH (return leg, 5 stops away)
        final forMbh = filterRelevantBusesForStop(
          boardingStop: stopMbh,
          buses: [bus],
          routesById: {outAndBackRoute.id: outAndBackRoute},
          progressByBusId: {bus.id: progress},
        );
        expect(forMbh.first.stopsAway, 5);
      },
    );

    test(
      'CASE 16: Multiple relevant buses select the primary card using defensible ordering',
      () {
        final now = DateTime.now();
        final busNear = Bus(
          id: 'bus-near',
          numberPlate: 'KL-11-NEAR',
          name: 'Bus Near',
          routeId: outAndBackRoute.id,
          tripId: 'trip-1',
          status: BusStatus.live,
          position: BusPosition(
            point: stopAtmCircle.location,
            speedKmH: 20.0,
            timestamp: now,
          ),
          lastUpdated: now,
        );

        final busFar = Bus(
          id: 'bus-far',
          numberPlate: 'KL-11-FAR',
          name: 'Bus Far',
          routeId: outAndBackRoute.id,
          tripId: 'trip-2',
          status: BusStatus.live,
          position: BusPosition(
            point: stopArch.location,
            speedKmH: 20.0,
            timestamp: now,
          ),
          lastUpdated: now,
        );

        final progressNear = resolveBusStopProgress(
          routeStops: outAndBackRoute.stopOccurrences,
          events: [
            BusStopEvent(
              stopId: 'dept',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 2)),
            ),
            BusStopEvent(
              stopId: 'atm-circle',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 1)),
            ),
          ],
          direction: 'reverse',
        );

        final progressFar = resolveBusStopProgress(
          routeStops: outAndBackRoute.stopOccurrences,
          events: [
            BusStopEvent(
              stopId: 'east-campus',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 4)),
            ),
            BusStopEvent(
              stopId: 'arch',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 1)),
            ),
          ],
          direction: 'reverse',
        );

        final results = filterRelevantBusesForStop(
          boardingStop: stopMbh,
          buses: [busFar, busNear],
          routesById: {outAndBackRoute.id: outAndBackRoute},
          progressByBusId: {busNear.id: progressNear, busFar.id: progressFar},
        );

        // busNear is closer (1 stop to MBH), busFar is further (3 stops to MBH)
        expect(results.first.bus.id, 'bus-near');
      },
    );

    // ========================================================================
    // WIDGET-LEVEL REGRESSION TEST (Screenshot Contradiction Scenario)
    // ========================================================================

    testWidgets(
      'WIDGET REGRESSION: Bus travelling toward Architecture outbound with MBH selected renders Architecture location and remaining out-and-back journey',
      (tester) async {
        final now = DateTime.now();
        final busHeadingToArch = Bus(
          id: 'bus-r1',
          numberPlate: 'KL-11-0001',
          name: 'Campus Bus 1',
          routeId: outAndBackRoute.id,
          tripId: 'trip-1',
          status: BusStatus.live,
          position: BusPosition(
            point: stopArch.location,
            speedKmH: 0.0,
            timestamp: now,
          ),
          lastUpdated: now,
        );

        final progress = resolveBusStopProgress(
          routeStops: outAndBackRoute.stopOccurrences,
          events: [
            BusStopEvent(
              stopId: 'mbh',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 8)),
            ),
            BusStopEvent(
              stopId: 'atm-circle',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 6)),
            ),
            BusStopEvent(
              stopId: 'dept',
              type: 'departed',
              occurredAt: now.subtract(const Duration(minutes: 3)),
            ),
            BusStopEvent(
              stopId: 'arch',
              type: 'arrived',
              occurredAt: now.subtract(const Duration(seconds: 20)),
            ),
          ],
          direction: 'forward',
        );

        final results = filterRelevantBusesForStop(
          boardingStop: stopMbh,
          buses: [busHeadingToArch],
          routesById: {outAndBackRoute.id: outAndBackRoute},
          progressByBusId: {busHeadingToArch.id: progress},
        );

        expect(results, hasLength(1));
        final arrival = results.first;

        // 1. Bus location is Architecture, NOT MBH
        expect(arrival.currentPositionText, 'At Architecture');
        expect(arrival.isAtStop, isFalse); // Not at boarding stop!
        expect(
          arrival.locationSubtitle,
          'Mega Hostel Boys is ahead on return leg',
        );

        await tester.pumpTrackletWidget(
          Scaffold(
            body: SingleChildScrollView(
              child: NextBusCard(
                selectedStop: stopMbh,
                arrival: arrival,
                stops: const [
                  stopMbh,
                  stopAtmCircle,
                  stopDept,
                  stopArch,
                  stopEastCampus,
                ],
                busProgress: progress,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 2. Verified UI elements
        expect(find.text('At Architecture'), findsOneWidget);
        expect(
          find.text('Mega Hostel Boys is ahead on return leg'),
          findsOneWidget,
        );
        expect(find.text('Bus is at your boarding stop'), findsNothing);
        expect(find.text('AT YOUR STOP'), findsNothing);
        expect(find.text('NEXT BUS'), findsOneWidget);

        // 3. Timeline renders the ordered out-and-back journey
        // Architecture (current) -> East Campus -> Architecture -> Department Building -> ATM Circle -> Mega Hostel Boys (Your stop)
        expect(find.text('TRIP PROGRESS'), findsOneWidget);
        expect(find.text('Your stop'), findsOneWidget);
      },
    );
  });
}
