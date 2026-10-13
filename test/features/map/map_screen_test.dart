import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/campus/campus_building.dart';
import 'package:tracklet/data/campus/campus_building_repository.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/route_geometry.dart';
import 'package:tracklet/data/transit/route_stop_occurrence.dart';
import 'package:tracklet/data/transit/scheduled_departure.dart';
import 'package:tracklet/data/transit/stop.dart';
import 'package:tracklet/data/transit/transit_repository.dart';
import 'package:tracklet/features/map/map_screen.dart';
import 'package:tracklet/features/map/widgets/map_controls.dart';
import 'package:tracklet/features/map/widgets/route_selector_card.dart';
import 'package:tracklet/features/map/widgets/route_stops_sheet.dart';
import 'package:tracklet/features/map/widgets/stop_detail_sheet.dart';
import 'package:tracklet/features/map/widgets/stop_marker_widget.dart';
import 'package:tracklet/services/maps/map_adapter.dart';
import 'package:tracklet/services/maps/map_cartography.dart';

import '../../helpers/pump_app.dart';

class TestCampusBuildingRepository implements CampusBuildingRepository {
  bool fail = false;
  int requestCount = 0;

  @override
  Future<List<CampusBuilding>> getBuildings() async {
    requestCount++;
    if (fail) throw Exception('Simulated campus metadata error');
    return const [
      CampusBuilding(
        id: 'building-main',
        name: 'Main Building',
        location: GeoPoint(latitude: 11.32165, longitude: 75.934246),
        category: 'Academic',
      ),
    ];
  }
}

class TestTransitRepository implements TransitRepository {
  TestTransitRepository({this.simulateError = false});

  final bool simulateError;

  final List<Stop> testStops = [
    const Stop(
      id: 'stop-1',
      code: 'east_campus',
      name: 'East Campus',
      location: GeoPoint(latitude: 11.323361, longitude: 75.937194),
      walkingTimeMinutes: 3,
      description: 'East campus bus shelter',
    ),
    const Stop(
      id: 'stop-2',
      code: 'main_gate',
      name: 'Main Gate',
      location: GeoPoint(latitude: 11.320083, longitude: 75.932722),
      walkingTimeMinutes: 5,
      description: 'NIT Calicut Main Entrance',
    ),
    const Stop(
      id: 'stop-3',
      code: 'library_gate',
      name: 'Library Gate',
      location: GeoPoint(latitude: 11.325, longitude: 75.936),
    ),
  ];

  late final List<BusRoute> testRoutes = [
    BusRoute(
      id: 'route-1',
      code: 'R1',
      name: 'East ↔ MBH (R1)',
      description: 'East Campus to Mega Boys Hostel via Main Gate',
      direction: 'forward',
      geometry: const RouteGeometry.missing(),
      stopOccurrences: [
        RouteStopOccurrence(
          routeId: 'route-1',
          stopId: 'stop-1',
          sequence: 0,
          stop: testStops[0],
        ),
        RouteStopOccurrence(
          routeId: 'route-1',
          stopId: 'stop-2',
          sequence: 1,
          stop: testStops[1],
        ),
      ],
    ),
    BusRoute(
      id: 'route-2',
      code: 'R2',
      name: 'East ↔ LH (R2)',
      description: 'East Campus to Ladies Hostel via South Campus loop',
      direction: 'forward',
      geometry: const RouteGeometry.missing(),
      stopOccurrences: [
        RouteStopOccurrence(
          routeId: 'route-2',
          stopId: 'stop-2',
          sequence: 0,
          stop: testStops[1],
        ),
      ],
    ),
    BusRoute(
      id: 'route-loop',
      code: 'R3',
      name: 'East Campus Loop (R3)',
      description: 'Campus loop returning to East Campus',
      geometry: const RouteGeometry.missing(),
      stopOccurrences: [
        RouteStopOccurrence(
          routeId: 'route-loop',
          stopId: 'stop-1',
          sequence: 0,
          stop: testStops[0],
        ),
        RouteStopOccurrence(
          routeId: 'route-loop',
          stopId: 'stop-2',
          sequence: 1,
          stop: testStops[1],
        ),
        RouteStopOccurrence(
          routeId: 'route-loop',
          stopId: 'stop-1',
          sequence: 2,
          stop: testStops[0],
        ),
      ],
    ),
  ];

  @override
  Future<List<Stop>> getStops() async {
    if (simulateError) throw Exception('Simulated network error');
    return testStops;
  }

  @override
  Future<List<BusRoute>> getRoutes({List<Stop>? knownStops}) async {
    if (simulateError) throw Exception('Simulated network error');
    if (testStops.isEmpty) return [];
    return testRoutes;
  }

  @override
  Future<List<RouteStopOccurrence>> getRouteStops(String routeId) async =>
      testRoutes.firstWhere((route) => route.id == routeId).stopOccurrences;

  @override
  Future<List<Bus>> getActiveBuses() async => [];

  @override
  Future<List<ScheduledDeparture>> getScheduledDepartures() async => [];

  @override
  Stream<List<Bus>> watchActiveBuses() => const Stream.empty();

  @override
  Future<Stop?> getNearestStop(GeoPoint userLocation) async => testStops.first;

  @override
  Future<Bus?> getBusById(String busId) async => null;
}

void main() {
  group('MapScreen widget tests', () {
    testWidgets('uses campus_buildings metadata for map labels', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(TestTransitRepository()),
          campusBuildingRepositoryProvider.overrideWithValue(
            TestCampusBuildingRepository(),
          ),
        ],
      );
      await tester.pumpAndSettle();

      final map = tester.widget<TrackletMapView>(find.byType(TrackletMapView));
      final buildingLabel = map.labels.singleWhere(
        (label) => label.id == 'building-building-main',
      );
      expect(buildingLabel.name, 'Main Building');
      expect(buildingLabel.kind, MapLabelKind.building);
      expect(buildingLabel.point.longitude, 75.934246);
    });

    testWidgets('campus label query errors are retryable', (tester) async {
      final buildings = TestCampusBuildingRepository()..fail = true;
      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(TestTransitRepository()),
          campusBuildingRepositoryProvider.overrideWithValue(buildings),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Campus names unavailable · Retry'), findsOneWidget);
      expect(buildings.requestCount, 1);

      buildings.fail = false;
      await tester.tap(find.text('Campus names unavailable · Retry'));
      await tester.pumpAndSettle();
      expect(buildings.requestCount, 2);
      expect(find.text('Campus names unavailable · Retry'), findsNothing);
    });

    testWidgets('renders map, compact route selector, markers and controls', (
      tester,
    ) async {
      final repository = TestTransitRepository();
      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [transitRepositoryProvider.overrideWithValue(repository)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(TrackletMapView), findsOneWidget);
      expect(find.byType(MapControls), findsOneWidget);
      expect(find.byType(RouteSelectorCard), findsOneWidget);
      expect(find.byType(RouteStopsSheet), findsOneWidget);
      expect(find.byType(StopMarkerWidget), findsNWidgets(3));
      final markers = tester.widgetList<StopMarkerWidget>(
        find.byType(StopMarkerWidget),
      );
      expect(
        markers.singleWhere((marker) => marker.stop.id == 'stop-3').isRouteStop,
        isFalse,
      );
      expect(find.text('East Campus'), findsOneWidget);
      expect(find.text('east_campus'), findsNothing);
      expect(
        find.textContaining('Road-following path is not available yet'),
        findsNothing,
      );
    });

    testWidgets('tapping a human-readable map marker resolves its stop', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(TestTransitRepository()),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('East Campus'));
      await tester.pumpAndSettle();

      expect(find.byType(StopDetailSheet), findsOneWidget);
      expect(find.text('East campus bus shelter'), findsOneWidget);
      expect(find.text('east_campus'), findsOneWidget);
      final markers = tester.widgetList<StopMarkerWidget>(
        find.byType(StopMarkerWidget),
      );
      expect(
        markers.singleWhere((marker) => marker.stop.id == 'stop-1').isSelected,
        isTrue,
      );
    });

    testWidgets('route picker switches to a database-provided route', (
      tester,
    ) async {
      final repository = TestTransitRepository();
      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [transitRepositoryProvider.overrideWithValue(repository)],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RouteSelectorCard));
      await tester.pumpAndSettle();
      expect(find.text('Choose a route'), findsOneWidget);
      expect(find.text('East ↔ LH (R2)'), findsOneWidget);

      await tester.tap(find.text('East ↔ LH (R2)'));
      await tester.pumpAndSettle();
      expect(find.text('East ↔ LH (R2)'), findsNWidgets(2));
      expect(find.text('1 stop · Ordered route stops'), findsOneWidget);
    });

    testWidgets(
      'expanded route details show ordered stops and geometry context',
      (tester) async {
        await tester.pumpTrackletWidget(
          const MapScreen(),
          overrides: [
            transitRepositoryProvider.overrideWithValue(
              TestTransitRepository(),
            ),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('2 stops · Ordered route stops'));
        await tester.pumpAndSettle();

        expect(find.text('East Campus'), findsWidgets);
        expect(find.text('Main Gate'), findsWidgets);
        expect(
          find.textContaining('Road-following path is not available yet'),
          findsOneWidget,
        );
      },
    );

    testWidgets('route details preserve repeated stop occurrences', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(TestTransitRepository()),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RouteSelectorCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('East Campus Loop (R3)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3 stops · Ordered route stops'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('route-stop-0-stop-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('route-stop-2-stop-1')), findsOneWidget);
    });

    testWidgets(
      'selecting a route stop opens its details without switching route',
      (tester) async {
        await tester.pumpTrackletWidget(
          const MapScreen(),
          overrides: [
            transitRepositoryProvider.overrideWithValue(
              TestTransitRepository(),
            ),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('2 stops · Ordered route stops'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('route-stop-1-stop-2')));
        await tester.pumpAndSettle();

        expect(find.byType(StopDetailSheet), findsOneWidget);
        expect(find.text('East ↔ MBH (R1)'), findsOneWidget);
        expect(find.text('NIT Calicut Main Entrance'), findsOneWidget);
        expect(find.text('main_gate'), findsOneWidget);
      },
    );

    testWidgets('responsive layouts work at phone and tablet widths', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final size in [
        const Size(320, 640),
        const Size(390, 844),
        const Size(1024, 768),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpTrackletWidget(
          const MapScreen(),
          overrides: [
            transitRepositoryProvider.overrideWithValue(
              TestTransitRepository(),
            ),
          ],
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'layout $size');
        expect(find.byType(RouteSelectorCard), findsOneWidget);

        if (size.width == 320) {
          await tester.tap(find.text('2 stops · Ordered route stops'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'expanded $size');
        }
      }
    });

    testWidgets('shows retryable error state when transit loading fails', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(
            TestTransitRepository(simulateError: true),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Transit map unavailable'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('shows an empty state when database data has no active stops', (
      tester,
    ) async {
      final repository = TestTransitRepository();
      repository.testStops.clear();

      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [transitRepositoryProvider.overrideWithValue(repository)],
      );
      await tester.pumpAndSettle();

      expect(find.text('No campus stops yet'), findsOneWidget);
    });
  });
}
