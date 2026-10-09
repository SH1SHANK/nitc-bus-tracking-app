import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
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
import 'package:tracklet/features/map/widgets/stop_detail_sheet.dart';
import 'package:tracklet/features/map/widgets/stop_marker_widget.dart';
import 'package:tracklet/services/maps/map_adapter.dart';

import '../../helpers/pump_app.dart';

class TestTransitRepository implements TransitRepository {
  TestTransitRepository({this.simulateError = false});

  final bool simulateError;

  final List<Stop> testStops = const [
    Stop(
      id: 'stop-1',
      code: 'east_campus',
      name: 'East Campus',
      location: GeoPoint(latitude: 11.323361, longitude: 75.937194),
      walkingTimeMinutes: 3,
      description: 'East campus bus shelter',
    ),
    Stop(
      id: 'stop-2',
      code: 'main_gate',
      name: 'Main Gate',
      location: GeoPoint(latitude: 11.320083, longitude: 75.932722),
      walkingTimeMinutes: 5,
      description: 'NIT Calicut Main Entrance',
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
  ];

  @override
  bool get usesSimulatedTelemetry => false;

  @override
  Future<List<Stop>> getStops() async {
    if (simulateError) throw Exception('Simulated network error');
    return testStops;
  }

  @override
  Future<List<BusRoute>> getRoutes() async {
    if (simulateError) throw Exception('Simulated network error');
    return testRoutes;
  }

  @override
  Future<List<RouteStopOccurrence>> getRouteStops(String routeId) async =>
      testRoutes.firstWhere((r) => r.id == routeId).stopOccurrences;

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
  group('MapScreen Widget Tests', () {
    testWidgets('renders map view, route selector card, and map controls', (
      tester,
    ) async {
      final repo = TestTransitRepository();

      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [transitRepositoryProvider.overrideWithValue(repo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(TrackletMapView), findsOneWidget);
      expect(find.byType(MapControls), findsOneWidget);
      expect(find.byType(RouteSelectorCard), findsOneWidget);

      // Route chips displayed
      expect(find.text('R1'), findsOneWidget);
      expect(find.text('R2'), findsOneWidget);

      // Explicit NULL/missing route geometry badge
      expect(
        find.textContaining('Road-following path pending verification'),
        findsOneWidget,
      );

      // Stops markers
      expect(find.byType(StopMarkerWidget), findsNWidgets(2));
    });

    testWidgets('tapping a stop marker opens StopDetailSheet with metadata', (
      tester,
    ) async {
      final repo = TestTransitRepository();

      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [transitRepositoryProvider.overrideWithValue(repo)],
      );
      await tester.pumpAndSettle();

      // Tap the first stop marker
      await tester.tap(find.text('east_campus'));
      await tester.pumpAndSettle();

      expect(find.byType(StopDetailSheet), findsOneWidget);
      expect(find.text('East Campus'), findsWidgets);
      expect(find.text('East campus bus shelter'), findsOneWidget);
      expect(find.text('~3 min walk'), findsOneWidget);
    });

    testWidgets('switching routes updates selected route and stops', (
      tester,
    ) async {
      final repo = TestTransitRepository();

      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [transitRepositoryProvider.overrideWithValue(repo)],
      );
      await tester.pumpAndSettle();

      // Switch to R2
      await tester.tap(find.text('R2'));
      await tester.pumpAndSettle();

      expect(find.text('East ↔ LH (R2)'), findsOneWidget);
      expect(find.text('1 stops'), findsOneWidget);
    });

    testWidgets('shows retryable error state when transit repository fails', (
      tester,
    ) async {
      final errorRepo = TestTransitRepository(simulateError: true);

      await tester.pumpTrackletWidget(
        const MapScreen(),
        overrides: [transitRepositoryProvider.overrideWithValue(errorRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Transit Map Unavailable'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}
