import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_eta.dart';
import 'package:tracklet/data/transit/bus_position.dart';
import 'package:tracklet/data/transit/bus_stop_event.dart';
import 'package:tracklet/data/transit/bus_stop_progress.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/route_stop_occurrence.dart';
import 'package:tracklet/data/transit/scheduled_departure.dart';
import 'package:tracklet/data/transit/stop.dart';
import 'package:tracklet/data/transit/transit_repository.dart';
import 'package:tracklet/features/home/home_screen.dart';
import 'package:tracklet/features/home/home_transit_logic.dart';

import 'package:tracklet/features/home/widgets/live_bus_route_preview.dart';
import 'package:tracklet/features/home/widgets/next_bus_card.dart';
import 'package:tracklet/features/home/widgets/next_buses_card.dart';
import 'package:tracklet/services/location/location_service.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders campus routes and honest empty telemetry states', (
      tester,
    ) async {
      await _pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.text('Tracklet'), findsOneWidget);
      expect(find.text('NIT Calicut'), findsOneWidget);
      expect(find.text('BOARDING STOP'), findsOneWidget);
      expect(find.text('Main Gate'), findsWidgets);
      expect(find.text('Choose a stop near you'), findsOneWidget);
      expect(
        find.text('Turn on location to find your nearest stop'),
        findsOneWidget,
      );
      expect(find.text('Locate'), findsOneWidget);
      expect(find.text('No buses approaching this stop'), findsOneWidget);
      expect(find.text('Change stop'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
    });

    testWidgets(
      'shows an empty state when no transit data source is configured',
      (tester) async {
        await tester.pumpTrackletWidget(
          const HomeScreen(),
          overrides: [
            transitRepositoryProvider.overrideWithValue(
              SupabaseTransitRepository(null),
            ),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.text('Campus transit unavailable'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.text('Main Gate'), findsNothing);
        expect(find.byType(NextBusCard), findsNothing);
      },
    );

    testWidgets('shows the closest stop and walking estimate from location', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        overrides: [
          locationStateProvider.overrideWith(
            () => _FixedLocationNotifier(
              const GeoPoint(latitude: 11.323028, longitude: 75.936722),
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('BOARDING STOP'), findsOneWidget);
      expect(find.text('Architecture'), findsWidgets);
      expect(find.textContaining('0 m away'), findsOneWidget);
      expect(find.textContaining('1 min'), findsOneWidget);
      expect(
        find.text('Automatically selected using your location'),
        findsOneWidget,
      );
      expect(find.text('Locate'), findsNothing);
    });

    testWidgets('keeps GPS visible when stop events are unavailable', (
      tester,
    ) async {
      final bus = Bus(
        id: 'live-bus',
        numberPlate: 'NITC-1',
        name: 'Campus Bus',
        routeId: 'route-test',
        tripId: 'trip-live',
        status: BusStatus.live,
        position: BusPosition(
          point: _homeTestStops.first.location,
          speedKmH: 6,
          timestamp: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );
      await tester.pumpTrackletWidget(
        const HomeScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(
            _HomeTestTransitRepository(buses: [bus]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('BUS ON ROUTE'), findsOneWidget);
      expect(find.text('ETA'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.textContaining('Updated'), findsOneWidget);
      expect(find.text('Track bus'), findsOneWidget);
    });

    testWidgets('shows ETA when event progress resolves the boarding stop', (
      tester,
    ) async {
      final now = DateTime.now();
      final route = BusRoute(
        id: 'route-test',
        name: 'Main Gate to Architecture',
        code: 'R1',
        path: [_homeTestStops.first.location, _homeTestStops.last.location],
        stopIds: const ['main-gate', 'architecture'],
        stopOccurrences: [
          RouteStopOccurrence(
            routeId: 'route-test',
            stopId: 'main-gate',
            sequence: 0,
            stop: _homeTestStops.first,
          ),
          RouteStopOccurrence(
            routeId: 'route-test',
            stopId: 'architecture',
            sequence: 1,
            stop: _homeTestStops.last,
          ),
        ],
      );
      final bus = Bus(
        id: 'live-bus',
        numberPlate: 'NITC-1',
        name: 'Campus Bus',
        routeId: route.id,
        tripId: 'trip-live',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.3215555, longitude: 75.934722),
          speedKmH: 18,
          timestamp: now,
        ),
        lastUpdated: now,
      );
      final repository = _HomeTestTransitRepository(
        buses: [bus],
        routes: [route],
        stopEvents: [
          BusStopEvent(
            stopId: 'main-gate',
            type: 'arrived',
            occurredAt: now.subtract(const Duration(minutes: 3)),
          ),
          BusStopEvent(
            stopId: 'main-gate',
            type: 'departed',
            occurredAt: now.subtract(const Duration(minutes: 2)),
          ),
        ],
      );

      await tester.pumpTrackletWidget(
        const HomeScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(repository),
          locationStateProvider.overrideWith(
            () => _FixedLocationNotifier(_homeTestStops.last.location),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('NEXT BUS'), findsOneWidget);
      expect(find.text('MIN'), findsOneWidget);
      expect(find.textContaining('En route to Architecture'), findsOneWidget);
      expect(find.text('Track bus'), findsOneWidget);
    });

    testWidgets('hides campus walking estimates for a distant location', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        overrides: [
          locationStateProvider.overrideWith(
            () => _FixedLocationNotifier(
              const GeoPoint(latitude: 40.7128, longitude: -74.006),
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Default boarding stop'), findsOneWidget);
      expect(
        find.text('Location is outside the campus service area'),
        findsOneWidget,
      );
      expect(find.textContaining('away'), findsNothing);
      expect(find.textContaining('walk'), findsNothing);
    });

    testWidgets(
      'Change button opens stop selector sheet to pick a boarding stop',
      (tester) async {
        await _pumpHome(tester);
        await tester.pumpAndSettle();

        final changeButton = find.widgetWithText(TextButton, 'Change');
        expect(changeButton, findsOneWidget);
        expect(tester.getSize(changeButton).height, greaterThanOrEqualTo(48));
        await tester.tap(changeButton);
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Architecture');
        await tester.pumpAndSettle();

        expect(find.text('Architecture'), findsWidgets);
        await tester.tap(find.text('Architecture').last);
        await tester.pumpAndSettle();

        expect(find.text('Architecture'), findsWidgets);
        expect(find.text('Selected manually'), findsOneWidget);
      },
    );

    testWidgets(
      'tracker highlights the closest served stop for an unmatched destination',
      (tester) async {
        const boardingStop = Stop(
          id: 'boarding',
          name: 'Main Gate',
          code: 'MG',
          location: GeoPoint(latitude: 0, longitude: 0),
        );
        const routeStop = Stop(
          id: 'route-stop',
          name: 'Lecture Hall',
          code: 'LH',
          location: GeoPoint(latitude: 0, longitude: 0.02),
        );
        const searchedStop = Stop(
          id: 'searched',
          name: 'East Gate',
          code: 'EG',
          location: GeoPoint(latitude: 0, longitude: 0.021),
        );
        const route = BusRoute(
          id: 'route',
          name: 'Campus Loop',
          code: 'CL-1',
          stopIds: ['boarding', 'route-stop'],
        );

        await tester.pumpTrackletWidget(
          const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: LiveBusRoutePreview(
                route: route,
                stop: boardingStop,
                stops: [boardingStop, routeStop, searchedStop],
                bus: null,
                destinationStop: searchedStop,
              ),
            ),
          ),
        );

        expect(
          find.text('Estimated closest route stop to East Gate: Lecture Hall'),
          findsOneWidget,
        );
        expect(find.text('Upcoming'), findsWidgets);
        expect(find.text('Next stop'), findsNothing);
      },
    );

    testWidgets('route tracker shows every stop through the loop ending', (
      tester,
    ) async {
      const mainGate = Stop(
        id: 'main-gate',
        name: 'Main Gate',
        location: GeoPoint(latitude: 0, longitude: 0),
      );
      const centerCircle = Stop(
        id: 'center-circle',
        name: 'Center Circle',
        location: GeoPoint(latitude: 0, longitude: 0.01),
      );
      const architecture = Stop(
        id: 'architecture',
        name: 'Architecture',
        location: GeoPoint(latitude: 0, longitude: 0.02),
      );
      const route = BusRoute(
        id: 'loop',
        name: 'Campus Loop',
        code: 'CL-1',
        stopIds: [
          'main-gate',
          'center-circle',
          'architecture',
          'center-circle',
          'main-gate',
        ],
      );

      await tester.pumpTrackletWidget(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: LiveBusRoutePreview(
              route: route,
              stop: centerCircle,
              stops: [architecture, mainGate, centerCircle],
              bus: null,
            ),
          ),
        ),
      );

      expect(find.text('Earlier stop'), findsNWidgets(2));
      expect(find.text('Board here'), findsOneWidget);
      expect(find.text('Upcoming'), findsNWidgets(3));
      expect(find.text('Center Circle'), findsNWidgets(3));
      expect(find.text('Main Gate'), findsNWidgets(2));
      expect(find.text('Architecture'), findsOneWidget);

      final secondLastStopX =
          tester.getCenter(find.text('Center Circle').at(0)).dx;
      final lastStopX = tester.getCenter(find.text('Main Gate').at(0)).dx;
      final boardingStopX =
          tester.getCenter(find.text('Center Circle').at(1)).dx;
      final firstNextStopX =
          tester.getCenter(find.text('Architecture').at(0)).dx;
      final repeatedNextStopX =
          tester.getCenter(find.text('Center Circle').at(2)).dx;
      final finalStopX = tester.getCenter(find.text('Main Gate').at(1)).dx;
      expect(secondLastStopX, lessThan(lastStopX));
      expect(lastStopX, lessThan(boardingStopX));
      expect(boardingStopX, lessThan(firstNextStopX));
      expect(firstNextStopX, lessThan(repeatedNextStopX));
      expect(repeatedNextStopX, lessThan(finalStopX));
    });

    testWidgets('tracker separates the bus position from the boarding stop', (
      tester,
    ) async {
      const boarding = Stop(
        id: 'boarding',
        name: 'Boarding Stop',
        location: GeoPoint(latitude: 0, longitude: 0),
      );
      const current = Stop(
        id: 'current',
        name: 'East Campus',
        location: GeoPoint(latitude: 0, longitude: 0.01),
      );
      const route = BusRoute(
        id: 'route',
        name: 'Campus Loop',
        code: 'R1',
        stopIds: ['current', 'boarding'],
      );
      final progress = resolveBusStopProgress(
        routeStops: const [
          RouteStopOccurrence(routeId: 'route', stopId: 'current', sequence: 0),
          RouteStopOccurrence(
            routeId: 'route',
            stopId: 'boarding',
            sequence: 1,
          ),
        ],
        events: [
          BusStopEvent(
            stopId: 'current',
            type: 'arrived',
            occurredAt: DateTime(2026),
          ),
        ],
        direction: 'forward',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: LiveBusRoutePreview(
                route: route,
                stop: boarding,
                stops: const [boarding, current],
                bus: null,
                progress: progress,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Bus here'), findsWidgets);
      expect(find.text('Board here'), findsOneWidget);
    });

    testWidgets(
      'next ride separates unavailable ETA, stale status and action',
      (tester) async {
        const stop = Stop(
          id: 'main-gate',
          name: 'Main Gate',
          location: GeoPoint(latitude: 0, longitude: 0),
        );
        const route = BusRoute(
          id: 'route',
          name: 'Campus Loop',
          code: 'R1',
          stopIds: ['main-gate'],
        );
        final bus = Bus(
          id: 'bus',
          name: 'Campus Bus',
          numberPlate: 'KL-00-0000',
          routeId: 'route',
          status: BusStatus.live,
          isStale: true,
          position: BusPosition(
            point: const GeoPoint(latitude: 0, longitude: 0.01),
            speedKmH: 6,
            timestamp: DateTime(2026),
          ),
          lastUpdated: DateTime(2026),
        );
        var tracked = false;
        await tester.pumpTrackletWidget(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: NextBusCard(
                selectedStop: stop,
                arrival: BusArrivalEstimate(
                  bus: bus,
                  route: route,
                  eta: const BusEtaResult.unavailable(
                    BusEtaStatus.staleTelemetry,
                  ),
                ),
                routePreview: const SizedBox.shrink(),
                busLocationHint: 'East Campus',
                onTrackPressed: () => tracked = true,
              ),
            ),
          ),
        );
        expect(find.text('LAST KNOWN BUS'), findsOneWidget);
        expect(find.text('Stale'), findsOneWidget);
        expect(find.text('ETA'), findsOneWidget);
        expect(find.text('Unavailable'), findsOneWidget);
        expect(find.textContaining('Updated'), findsOneWidget);
        expect(find.text('Track bus'), findsOneWidget);
        expect(find.textContaining('Near East Campus'), findsOneWidget);
        await tester.tap(find.text('Track bus'));
        expect(tracked, isTrue);
      },
    );

    testWidgets('shows a numeric ETA only for a valid along-route result', (
      tester,
    ) async {
      const stop = Stop(
        id: 'main-gate',
        name: 'Main Gate',
        location: GeoPoint(latitude: 11.32, longitude: 75.93),
      );
      const route = BusRoute(
        id: 'route',
        name: 'Campus Loop',
        code: 'R1',
        stopIds: ['main-gate'],
      );
      final bus = Bus(
        id: 'bus',
        name: 'Campus Bus',
        numberPlate: 'KL-00-0000',
        routeId: 'route',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 0, longitude: 0.01),
          speedKmH: 6,
          timestamp: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );
      await tester.pumpTrackletWidget(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: NextBusCard(
              selectedStop: stop,
              arrival: BusArrivalEstimate(
                bus: bus,
                route: route,
                eta: const BusEtaResult.valid(
                  minutes: 6,
                  distanceMeters: 500,
                  busProgressMeters: 100,
                  smoothedSpeedMetersPerSecond: 4,
                ),
              ),
              routePreview: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      expect(find.text('NEXT BUS'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('MIN'), findsOneWidget);
    });

    testWidgets('homepage adapts to narrow, standard and landscape screens', (
      tester,
    ) async {
      for (final size in [
        const Size(320, 568),
        const Size(390, 844),
        const Size(844, 390),
      ]) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        await tester.pumpTrackletWidget(
          MediaQuery(
            data: MediaQueryData(
              size: size,
              devicePixelRatio: 1,
              textScaler: const TextScaler.linear(1.3),
              disableAnimations: true,
            ),
            child: const HomeScreen(),
          ),
          overrides: [
            transitRepositoryProvider.overrideWithValue(
              _HomeTestTransitRepository(),
            ),
          ],
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'layout at $size');
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets(
      'scheduled next bus card and list display timetable departures',
      (tester) async {
        const scheduledStop = Stop(
          id: 'stop-a',
          name: 'Main Gate',
          location: GeoPoint(latitude: 11.32, longitude: 75.93),
        );
        const scheduledRoute = BusRoute(
          id: 'route-a',
          name: 'Main Gate → East Campus (Bus 1)',
          code: 'Bus 1',
          stopIds: ['stop-a'],
        );
        const departure = ScheduledDeparture(
          id: 'timing-a',
          routeId: 'route-a',
          hour: 9,
          minute: 10,
        );

        await tester.pumpTrackletWidget(
          Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                NextBusCard(
                  selectedStop: scheduledStop,
                  arrival: null,
                  scheduledDeparture: departure,
                  scheduledRoute: scheduledRoute,
                  routePreview: SizedBox.shrink(),
                ),
                SizedBox(height: 20),
                NextBusesCard(
                  stopName: 'Main Gate',
                  scheduledDepartures: [departure],
                  routes: [scheduledRoute],
                ),
              ],
            ),
          ),
        );

        expect(find.text('NEXT SCHEDULED BUS'), findsOneWidget);
        expect(find.text('9:10 AM'), findsNWidgets(2));
        expect(find.text('Scheduled route departure'), findsOneWidget);
        expect(
          find.text('Scheduled departure · live location unavailable'),
          findsOneWidget,
        );
        expect(find.text('Main Gate → East Campus (Bus 1)'), findsNWidgets(2));
      },
    );

    testWidgets('empty bus list shows a clear empty state, not sample routes', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: NextBusesCard(stopName: 'Main Gate'),
          ),
        ),
      );

      expect(
        find.text('No more scheduled departures for this service period.'),
        findsOneWidget,
      );
      expect(find.text('Kozhikode City'), findsNothing);
      expect(find.text('Kuttipuram'), findsNothing);
    });

    testWidgets('limits Next Buses list items to at most 4 items', (
      tester,
    ) async {
      final manyDepartures = List.generate(
        8,
        (i) => ScheduledDeparture(
          id: 'dep-$i',
          routeId: 'r1',
          hour: i + 1,
          minute: 0,
        ),
      );
      const testRoute = BusRoute(
        id: 'r1',
        name: 'Route 1',
        code: 'R1',
        stopIds: ['stop-mg'],
      );

      await tester.pumpTrackletWidget(
        Scaffold(
          body: SingleChildScrollView(
            child: NextBusesCard(
              stopName: 'Main Gate',
              scheduledDepartures: manyDepartures,
              routes: const [testRoute],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Route 1'), findsNWidgets(4));
    });

    testWidgets('opens drawer on tapping hamburger icon', (tester) async {
      await _pumpHome(tester);
      await tester.pumpAndSettle();

      final menuIcon = find.byIcon(Icons.menu_rounded);
      expect(menuIcon, findsOneWidget);

      await tester.tap(menuIcon);
      await tester.pumpAndSettle();

      expect(find.text('Account Options'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Report Errors/Bugs'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  List<dynamic> overrides = const [],
}) {
  return tester.pumpTrackletWidget(
    const HomeScreen(),
    overrides: [
      transitRepositoryProvider.overrideWithValue(_HomeTestTransitRepository()),
      ...overrides,
    ],
  );
}

const _homeTestStops = <Stop>[
  Stop(
    id: 'main-gate',
    sourceStopId: 'main_gate',
    name: 'Main Gate',
    code: 'MG',
    location: GeoPoint(latitude: 11.320083, longitude: 75.932722),
    walkingTimeMinutes: 2,
  ),
  Stop(
    id: 'architecture',
    sourceStopId: 'architecture',
    name: 'Architecture',
    code: 'ARC',
    location: GeoPoint(latitude: 11.323028, longitude: 75.936722),
  ),
];

const _homeTestRoutes = <BusRoute>[
  BusRoute(
    id: 'route-test',
    name: 'Main Gate to Architecture',
    code: 'R1',
    stopIds: ['main-gate', 'architecture'],
  ),
];

class _HomeTestTransitRepository implements TransitRepository {
  _HomeTestTransitRepository({
    this.buses = const [],
    this.routes = _homeTestRoutes,
    this.stopEvents = const [],
  });

  final List<Bus> buses;
  final List<BusRoute> routes;
  final List<BusStopEvent> stopEvents;

  @override
  Future<List<BusRoute>> getRoutes({List<Stop>? knownStops}) async => routes;

  @override
  Future<List<Stop>> getStops() async => _homeTestStops;

  @override
  Future<List<RouteStopOccurrence>> getRouteStops(String routeId) async =>
      const [];

  @override
  Future<List<Bus>> getActiveBuses() async => buses;

  @override
  Future<List<ScheduledDeparture>> getScheduledDepartures() async => const [];

  @override
  Stream<List<Bus>> watchActiveBuses() => Stream.value(buses);

  @override
  Future<Stop?> getNearestStop(GeoPoint userLocation) async =>
      _homeTestStops.first;

  @override
  Future<Bus?> getBusById(String busId) async => null;
  @override
  Future<List<BusStopEvent>> getBusStopEvents(String tripId) async =>
      stopEvents;
}

class _FixedLocationNotifier extends LocationNotifier {
  _FixedLocationNotifier(this.location);

  final GeoPoint location;

  @override
  LocationState build() => LocationState(
    currentLocation: location,
    permissionState: LocationPermissionState.granted,
  );

  @override
  Future<void> refreshLocationIfPermitted() async {}
}
