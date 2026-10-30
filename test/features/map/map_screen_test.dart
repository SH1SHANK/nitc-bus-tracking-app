import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/features/map/providers/map_state_provider.dart';
import 'package:tracklet/data/campus/campus_building.dart';
import 'package:tracklet/data/campus/campus_building_repository.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_position.dart';
import 'package:tracklet/data/transit/bus_stop_event.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/route_geometry.dart';
import 'package:tracklet/data/transit/route_stop_occurrence.dart';
import 'package:tracklet/data/transit/scheduled_departure.dart';
import 'package:tracklet/data/transit/stop.dart';
import 'package:tracklet/data/transit/transit_repository.dart';
import 'package:tracklet/features/home/providers/home_provider.dart';
import 'package:tracklet/features/map/map_screen.dart';
import 'package:tracklet/features/map/widgets/bus_detail_sheet.dart';
import 'package:tracklet/features/map/widgets/map_controls.dart';
import 'package:tracklet/features/map/widgets/route_selector_card.dart';
import 'package:tracklet/features/map/widgets/route_stops_sheet.dart';
import 'package:tracklet/features/map/widgets/stop_detail_sheet.dart';
import 'package:tracklet/services/location/location_service.dart';
import 'package:tracklet/services/maps/map_adapter.dart';
import 'package:tracklet/services/maps/map_cartography.dart';

import '../../helpers/pump_app.dart';

class _MapTestLocationNotifier extends LocationNotifier {
  _MapTestLocationNotifier(this.testState);

  final LocationState testState;

  @override
  LocationState build() => testState;

  @override
  Future<void> refreshLocationIfPermitted() async {}

  @override
  Future<GeoPoint?> requestAndFetchLocation() async =>
      testState.currentLocation;
}

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
        description: 'Central campus administration',
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
  @override
  Future<List<BusStopEvent>> getBusStopEvents(String tripId) async => const [];
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
      final markers =
          tester.widget<TrackletMapView>(find.byType(TrackletMapView)).markers;
      expect(
        markers.where((marker) => marker.id.startsWith('stop-')),
        hasLength(3),
      );
      expect(
        markers.singleWhere((marker) => marker.id == 'stop-3').isRouteStop,
        isFalse,
      );
      expect(
        markers.singleWhere((marker) => marker.id == 'stop-1').title,
        'East Campus',
      );
      expect(
        markers.singleWhere((marker) => marker.id == 'stop-1').subtitle,
        'east_campus',
      );
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

      tester
          .widget<TrackletMapView>(find.byType(TrackletMapView))
          .markers
          .singleWhere((marker) => marker.id == 'stop-1')
          .onTap!
          .call();
      await tester.pumpAndSettle();

      expect(find.byType(StopDetailSheet), findsOneWidget);
      expect(find.text('East campus bus shelter'), findsOneWidget);
      expect(find.text('east_campus'), findsOneWidget);
      final markers =
          tester.widget<TrackletMapView>(find.byType(TrackletMapView)).markers;
      expect(
        markers.singleWhere((marker) => marker.id == 'stop-1').isSelected,
        isTrue,
      );
    });

    testWidgets('searching selects and highlights a campus building', (
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

      await tester.tap(find.byTooltip('Search campus buildings'));
      await tester.pumpAndSettle();
      expect(find.text('Find a campus building'), findsOneWidget);
      await tester.tap(find.text('Main Building'));
      await tester.pumpAndSettle();

      expect(find.text('Main Building'), findsOneWidget);
      expect(find.text('Academic'), findsOneWidget);
      expect(find.text('Central campus administration'), findsOneWidget);
      final building = tester
          .widget<TrackletMapView>(find.byType(TrackletMapView))
          .labels
          .singleWhere((label) => label.id == 'building-building-main');
      expect(building.isSelected, isTrue);
      expect(building.point.latitude, 11.32165);
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

    testWidgets('map fits 320x568 and 390x844 with 1.3 text scaling', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final size in [const Size(320, 568), const Size(390, 844)]) {
        tester.view.physicalSize = size;
        await tester.pumpTrackletWidget(
          MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: const MapScreen(),
          ),
          overrides: [
            transitRepositoryProvider.overrideWithValue(
              TestTransitRepository(),
            ),
          ],
        );
        await tester.pumpAndSettle();

        final layoutException = tester.takeException();
        expect(layoutException, isNull, reason: 'layout $size');
        expect(find.byType(RouteSelectorCard), findsOneWidget);
        final controls = tester.getRect(find.byType(MapControls));
        expect(controls.top, greaterThanOrEqualTo(0));
        expect(controls.bottom, lessThanOrEqualTo(size.height));
        await tester.tap(find.text('2 stops · Ordered route stops'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'expanded $size');
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

    testWidgets('clearing a selected route returns to overview state', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(TestTransitRepository()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(RouteStopsSheet), findsOneWidget);
      expect(find.byTooltip('Clear selected route'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear selected route'));
      await tester.pumpAndSettle();

      expect(find.byType(RouteStopsSheet), findsNothing);
      expect(find.text('Choose a route'), findsOneWidget);
    });

    testWidgets(
      'closing stop details smoothly restores active route stops sheet',
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

        expect(find.byType(RouteStopsSheet), findsOneWidget);

        // Trigger the same callback Mapbox calls after a rendered-feature hit.
        tester
            .widget<TrackletMapView>(find.byType(TrackletMapView))
            .markers
            .singleWhere((marker) => marker.id == 'stop-1')
            .onTap!
            .call();
        await tester.pumpAndSettle();

        expect(find.byType(StopDetailSheet), findsOneWidget);
        expect(find.byType(RouteStopsSheet), findsNothing);

        // Close stop detail sheet
        await tester.tap(find.byTooltip('Close stop details'));
        await tester.pumpAndSettle();

        expect(find.byType(StopDetailSheet), findsNothing);
        expect(find.byType(RouteStopsSheet), findsOneWidget);
        expect(find.text('East ↔ MBH (R1)'), findsWidgets);
      },
    );

    testWidgets('map controls trigger campus recentering and route fitting', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(TestTransitRepository()),
        ],
      );
      await tester.pumpAndSettle();

      // Tap show all stops on route
      await tester.tap(find.byTooltip('Show all stops on this route'));
      await tester.pumpAndSettle();

      // Tap recenter on campus
      await tester.tap(find.byTooltip('Recenter on NIT Calicut campus'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'respects reduced-motion setting without breaking transitions',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        addTearDown(() {
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        });

        await tester.pumpTrackletWidget(
          const MapScreen(),
          overrides: [
            transitRepositoryProvider.overrideWithValue(
              TestTransitRepository(),
            ),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.byType(RouteStopsSheet), findsOneWidget);

        await tester.tap(find.byTooltip('Recenter on NIT Calicut campus'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

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

    testWidgets('renders live bus marker and opens bus detail sheet on tap', (
      tester,
    ) async {
      final liveBus = Bus(
        id: 'bus-sim-1',
        numberPlate: 'KL 11 BH 0001',
        name: 'Bus 1 (East ↔ MBH)',
        routeId: 'route-1',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.32168, longitude: 75.93367),
          heading: 45.0,
          speedKmH: 20.0,
          accuracyMeters: 4.0,
          sequenceNumber: 1,
          timestamp: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      final repository = TestTransitRepository();

      await tester.pumpTrackletWidget(
        const MapScreen(busBodyColors: {'bus-sim-1': Color(0xff2684ff)}),
        overrides: [
          transitRepositoryProvider.overrideWithValue(repository),
          activeBusesStreamProvider.overrideWith(
            (ref) => Stream.value([liveBus]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      final map = tester.widget<TrackletMapView>(find.byType(TrackletMapView));
      expect(
        map.markers.where((marker) => marker.id.startsWith('bus-')),
        hasLength(1),
      );
      final busMarker = map.markers.singleWhere(
        (marker) => marker.id == 'bus-bus-sim-1',
      );
      expect(busMarker.show3dModel, isTrue);
      expect(busMarker.busBodyColor, const Color(0xff2684ff));

      busMarker.onTap!.call();
      await tester.pumpAndSettle();

      expect(find.byType(BusDetailSheet), findsOneWidget);
      expect(find.text('Bus 1 (East ↔ MBH)'), findsOneWidget);
      expect(find.text('KL 11 BH 0001'), findsOneWidget);
      expect(find.text('Next stop'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);

      await tester.tap(find.text('More detail'));
      await tester.pumpAndSettle();
      expect(find.text('ETA'), findsOneWidget);
      expect(find.text('Follow bus'), findsOneWidget);

      tester
          .widget<TrackletMapView>(find.byType(TrackletMapView))
          .onUserGesture!
          .call();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(find.text('Resume following'), findsOneWidget);
      await tester.tap(find.text('Resume following'));
      await tester.pumpAndSettle();
      expect(find.text('Resume following'), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byType(BusDetailSheet),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BusDetailSheet), findsNothing);
    });

    testWidgets('opens map legend modal bottom sheet and toggles routes', (
      tester,
    ) async {
      final repository = TestTransitRepository();

      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [transitRepositoryProvider.overrideWithValue(repository)],
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Map legend'), findsOneWidget);
      await tester.tap(find.byTooltip('Map legend'));
      await tester.pumpAndSettle();

      expect(find.text('Map Legend'), findsOneWidget);
      expect(find.text('Hide routes'), findsOneWidget);

      await tester.tap(find.text('Hide routes'));
      await tester.pumpAndSettle();

      expect(find.text('Show routes'), findsOneWidget);
    });

    testWidgets(
      'recenter on user cancels bus following and recenters camera when valid',
      (tester) async {
        const userLoc = GeoPoint(latitude: 11.3218, longitude: 75.9370);
        final liveBus = Bus(
          id: 'bus-follow-test',
          numberPlate: 'KL 11 BH 0002',
          name: 'Follow Bus',
          routeId: 'route-1',
          status: BusStatus.live,
          position: BusPosition(
            point: const GeoPoint(latitude: 11.32168, longitude: 75.93367),
            speedKmH: 20.0,
            timestamp: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );

        final repository = TestTransitRepository();

        await tester.pumpTrackletWidget(
          const MapScreen(),
          overrides: [
            transitRepositoryProvider.overrideWithValue(repository),
            activeBusesStreamProvider.overrideWith(
              (ref) => Stream.value([liveBus]),
            ),
            locationStateProvider.overrideWith(
              () => _MapTestLocationNotifier(
                const LocationState(
                  currentLocation: userLoc,
                  permissionState: LocationPermissionState.granted,
                ),
              ),
            ),
          ],
        );
        await tester.pumpAndSettle();

        // Tap bus and follow it
        final map = tester.widget<TrackletMapView>(
          find.byType(TrackletMapView),
        );
        map.markers
            .singleWhere((marker) => marker.id == 'bus-bus-follow-test')
            .onTap!
            .call();
        await tester.pumpAndSettle();
        await tester.tap(find.text('More detail'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Follow bus'));
        await tester.pumpAndSettle();

        // Recenter on user should clear following bus
        await tester.tap(find.byTooltip('Recenter on your location'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'shows floating SnackBar with Settings when permission is deniedForever',
      (tester) async {
        final repository = TestTransitRepository();

        await tester.pumpTrackletWidget(
          const MapScreen(),
          overrides: [
            transitRepositoryProvider.overrideWithValue(repository),
            locationStateProvider.overrideWith(
              () => _MapTestLocationNotifier(
                const LocationState(
                  permissionState: LocationPermissionState.deniedForever,
                  errorMessage:
                      'Location permission is denied. Enable it in settings.',
                ),
              ),
            ),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Recenter on your location'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.text('Location permission is denied. Enable it in settings.'),
          findsOneWidget,
        );
        expect(find.text('Settings'), findsOneWidget);
      },
    );

    testWidgets(
      'shows floating SnackBar with Settings when location service is disabled',
      (tester) async {
        final repository = TestTransitRepository();

        await tester.pumpTrackletWidget(
          const MapScreen(),
          overrides: [
            transitRepositoryProvider.overrideWithValue(repository),
            locationStateProvider.overrideWith(
              () => _MapTestLocationNotifier(
                const LocationState(
                  permissionState: LocationPermissionState.serviceDisabled,
                  errorMessage:
                      'Location services are disabled on your device.',
                ),
              ),
            ),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Recenter on your location'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.text('Location services are disabled on your device.'),
          findsOneWidget,
        );
        expect(find.text('Settings'), findsOneWidget);
      },
    );

    testWidgets(
      'when bus has no valid location, onRecenterBus is disabled and following is not enabled',
      (tester) async {
        final now = DateTime.now();
        final noLocationBus = Bus(
          id: 'bus-no-loc',
          name: 'Campus Bus No Loc',
          numberPlate: 'KL 11 BH 9999',
          routeId: 'route-1',
          status: BusStatus.live,
          position: BusPosition(
            point: const GeoPoint(latitude: 0, longitude: 0),
            timestamp: now,
          ),
          lastUpdated: now,
        );

        final repository = TestTransitRepository();

        await tester.pumpTrackletWidget(
          const MapScreen(),
          overrides: [
            transitRepositoryProvider.overrideWithValue(repository),
            activeBusesStreamProvider.overrideWith(
              (ref) => Stream.value([noLocationBus]),
            ),
          ],
        );
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<TrackletMapView>(find.byType(TrackletMapView))
              .markers
              .where((marker) => marker.id.startsWith('bus-')),
          isEmpty,
        );

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MapScreen)),
        );
        container
            .read(mapStateNotifierProvider.notifier)
            .selectBus(noLocationBus);
        await tester.pumpAndSettle();

        expect(find.byType(BusDetailSheet), findsOneWidget);
        expect(find.text('Campus Bus No Loc'), findsOneWidget);

        final mapControls = tester.widget<MapControls>(
          find.byType(MapControls),
        );
        expect(mapControls.onRecenterBus, isNull);
        expect(find.text('Resume following'), findsNothing);
      },
    );

    testWidgets(
      'clearing BusDetailSheet clears selectedBus on mapStateNotifierProvider',
      (tester) async {
        final now = DateTime.now();
        final liveBus = Bus(
          id: 'bus-1',
          name: 'Bus 1 (East ↔ MBH)',
          numberPlate: 'KL 11 BH 0001',
          routeId: 'route-1',
          status: BusStatus.live,
          position: BusPosition(
            point: const GeoPoint(latitude: 11.3216, longitude: 75.9337),
            speedKmH: 15,
            timestamp: now,
          ),
          lastUpdated: now,
        );

        final repository = TestTransitRepository();

        await tester.pumpTrackletWidget(
          const MapScreen(),
          overrides: [
            transitRepositoryProvider.overrideWithValue(repository),
            activeBusesStreamProvider.overrideWith(
              (ref) => Stream.value([liveBus]),
            ),
          ],
        );
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MapScreen)),
        );
        container.read(mapStateNotifierProvider.notifier).selectBus(liveBus);
        await tester.pumpAndSettle();

        expect(find.byType(BusDetailSheet), findsOneWidget);
        expect(find.text('Bus 1 (East ↔ MBH)'), findsOneWidget);

        // Tap close button on sheet
        await tester.tap(
          find.descendant(
            of: find.byType(BusDetailSheet),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(container.read(mapStateNotifierProvider).selectedBus, isNull);
      },
    );
  });
}
