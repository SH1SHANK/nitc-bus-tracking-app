import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_position.dart';
import 'package:tracklet/features/map/widgets/bus_marker_widget.dart';

Bus testBus({required double heading, required DateTime timestamp}) => Bus(
  id: 'private-id-not-displayed',
  name: 'Campus Bus 1',
  numberPlate: 'NITC-01',
  status: BusStatus.live,
  position: BusPosition(
    point: const GeoPoint(latitude: 11.32, longitude: 75.93),
    heading: heading,
    speedKmH: 12,
    sequenceNumber: 1,
    timestamp: timestamp,
  ),
  lastUpdated: timestamp,
);

void main() {
  testWidgets('marker rotates through the short 359 to 1 degree arc', (
    tester,
  ) async {
    final now = DateTime.now();
    Widget build(double heading) => MaterialApp(
      home: Scaffold(
        body: BusMarkerWidget(bus: testBus(heading: heading, timestamp: now)),
      ),
    );

    await tester.pumpWidget(build(359));
    await tester.pumpWidget(build(1));
    await tester.pump(const Duration(milliseconds: 175));

    final transform = tester.widget<Transform>(find.byType(Transform).first);
    expect(transform.transform.storage[0], closeTo(1, 0.001));
    expect(transform.transform.storage[1], closeTo(0, 0.02));
  });

  testWidgets('old telemetry shows a stale state without exposing its UUID', (
    tester,
  ) async {
    final staleBus = testBus(
      heading: 0,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: BusMarkerWidget(bus: staleBus))),
    );

    expect(
      find.bySemanticsLabel('Campus Bus 1, stale or offline bus'),
      findsOneWidget,
    );
    expect(find.text('private-id-not-displayed'), findsNothing);
  });

  testWidgets(
    'stationary bus (speed < 2 km/h) stays upright with pause icon at 0 rotation',
    (tester) async {
      final now = DateTime.now();
      final stationaryBus = Bus(
        id: 'stationary-bus',
        name: 'Campus Bus 2',
        numberPlate: 'NITC-02',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.32, longitude: 75.93),
          heading: 120,
          speedKmH: 0.5,
          timestamp: now,
        ),
        lastUpdated: now,
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: BusMarkerWidget(bus: stationaryBus))),
      );
      await tester.pumpAndSettle();

      final transform = tester.widget<Transform>(find.byType(Transform).first);
      // Identity rotation matrix for 0 degrees: storage[0] = 1, storage[1] = 0
      expect(transform.transform.storage[0], closeTo(1.0, 1e-4));
      expect(transform.transform.storage[1], closeTo(0.0, 1e-4));
    },
  );

  testWidgets(
    'bus without reliable hardware heading stays upright at 0 rotation',
    (tester) async {
      final now = DateTime.now();
      final noHeadingBus = Bus(
        id: 'no-heading-bus',
        name: 'Campus Bus 3',
        numberPlate: 'NITC-03',
        status: BusStatus.live,
        position: BusPosition(
          point: const GeoPoint(latitude: 11.32, longitude: 75.93),
          speedKmH: 25.0,
          timestamp: now,
        ),
        lastUpdated: now,
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: BusMarkerWidget(bus: noHeadingBus))),
      );
      await tester.pumpAndSettle();

      final transform = tester.widget<Transform>(find.byType(Transform).first);
      expect(transform.transform.storage[0], closeTo(1.0, 1e-4));
      expect(transform.transform.storage[1], closeTo(0.0, 1e-4));
    },
  );
}
