import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_eta.dart';
import 'package:tracklet/data/transit/bus_position.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/route_geometry.dart';
import 'package:tracklet/data/transit/stop.dart';
import 'package:tracklet/features/map/widgets/bus_detail_sheet.dart';
import 'package:tracklet/features/map/widgets/map_controls.dart';
import 'package:tracklet/features/map/widgets/stop_detail_sheet.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('StopDetailSheet tests', () {
    const testStop = Stop(
      id: 'stop-east',
      code: 'east_campus',
      name: 'East Campus Stop',
      location: GeoPoint(latitude: 11.3233, longitude: 75.9371),
      walkingTimeMinutes: 5,
      description: 'East campus shelter',
    );

    testWidgets(
      'displays dynamic walking distance and time when user location is nearby',
      (tester) async {
        // 160 meters away (~2 mins walk)
        const nearbyUserLocation = GeoPoint(
          latitude: 11.32186,
          longitude: 75.9371,
        );

        await tester.pumpTrackletWidget(
          Material(
            child: StopDetailSheet(
              stop: testStop,
              userLocation: nearbyUserLocation,
              isDefaultStop: false,
              onClose: () {},
              onSetAsDefaultStop: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('East Campus Stop'), findsOneWidget);
        expect(find.textContaining('walk'), findsOneWidget);
        expect(find.text('Set as Boarding Stop'), findsOneWidget);
      },
    );

    testWidgets(
      'displays selected boarding stop pill when isDefaultStop is true',
      (tester) async {
        await tester.pumpTrackletWidget(
          Material(
            child: StopDetailSheet(
              stop: testStop,
              isDefaultStop: true,
              onClose: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Your selected boarding stop'), findsOneWidget);
        expect(find.text('Set as Boarding Stop'), findsNothing);
      },
    );
  });

  group('MapControls tests', () {
    testWidgets('triggers user recenter when onRecenterUser is provided', (
      tester,
    ) async {
      var recenterCampusCalled = false;
      var recenterUserCalled = false;

      await tester.pumpTrackletWidget(
        Material(
          child: MapControls(
            onRecenterCampus: () => recenterCampusCalled = true,
            onRecenterUser: () => recenterUserCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Recenter on your location'), findsOneWidget);
      expect(find.byTooltip('Recenter on NIT Calicut campus'), findsOneWidget);

      await tester.tap(find.byTooltip('Recenter on your location'));
      expect(recenterUserCalled, isTrue);

      await tester.tap(find.byTooltip('Recenter on NIT Calicut campus'));
      expect(recenterCampusCalled, isTrue);
    });
  });

  group('BusDetailSheet telemetry tests', () {
    testWidgets('displays formatted speed and ETA when expanded', (
      tester,
    ) async {
      final now = DateTime.now();
      final bus = Bus(
        id: 'bus-1',
        name: 'Campus Bus 1',
        numberPlate: 'KL 11 BH 1234',
        routeId: 'route-1',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.32, longitude: 75.93),
          speedKmH: 24.6,
          timestamp: now,
        ),
        lastUpdated: now,
      );

      await tester.pumpTrackletWidget(
        Material(
          child: BusDetailSheet(
            bus: bus,
            route: const BusRoute(
              id: 'route-1',
              code: 'R1',
              name: 'East ↔ MBH',
              geometry: RouteGeometry.missing(),
            ),
            eta: const BusEtaResult.valid(
              minutes: 4,
              distanceMeters: 600,
              busProgressMeters: 200,
              smoothedSpeedMetersPerSecond: 6.8,
            ),
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Campus Bus 1'), findsOneWidget);
      expect(find.text('KL 11 BH 1234'), findsOneWidget);

      await tester.tap(find.text('More detail'));
      await tester.pumpAndSettle();

      expect(find.text('25 km/h'), findsOneWidget);
      expect(find.text('4 min'), findsWidgets);
    });
  });
}
