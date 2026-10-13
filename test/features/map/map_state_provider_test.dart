import 'dart:async';

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

  Completer<List<RouteStopOccurrence>>? delayedRouteStops;

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
          sequence: 2,
          stop: mockStops[0],
        ),
        RouteStopOccurrence(
          routeId: 'route-r1',
          stopId: 'stop-2',
          sequence: 1,
          stop: mockStops[1],
        ),
        RouteStopOccurrence(
          routeId: 'route-r1',
          stopId: 'stop-1',
          sequence: 0,
          stop: mockStops[0],
        ),
      ],
    ),
    const BusRoute(
      id: 'route-r2',
      code: 'R2',
      name: 'East to Hostel',
      stopIds: ['stop-2'],
    ),
  ];

  @override
  Future<List<Stop>> getStops() async => mockStops;

  @override
  Future<List<BusRoute>> getRoutes({List<Stop>? knownStops}) async =>
      mockRoutes;

  @override
  Future<List<RouteStopOccurrence>> getRouteStops(String routeId) {
    if (routeId == 'route-r2' && delayedRouteStops != null) {
      return delayedRouteStops!.future;
    }
    return Future.value(mockRoutes.first.stopOccurrences);
  }

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
        expect(state.routes, hasLength(2));
        expect(state.selectedRoute?.code, 'R1');
        expect(state.isGeometryMissing, isTrue);
        expect(state.activeRouteStopIds, containsAll(['stop-1', 'stop-2']));
        expect(state.selectedRouteStops, hasLength(3));
        expect(
          state.selectedRouteStops.map((occurrence) => occurrence.sequence),
          [0, 1, 2],
        );
        expect(
          state.selectedRouteStops.first.stopId,
          state.selectedRouteStops.last.stopId,
        );
      },
    );

    test(
      'a late route-stop response cannot replace a newer route choice',
      () async {
        mockRepo.delayedRouteStops = Completer();
        final notifier = container.read(mapStateNotifierProvider.notifier);
        await notifier.loadTransitData();

        final slowSelection = notifier.selectRoute(mockRepo.mockRoutes[1]);
        await notifier.selectRoute(mockRepo.mockRoutes[0]);
        mockRepo.delayedRouteStops!.complete([
          RouteStopOccurrence(
            routeId: 'route-r2',
            stopId: 'stop-2',
            sequence: 0,
            stop: mockRepo.mockStops[1],
          ),
        ]);
        await slowSelection;

        final state = container.read(mapStateNotifierProvider);
        expect(state.selectedRoute?.id, 'route-r1');
        expect(state.selectedRouteStops, hasLength(3));
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
