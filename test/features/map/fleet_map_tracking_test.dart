import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_position.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/route_geometry.dart';
import 'package:tracklet/data/transit/route_stop_occurrence.dart';
import 'package:tracklet/data/transit/stop.dart';
import 'package:tracklet/data/transit/transit_repository.dart';
import 'package:tracklet/features/home/providers/home_provider.dart';
import 'package:tracklet/features/map/map_screen.dart';
import 'package:tracklet/features/map/widgets/bus_detail_sheet.dart';
import 'package:tracklet/features/map/widgets/bus_marker_widget.dart';
import 'package:tracklet/features/map/widgets/route_selector_card.dart';
import 'package:tracklet/services/maps/map_adapter.dart';

import '../../helpers/pump_app.dart';

class _FleetTestTransitRepository implements TransitRepository {
  final List<Stop> testStops = [
    const Stop(
      id: 'stop-1',
      code: 'east_campus',
      name: 'East Campus',
      location: GeoPoint(latitude: 11.323361, longitude: 75.937194),
    ),
    const Stop(
      id: 'stop-2',
      code: 'main_gate',
      name: 'Main Gate',
      location: GeoPoint(latitude: 11.320083, longitude: 75.932722),
    ),
  ];

  late final List<BusRoute> testRoutes = [
    BusRoute(
      id: 'route-1',
      code: 'R1',
      name: 'East ↔ MBH (R1)',
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
  ];

  @override
  Future<List<Stop>> getStops() async => testStops;

  @override
  Future<List<BusRoute>> getRoutes({List<Stop>? knownStops}) async =>
      testRoutes;

  @override
  Future<List<RouteStopOccurrence>> getRouteStops(String routeId) async =>
      testRoutes.firstWhere((r) => r.id == routeId).stopOccurrences;

  @override
  Future<List<Bus>> getActiveBuses() async => const [];

  @override
  Stream<List<Bus>> watchActiveBuses() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Fleet-Wide Map Tracking Tests', () {
    testWidgets('renders all buses on different routes simultaneously', (
      tester,
    ) async {
      final now = DateTime.now();
      final busRoute1 = Bus(
        id: 'bus-1',
        name: 'Bus 1 (Route 1)',
        numberPlate: 'KL 11 BH 0001',
        routeId: 'route-1',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.3216, longitude: 75.9337),
          speedKmH: 22.0,
          timestamp: now,
        ),
        lastUpdated: now,
      );
      final busRoute2 = Bus(
        id: 'bus-2',
        name: 'Bus 2 (Route 2)',
        numberPlate: 'KL 11 BH 0002',
        routeId: 'route-2',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.3245, longitude: 75.9360),
          speedKmH: 18.0,
          timestamp: now,
        ),
        lastUpdated: now,
      );
      final busUnassigned = Bus(
        id: 'bus-3',
        name: 'Bus 3 (Unassigned)',
        numberPlate: 'KL 11 BH 0003',
        routeId: null,
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.3228, longitude: 75.9348),
          speedKmH: 15.0,
          timestamp: now,
        ),
        lastUpdated: now,
      );

      final repository = _FleetTestTransitRepository();

      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(repository),
          activeBusesStreamProvider.overrideWith(
            (ref) => Stream.value([busRoute1, busRoute2, busUnassigned]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      // All 3 bus markers must exist in the map data simultaneously
      final mapView = tester.widget<TrackletMapView>(
        find.byType(TrackletMapView),
      );
      final busMarkers =
          mapView.markers.where((m) => m.id.startsWith('bus-')).toList();
      expect(busMarkers, hasLength(3));
      expect(
        busMarkers.map((m) => m.id),
        containsAll(['bus-bus-1', 'bus-bus-2', 'bus-bus-3']),
      );

      // Clear the default selected route to return to fleet overview state
      await tester.tap(find.byTooltip('Clear selected route'));
      await tester.pumpAndSettle();

      // Verify fleet overview card shows active fleet count when no route is selected
      expect(find.text('Campus Transit Fleet'), findsOneWidget);
      expect(
        find.text('3 buses active · Tap any bus for details'),
        findsOneWidget,
      );
    });

    testWidgets('selecting a route does NOT remove other buses from the map', (
      tester,
    ) async {
      final now = DateTime.now();
      // Place buses close to Main Gate (Route 2's stop) so both are in visible camera viewport
      final busRoute1 = Bus(
        id: 'bus-1',
        name: 'Bus 1 (Route 1)',
        numberPlate: 'KL 11 BH 0001',
        routeId: 'route-1',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.3200, longitude: 75.9327),
          timestamp: now,
        ),
        lastUpdated: now,
      );
      final busRoute2 = Bus(
        id: 'bus-2',
        name: 'Bus 2 (Route 2)',
        numberPlate: 'KL 11 BH 0002',
        routeId: 'route-2',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.3202, longitude: 75.9327),
          timestamp: now,
        ),
        lastUpdated: now,
      );

      final repository = _FleetTestTransitRepository();

      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(repository),
          activeBusesStreamProvider.overrideWith(
            (ref) => Stream.value([busRoute1, busRoute2]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TrackletMapView>(find.byType(TrackletMapView))
            .markers
            .where((marker) => marker.id.startsWith('bus-')),
        hasLength(2),
      );

      // Open route picker and select Route 2
      await tester.tap(find.byType(RouteSelectorCard));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('route-option-route-2')));
      await tester.pumpAndSettle();

      // Both buses MUST remain present on the map
      final mapView = tester.widget<TrackletMapView>(
        find.byType(TrackletMapView),
      );
      final markers =
          mapView.markers.where((m) => m.id.startsWith('bus-')).toList();
      expect(markers, hasLength(2));
      expect(markers.map((m) => m.id), containsAll(['bus-bus-1', 'bus-bus-2']));
    });

    testWidgets('duplicate telemetry does not create duplicate markers', (
      tester,
    ) async {
      final now = DateTime.now();
      final bus1 = Bus(
        id: 'bus-1',
        name: 'Bus 1',
        numberPlate: 'KL 11 BH 0001',
        routeId: 'route-1',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.3216, longitude: 75.9337),
          sequenceNumber: 1,
          timestamp: now,
        ),
        lastUpdated: now,
      );
      // Duplicate record with same bus ID
      final bus1Duplicate = Bus(
        id: 'bus-1',
        name: 'Bus 1 Duplicate',
        numberPlate: 'KL 11 BH 0001',
        routeId: 'route-1',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.3216, longitude: 75.9337),
          sequenceNumber: 1,
          timestamp: now,
        ),
        lastUpdated: now,
      );

      final repository = _FleetTestTransitRepository();

      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(repository),
          activeBusesStreamProvider.overrideWith(
            (ref) => Stream.value([bus1, bus1Duplicate]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      // Only 1 marker should be created
      expect(
        tester
            .widget<TrackletMapView>(find.byType(TrackletMapView))
            .markers
            .where((marker) => marker.id == 'bus-bus-1'),
        hasLength(1),
      );
    });

    testWidgets(
      'rejects invalid coordinates and displays stale styling for old telemetry',
      (tester) async {
        final now = DateTime.now();
        final invalidBus = Bus(
          id: 'bus-invalid',
          name: 'Invalid GPS Bus',
          numberPlate: 'KL 11 BH 9999',
          routeId: 'route-1',
          status: BusStatus.live,
          position: BusPosition(
            point: const GeoPoint(latitude: 0.0, longitude: 0.0), // Null island
            timestamp: now,
          ),
          lastUpdated: now,
        );
        final staleBus = Bus(
          id: 'bus-stale',
          name: 'Stale Bus',
          numberPlate: 'KL 11 BH 8888',
          routeId: 'route-1',
          status: BusStatus.live,
          position: BusPosition(
            point: const GeoPoint(latitude: 11.3216, longitude: 75.9337),
            timestamp: now.subtract(
              const Duration(seconds: 120),
            ), // > 90s stale
          ),
          lastUpdated: now.subtract(const Duration(seconds: 120)),
        );

        final repository = _FleetTestTransitRepository();

        await tester.pumpTrackletWidget(
          const MapScreen(),
          overrides: [
            transitRepositoryProvider.overrideWithValue(repository),
            activeBusesStreamProvider.overrideWith(
              (ref) => Stream.value([invalidBus, staleBus]),
            ),
          ],
        );
        await tester.pumpAndSettle();

        // Invalid bus has no marker
        final markers =
            tester
                .widget<TrackletMapView>(find.byType(TrackletMapView))
                .markers;
        expect(
          markers.where((marker) => marker.id == 'bus-bus-invalid'),
          isEmpty,
        );
        final marker = markers.singleWhere(
          (item) => item.id == 'bus-bus-stale',
        );
        final busMarker = marker.child as BusMarkerWidget;
        expect(busMarker.bus.trackingState(), BusTrackingState.stale);
        expect(marker.show3dModel, isFalse);
      },
    );

    testWidgets('displays clean empty fleet card when no buses are active', (
      tester,
    ) async {
      final repository = _FleetTestTransitRepository();

      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(repository),
          activeBusesStreamProvider.overrideWith(
            (ref) => Stream.value(<Bus>[]),
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
      expect(find.byKey(const ValueKey('empty-fleet-card')), findsOneWidget);
      expect(find.text('No active buses right now'), findsOneWidget);
      expect(
        find.text('Live tracking will appear once buses start operating.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'gracefully offsets markers for geographically overlapping buses',
      (tester) async {
        final now = DateTime.now();
        // Two buses at the exact same coordinates (e.g. terminal / bus shelter)
        const hubLocation = GeoPoint(latitude: 11.323361, longitude: 75.937194);
        final busAtHub1 = Bus(
          id: 'bus-hub-1',
          name: 'Hub Bus 1',
          numberPlate: 'KL 11 BH 0001',
          routeId: 'route-1',
          status: BusStatus.live,
          position: BusPosition(point: hubLocation, timestamp: now),
          lastUpdated: now,
        );
        final busAtHub2 = Bus(
          id: 'bus-hub-2',
          name: 'Hub Bus 2',
          numberPlate: 'KL 11 BH 0002',
          routeId: 'route-2',
          status: BusStatus.live,
          position: BusPosition(point: hubLocation, timestamp: now),
          lastUpdated: now,
        );

        final repository = _FleetTestTransitRepository();

        await tester.pumpTrackletWidget(
          const MapScreen(),
          overrides: [
            transitRepositoryProvider.overrideWithValue(repository),
            activeBusesStreamProvider.overrideWith(
              (ref) => Stream.value([busAtHub1, busAtHub2]),
            ),
          ],
        );
        await tester.pumpAndSettle();

        final mapView = tester.widget<TrackletMapView>(
          find.byType(TrackletMapView),
        );
        final markers =
            mapView.markers.where((m) => m.id.startsWith('bus-')).toList();

        expect(markers, hasLength(2));
        // Overlapping markers should have distinct non-zero alignments to avoid occlusion
        expect(markers[0].alignment, isNot(equals(markers[1].alignment)));
        expect(markers[0].alignment, isNot(equals(Alignment.center)));
        expect(markers[1].alignment, isNot(equals(Alignment.center)));
      },
    );

    testWidgets(
      'tapping a bus marker opens BusDetailSheet and manual navigation resets follow state',
      (tester) async {
        final now = DateTime.now();
        final bus = Bus(
          id: 'bus-tap-test',
          name: 'Bus Tap Test',
          numberPlate: 'KL 11 BH 1234',
          routeId: 'route-1',
          status: BusStatus.live,
          position: BusPosition(
            point: const GeoPoint(latitude: 11.3216, longitude: 75.9337),
            speedKmH: 25.0,
            timestamp: now,
          ),
          lastUpdated: now,
        );

        final repository = _FleetTestTransitRepository();

        await tester.pumpTrackletWidget(
          const MapScreen(),
          overrides: [
            transitRepositoryProvider.overrideWithValue(repository),
            activeBusesStreamProvider.overrideWith(
              (ref) => Stream.value([bus]),
            ),
          ],
        );
        await tester.pumpAndSettle();

        tester
            .widget<TrackletMapView>(find.byType(TrackletMapView))
            .markers
            .singleWhere((marker) => marker.id == 'bus-bus-tap-test')
            .onTap!
            .call();
        await tester.pumpAndSettle();

        expect(find.byType(BusDetailSheet), findsOneWidget);
        expect(find.text('Bus Tap Test'), findsOneWidget);

        // Trigger user map gesture
        tester
            .widget<TrackletMapView>(find.byType(TrackletMapView))
            .onUserGesture
            ?.call();
        await tester.pumpAndSettle();

        // Resume following appears when user panned away from followed bus
        expect(find.text('Resume following'), findsOneWidget);
      },
    );

    testWidgets('Fit fleet map control fits all active buses in view', (
      tester,
    ) async {
      final now = DateTime.now();
      final bus1 = Bus(
        id: 'bus-1',
        name: 'Bus 1',
        numberPlate: 'KL 11 BH 0001',
        routeId: 'route-1',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.3216, longitude: 75.9337),
          timestamp: now,
        ),
        lastUpdated: now,
      );
      final bus2 = Bus(
        id: 'bus-2',
        name: 'Bus 2',
        numberPlate: 'KL 11 BH 0002',
        routeId: 'route-2',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.3245, longitude: 75.9360),
          timestamp: now,
        ),
        lastUpdated: now,
      );

      final repository = _FleetTestTransitRepository();

      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [
          transitRepositoryProvider.overrideWithValue(repository),
          activeBusesStreamProvider.overrideWith(
            (ref) => Stream.value([bus1, bus2]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Fit all active buses in view'), findsOneWidget);
      await tester.tap(find.byTooltip('Fit all active buses in view'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
