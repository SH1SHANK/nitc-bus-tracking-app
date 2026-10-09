import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_route.dart';
import 'package:tracklet/data/transit/route_geometry.dart';
import 'package:tracklet/data/transit/route_stop_occurrence.dart';
import 'package:tracklet/data/transit/scheduled_departure.dart';
import 'package:tracklet/data/transit/stop.dart';
import 'package:tracklet/data/transit/transit_repository.dart';
import 'package:tracklet/features/map/providers/map_state_provider.dart';
import 'package:tracklet/services/maps/map_config.dart';

class MockTransitRepository implements TransitRepository {
  @override
  bool get usesSimulatedTelemetry => false;

  final List<Stop> mockStops = [
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

  late final List<BusRoute> mockRoutes = [
    BusRoute(
      id: 'route-r1',
      code: 'R1',
      name: 'East ↔ MBH (R1)',
      geometry: const RouteGeometry.missing(),
      stopOccurrences: [
        RouteStopOccurrence(
          routeId: 'route-r1',
          stopId: 'stop-1',
          sequence: 0,
          stop: mockStops[0],
        ),
        RouteStopOccurrence(
          routeId: 'route-r1',
          stopId: 'stop-2',
          sequence: 1,
          stop: mockStops[1],
        ),
      ],
    ),
  ];

  @override
  Future<List<Stop>> getStops() async => mockStops;

  @override
  Future<List<BusRoute>> getRoutes() async => mockRoutes;

  @override
  Future<List<RouteStopOccurrence>> getRouteStops(String routeId) async =>
      mockRoutes.first.stopOccurrences;

  @override
  Future<List<Bus>> getActiveBuses() async => [];

  @override
  Future<List<ScheduledDeparture>> getScheduledDepartures() async => [];

  @override
  Stream<List<Bus>> watchActiveBuses() => const Stream.empty();

  @override
  Future<Stop?> getNearestStop(GeoPoint userLocation) async => mockStops.first;

  @override
  Future<Bus?> getBusById(String busId) async => null;
}

void main() {
  group('MapStateNotifier State Transitions', () {
    late ProviderContainer container;
    late MockTransitRepository mockRepo;

    setUp(() {
      mockRepo = MockTransitRepository();
      container = ProviderContainer(
        overrides: [transitRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'initializes and loads stops, routes, and initial selection',
      () async {
        final notifier = container.read(mapStateNotifierProvider.notifier);
        await notifier.loadTransitData();

        final state = container.read(mapStateNotifierProvider);
        expect(state.isLoading, isFalse);
        expect(state.hasError, isFalse);
        expect(state.stops, hasLength(2));
        expect(state.routes, hasLength(1));
        expect(state.selectedRoute?.code, 'R1');
        expect(state.isGeometryMissing, isTrue);
        expect(state.activeRouteStopIds, containsAll(['stop-1', 'stop-2']));
      },
    );

    test('selecting stop updates cameraCenter and selectedStop', () async {
      final notifier = container.read(mapStateNotifierProvider.notifier);
      await notifier.loadTransitData();

      final targetStop = mockRepo.mockStops[1];
      notifier.selectStop(targetStop);

      final state = container.read(mapStateNotifierProvider);
      expect(state.selectedStop?.id, 'stop-2');
      expect(state.cameraCenter, targetStop.location);
    });

    test(
      'clearing selection resets selectedStop without modifying routes',
      () async {
        final notifier = container.read(mapStateNotifierProvider.notifier);
        await notifier.loadTransitData();

        notifier.selectStop(mockRepo.mockStops.first);
        expect(
          container.read(mapStateNotifierProvider).selectedStop,
          isNotNull,
        );

        notifier.clearSelection();
        expect(container.read(mapStateNotifierProvider).selectedStop, isNull);
        expect(
          container.read(mapStateNotifierProvider).selectedRoute,
          isNotNull,
        );
      },
    );

    test('recenterCampus moves camera to MapConfig.campusCenter', () async {
      final notifier = container.read(mapStateNotifierProvider.notifier);
      await notifier.loadTransitData();

      notifier.selectStop(mockRepo.mockStops.first);
      notifier.recenterCampus();

      final state = container.read(mapStateNotifierProvider);
      expect(state.cameraCenter, MapConfig.campusCenter);
      expect(state.selectedStop, isNull);
    });
  });
}
