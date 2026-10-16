import 'package:flutter_test/flutter_test.dart';

import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/bus_stop_event.dart';
import 'package:tracklet/data/transit/route_stop_occurrence.dart';
import 'package:tracklet/data/transit/scheduled_departure.dart';
import 'package:tracklet/data/transit/stop.dart';
import 'package:tracklet/data/transit/transit_repository.dart';
import 'package:tracklet/features/schedule/timetable_screen.dart';

import '../../helpers/pump_app.dart';

class _FakeTransitRepository implements TransitRepository {
  _FakeTransitRepository({
    this.stops = const [],
    this.routes = const [],
    this.departures = const [],
  });

  final List<Stop> stops;
  final List<BusRoute> routes;
  final List<ScheduledDeparture> departures;

  @override
  Future<List<Stop>> getStops() async => stops;
  @override
  Future<List<BusRoute>> getRoutes({List<Stop>? knownStops}) async => routes;
  @override
  Future<List<ScheduledDeparture>> getScheduledDepartures() async => departures;
  @override
  Future<List<Bus>> getActiveBuses() async => const [];
  @override
  Stream<List<Bus>> watchActiveBuses() => Stream.value(const []);
  @override
  Future<Stop?> getNearestStop(GeoPoint userLocation) async =>
      stops.firstOrNull;
  @override
  Future<Bus?> getBusById(String busId) async => null;
  @override
  Future<List<RouteStopOccurrence>> getRouteStops(String routeId) async =>
      const [];
  @override
  Future<List<BusStopEvent>> getBusStopEvents(String tripId) async => const [];
}

void main() {
  final testStops = [
    const Stop(
      id: 'stop-1',
      name: 'Main Gate',
      location: GeoPoint(latitude: 11.32, longitude: 75.93),
    ),
    const Stop(
      id: 'stop-2',
      name: 'Mega Hostel',
      location: GeoPoint(latitude: 11.33, longitude: 75.94),
    ),
  ];

  final testRoutes = [
    const BusRoute(
      id: 'route-1',
      name: 'Main Gate ↔ Mega Hostel',
      code: 'R1',
      colorHex: '#4F46E5',
      stopIds: ['stop-1', 'stop-2'],
    ),
    const BusRoute(
      id: 'route-2',
      name: 'East Campus ↔ LH',
      code: 'R2',
      colorHex: '#0D9488',
      stopIds: ['stop-2'],
    ),
  ];

  final testDepartures = [
    const ScheduledDeparture(
      id: 'dep-1',
      routeId: 'route-1',
      hour: 8,
      minute: 30,
      sortOrder: 1,
    ),
    const ScheduledDeparture(
      id: 'dep-2',
      routeId: 'route-1',
      hour: 9,
      minute: 0,
      sortOrder: 2,
      isSpecial: true,
    ),
    const ScheduledDeparture(
      id: 'dep-3',
      routeId: 'route-2',
      hour: 9,
      minute: 15,
      sortOrder: 3,
    ),
  ];

  testWidgets('displays title, disclaimer, route chips and departures', (
    tester,
  ) async {
    await tester.pumpTrackletWidget(
      const TimetableScreen(),
      overrides: [
        transitRepositoryProvider.overrideWithValue(
          _FakeTransitRepository(
            stops: testStops,
            routes: testRoutes,
            departures: testDepartures,
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Campus Timetable'), findsOneWidget);
    expect(find.text('Institute timetable · Reference only'), findsOneWidget);
    expect(find.text('VIEW TIMINGS FOR STOP'), findsOneWidget);
    expect(find.text('All routes (3)'), findsOneWidget);
    expect(find.text('Main Gate ↔ Mega Hostel (2)'), findsOneWidget);
    expect(find.text('East Campus ↔ LH (1)'), findsOneWidget);

    // Verify departures and absence of internal codes / Departure numbers
    expect(find.text('8:30 AM'), findsOneWidget);
    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text('9:15 AM'), findsOneWidget);
    expect(find.text('Special'), findsOneWidget);
    expect(find.textContaining('Route R1'), findsNothing);
    expect(find.textContaining('Departure 0'), findsNothing);
    expect(find.textContaining('Departure 1'), findsNothing);
  });

  testWidgets('filters departures by route when chip is selected', (
    tester,
  ) async {
    await tester.pumpTrackletWidget(
      const TimetableScreen(),
      overrides: [
        transitRepositoryProvider.overrideWithValue(
          _FakeTransitRepository(
            stops: testStops,
            routes: testRoutes,
            departures: testDepartures,
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Main Gate ↔ Mega Hostel (2)'));
    await tester.pumpAndSettle();

    expect(find.text('8:30 AM'), findsOneWidget);
    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text('9:15 AM'), findsNothing);
  });

  testWidgets('filters departures by stop when initialStopId is provided', (
    tester,
  ) async {
    await tester.pumpTrackletWidget(
      const TimetableScreen(initialStopId: 'stop-1'),
      overrides: [
        transitRepositoryProvider.overrideWithValue(
          _FakeTransitRepository(
            stops: testStops,
            routes: testRoutes,
            departures: testDepartures,
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();

    // Dropdown shows Main Gate as the selected value
    expect(find.text('Main Gate'), findsOneWidget);
    // Route 2 does not serve stop-1, so only Route 1's 2 departures are shown
    expect(find.text('8:30 AM'), findsOneWidget);
    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.text('9:15 AM'), findsNothing);

    // Open dropdown and select "All campus stops (Full timetable)"
    await tester.tap(find.text('Main Gate'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('All campus stops (Full timetable)').last);
    await tester.pumpAndSettle();

    expect(find.text('9:15 AM'), findsOneWidget);
  });
}
