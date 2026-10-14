import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_eta.dart';
import 'package:tracklet/data/transit/bus_position.dart';
import 'package:tracklet/data/transit/route_stop_occurrence.dart';
import 'package:tracklet/data/transit/stop.dart';
import 'package:tracklet/features/map/bus_stop_progress.dart';

void main() {
  final now = DateTime.utc(2026, 10, 14, 10);
  const route = [
    GeoPoint(latitude: 11.32, longitude: 75.93),
    GeoPoint(latitude: 11.32, longitude: 75.94),
  ];
  const target = Stop(
    id: 'b',
    name: 'Stop B',
    location: GeoPoint(latitude: 11.32, longitude: 75.939),
  );

  Bus bus({
    GeoPoint? point,
    double speedMps = 4,
    BusStatus status = BusStatus.live,
    bool stale = false,
    double heading = 0,
    DateTime? timestamp,
  }) => Bus(
    id: 'bus',
    numberPlate: 'NITC-1',
    name: 'Campus bus',
    routeId: 'r',
    tripId: 't',
    status: status,
    isStale: stale,
    position: BusPosition(
      point: point ?? const GeoPoint(latitude: 11.32, longitude: 75.932),
      speedKmH: speedMps * 3.6,
      heading: heading,
      timestamp: timestamp ?? now.subtract(const Duration(seconds: 5)),
    ),
    lastUpdated: timestamp ?? now,
  );

  BusStopProgress progress({
    String? current,
    String? lastType = 'departed',
    DateTime? eventAt,
    String direction = 'forward',
    Stop? targetOverride,
  }) => BusStopProgress(
    visitedStopIds: const {'a'},
    currentStopId: current,
    nextStop: RouteStopOccurrence(
      routeId: 'r',
      stopId: targetOverride?.id ?? 'b',
      sequence: 1,
      stop: targetOverride ?? target,
    ),
    upcomingStops: const [],
    direction: direction,
    lastEventType: lastType,
    lastEventAt: eventAt ?? now.subtract(const Duration(minutes: 1)),
  );

  BusEtaResult estimate({
    Bus? vehicle,
    List<GeoPoint>? geometry,
    BusStopProgress? stopProgress,
    bool unresolved = false,
    double? previousProgressMeters,
    double? previousSpeedMetersPerSecond,
  }) => BusEtaCalculator.calculate(
    bus: vehicle ?? bus(),
    route: geometry ?? route,
    progress: unresolved ? null : stopProgress ?? progress(),
    clock: () => now,
    previousProgressMeters: previousProgressMeters,
    previousSpeedMetersPerSecond: previousSpeedMetersPerSecond,
  );

  test('projects with metric accuracy and handles duplicate route points', () {
    final candidates = RouteProgressProjector.candidates([
      route.first,
      route.first,
      route.last,
    ], const GeoPoint(latitude: 11.32, longitude: 75.935));
    expect(candidates, hasLength(1));
    expect(candidates.single.offsetMeters, lessThan(1));
    expect(candidates.single.alongMeters, closeTo(545, 2));
    expect(
      RouteProgressProjector.candidates([route.first], route.first),
      isEmpty,
    );
  });

  test('projects self crossings onto distinct cumulative route positions', () {
    const crossing = GeoPoint(latitude: 11.32, longitude: 75.93);
    final candidates = RouteProgressProjector.candidates(const [
      GeoPoint(latitude: 11.319, longitude: 75.929),
      GeoPoint(latitude: 11.321, longitude: 75.931),
      GeoPoint(latitude: 11.319, longitude: 75.931),
      GeoPoint(latitude: 11.321, longitude: 75.929),
    ], crossing);
    expect(
      candidates.where((candidate) => candidate.offsetMeters < 1).length,
      2,
    );
    expect(
      (candidates.first.alongMeters - candidates.last.alongMeters).abs(),
      greaterThan(200),
    );
  });

  test('measures loop wrap in route direction', () {
    const start = RouteProjection(
      alongMeters: 900,
      offsetMeters: 0,
      segmentIndex: 2,
      bearing: 0,
    );
    const end = RouteProjection(
      alongMeters: 100,
      offsetMeters: 0,
      segmentIndex: 0,
      bearing: 0,
    );
    expect(
      RouteProgressProjector.forwardDistance(
        bus: start,
        stop: end,
        routeLengthMeters: 1000,
        isLoop: true,
        reverse: false,
      ),
      200,
    );
    expect(
      RouteProgressProjector.forwardDistance(
        bus: start,
        stop: end,
        routeLengthMeters: 1000,
        isLoop: false,
        reverse: false,
      ),
      isNull,
    );
  });

  test(
    'projects a loop next stop at its forward occurrence across the seam',
    () {
      const loop = [
        GeoPoint(latitude: 11.32, longitude: 75.93),
        GeoPoint(latitude: 11.321, longitude: 75.93),
        GeoPoint(latitude: 11.321, longitude: 75.931),
        GeoPoint(latitude: 11.32, longitude: 75.931),
        GeoPoint(latitude: 11.32, longitude: 75.93),
      ];
      final startStop = Stop(
        id: 'start',
        name: 'Loop start',
        location: loop.first,
      );
      final loopProgress = BusStopProgress(
        visitedStopIds: const {'middle'},
        currentStopId: null,
        nextStop: RouteStopOccurrence(
          routeId: 'loop',
          stopId: 'start',
          sequence: 0,
          stop: startStop,
          distanceFromStart: 0,
        ),
        upcomingStops: const [],
        direction: 'forward',
        isLoopRoute: true,
        lastEventType: 'departed',
        lastEventAt: now.subtract(const Duration(minutes: 1)),
      );
      final result = estimate(
        geometry: loop,
        stopProgress: loopProgress,
        vehicle: bus(
          point: const GeoPoint(latitude: 11.32, longitude: 75.93005),
        ),
      );
      expect(result.status, BusEtaStatus.valid);
      expect(result.distanceMeters, lessThan(20));
    },
  );

  test('rejects an equally plausible self-crossing projection', () {
    const crossing = GeoPoint(latitude: 11.32, longitude: 75.93);
    const crossRoute = [
      GeoPoint(latitude: 11.319, longitude: 75.929),
      GeoPoint(latitude: 11.321, longitude: 75.931),
      GeoPoint(latitude: 11.319, longitude: 75.931),
      GeoPoint(latitude: 11.321, longitude: 75.929),
      GeoPoint(latitude: 11.322, longitude: 75.928),
    ];
    final end = Stop(id: 'end', name: 'End', location: crossRoute.last);
    final result = estimate(
      geometry: crossRoute,
      stopProgress: BusStopProgress(
        visitedStopIds: const {},
        currentStopId: null,
        nextStop: RouteStopOccurrence(
          routeId: 'cross',
          stopId: 'end',
          sequence: 1,
          stop: end,
        ),
        upcomingStops: const [],
        direction: 'forward',
        lastEventType: 'departed',
        lastEventAt: now.subtract(const Duration(minutes: 1)),
      ),
      vehicle: bus(point: crossing, speedMps: 0),
    );
    expect(result.status, BusEtaStatus.ambiguousProjection);
  });

  test(
    'uses heading and prior cumulative progress on parallel return legs',
    () {
      const parallel = [
        GeoPoint(latitude: 11.32, longitude: 75.93),
        GeoPoint(latitude: 11.32, longitude: 75.94),
        GeoPoint(latitude: 11.3201, longitude: 75.94),
        GeoPoint(latitude: 11.3201, longitude: 75.93),
      ];
      final routeLength =
          parallel[0].distanceToMeters(parallel[1]) +
          parallel[1].distanceToMeters(parallel[2]) +
          parallel[2].distanceToMeters(parallel[3]);
      final endpoint = Stop(id: 'end', name: 'End', location: parallel.last);
      final routeProgress = BusStopProgress(
        visitedStopIds: const {},
        currentStopId: null,
        nextStop: RouteStopOccurrence(
          routeId: 'parallel',
          stopId: 'end',
          sequence: 2,
          stop: endpoint,
          distanceFromStart: routeLength,
        ),
        upcomingStops: const [],
        direction: 'forward',
        lastEventType: 'departed',
        lastEventAt: now.subtract(const Duration(minutes: 1)),
      );
      final result = estimate(
        geometry: parallel,
        stopProgress: routeProgress,
        vehicle: bus(
          point: const GeoPoint(latitude: 11.32005, longitude: 75.935),
          heading: 90,
        ),
        previousProgressMeters: 500,
      );
      expect(result.status, BusEtaStatus.valid);
      expect(result.busProgressMeters, lessThan(1000));
    },
  );

  test(
    'returns along-route ETA and deterministic one-to-forty-five minute bounds',
    () {
      final result = estimate();
      expect(result.status, BusEtaStatus.valid);
      expect(result.minutes, 3);
      expect(result.distanceMeters, greaterThan(200));
      expect(result.displayValue, '3 min');
      expect(
        estimate(previousSpeedMetersPerSecond: 10).smoothedSpeedMetersPerSecond,
        7,
      );
    },
  );

  test('rejects stale, missing progress, off-route, and invalid geometry', () {
    expect(
      estimate(vehicle: bus(stale: true)).status,
      BusEtaStatus.staleTelemetry,
    );
    expect(
      estimate(unresolved: true).status,
      BusEtaStatus.unresolvedStopProgress,
    );
    expect(
      estimate(
        vehicle: bus(
          point: const GeoPoint(latitude: 11.322, longitude: 75.932),
        ),
      ).status,
      BusEtaStatus.offRoute,
    );
    expect(estimate(geometry: const []).status, BusEtaStatus.invalidGeometry);
  });

  test('never fabricates an ETA for a dwell or stationary bus', () {
    expect(
      estimate(stopProgress: progress(current: 'a')).status,
      BusEtaStatus.dwellingAtStop,
    );
    expect(
      estimate(
        vehicle: bus(speedMps: 0),
        stopProgress: progress(
          lastType: null,
          eventAt: now.subtract(const Duration(minutes: 3)),
        ),
      ).status,
      BusEtaStatus.stationary,
    );
  });

  test('uses conservative fallback only for a recent departure pause', () {
    final eligible = estimate(
      vehicle: bus(speedMps: 0),
      stopProgress: progress(
        eventAt: now.subtract(const Duration(seconds: 30)),
      ),
    );
    expect(eligible.status, BusEtaStatus.valid);
    expect(
      estimate(
        vehicle: bus(speedMps: 0, status: BusStatus.due),
        stopProgress: progress(
          eventAt: now.subtract(const Duration(seconds: 30)),
        ),
      ).status,
      BusEtaStatus.stationary,
    );
  });

  test(
    'clamps only valid ETA values and rejects invalid speed or stop projection',
    () {
      const shortRoute = [
        GeoPoint(latitude: 11.32, longitude: 75.93),
        GeoPoint(latitude: 11.32, longitude: 75.9301),
      ];
      final shortTarget = Stop(
        id: 'near',
        name: 'Near',
        location: shortRoute.last,
      );
      final nearProgress = BusStopProgress(
        visitedStopIds: const {},
        currentStopId: null,
        nextStop: RouteStopOccurrence(
          routeId: 'short',
          stopId: 'near',
          sequence: 1,
          stop: shortTarget,
        ),
        upcomingStops: const [],
        direction: 'forward',
        lastEventType: 'departed',
        lastEventAt: now.subtract(const Duration(minutes: 1)),
      );
      expect(
        estimate(
          geometry: shortRoute,
          stopProgress: nearProgress,
          vehicle: bus(
            point: const GeoPoint(latitude: 11.32, longitude: 75.93001),
            speedMps: 50,
          ),
        ).minutes,
        1,
      );
      final farRoute = [
        route.first,
        const GeoPoint(latitude: 11.32, longitude: 76.13),
      ];
      final farTarget = Stop(id: 'far', name: 'Far', location: farRoute.last);
      expect(
        estimate(
          geometry: farRoute,
          stopProgress: progress(targetOverride: farTarget),
          vehicle: bus(speedMps: 0.6),
        ).minutes,
        45,
      );
      expect(
        estimate(vehicle: bus(speedMps: -1)).status,
        BusEtaStatus.invalidSpeed,
      );
      final speedMissingBus = bus().copyWith(
        position: bus().position.copyWith(hasSpeed: false),
      );
      expect(
        estimate(vehicle: speedMissingBus).status,
        BusEtaStatus.invalidSpeed,
      );
      expect(
        estimate(
          stopProgress: progress(
            targetOverride: const Stop(
              id: 'off',
              name: 'Off route',
              location: GeoPoint(latitude: 11.34, longitude: 76),
            ),
          ),
        ).status,
        BusEtaStatus.stopProjectionUnavailable,
      );
    },
  );
}
