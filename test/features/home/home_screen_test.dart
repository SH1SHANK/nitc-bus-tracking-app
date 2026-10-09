import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/scheduled_departure.dart';
import 'package:tracklet/data/transit/stop.dart';
import 'package:tracklet/features/home/home_screen.dart';
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
      await tester.pumpTrackletWidget(const HomeScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('Shashank'), findsOneWidget);
      expect(find.text('Where are you headed?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(NextBusCard), findsOneWidget);
      expect(find.byType(LiveBusRoutePreview), findsOneWidget);
      expect(find.byType(NextBusesCard), findsOneWidget);
      expect(find.text('Default boarding stop'), findsOneWidget);
      expect(
        find.text('Turn on location to find your nearest stop'),
        findsOneWidget,
      );
      expect(find.text('Locate'), findsOneWidget);
      expect(find.text('Your next ride'), findsOneWidget);
      expect(find.text('Open map'), findsOneWidget);
      expect(
        find.textContaining('Demo bus locations are simulated'),
        findsNothing,
      );
      expect(find.text('Next buses'), findsOneWidget);
      expect(find.text('ROUTE TRACKER'), findsOneWidget);
      expect(find.text('Board here'), findsOneWidget);
      expect(
        find.text('No other buses are available to display.'),
        findsOneWidget,
      );
    });

    testWidgets('shows the closest stop and walking estimate from location', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const HomeScreen(),
        overrides: [
          locationStateProvider.overrideWith(
            () => _FixedLocationNotifier(
              const GeoPoint(latitude: 11.323028, longitude: 75.936722),
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Nearest bus stop'), findsOneWidget);
      expect(find.text('Architecture'), findsWidgets);
      expect(find.text('~0 m straight-line distance'), findsOneWidget);
      expect(find.text('1 min walk'), findsOneWidget);
      expect(find.text('Locate'), findsNothing);
    });

    testWidgets('hides campus walking estimates for a distant location', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const HomeScreen(),
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
      expect(find.textContaining('straight-line distance'), findsNothing);
      expect(find.textContaining('min walk'), findsNothing);
    });

    testWidgets('stop search suggests and selects a campus destination', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Architecture');
      await tester.pumpAndSettle();

      expect(find.text('Architecture'), findsWidgets);
      await tester.tap(find.text('Architecture').at(1));
      await tester.pumpAndSettle();

      final searchField = tester.widget<TextField>(find.byType(TextField));
      expect(searchField.controller?.text, 'Architecture');
      expect(find.text('Architecture is on this route'), findsOneWidget);
      expect(find.text('Board here'), findsOneWidget);
      expect(find.textContaining('Seats Available'), findsNothing);
    });

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
          find.text('Closest route stop to East Gate: Lecture Hall'),
          findsOneWidget,
        );
        expect(find.text('Last stop'), findsOneWidget);
        expect(find.text('Next stop'), findsOneWidget);
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

      expect(find.text('2 stops back'), findsOneWidget);
      expect(find.text('Last stop'), findsOneWidget);
      expect(find.text('Board here'), findsOneWidget);
      expect(find.text('Next stop'), findsNWidgets(3));
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
        find.text('No other buses are available to display.'),
        findsOneWidget,
      );
      expect(find.text('Kozhikode City'), findsNothing);
      expect(find.text('Kuttipuram'), findsNothing);
    });

    testWidgets('opens drawer on tapping hamburger icon', (tester) async {
      await tester.pumpTrackletWidget(const HomeScreen());
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
