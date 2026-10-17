import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/services/maps/map_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrackletMapView Marker Animation & Interpolation Tests', () {
    late TrackletMapController controller;

    setUp(() {
      controller = TrackletMapController();
    });

    tearDown(() {
      controller.dispose();
    });

    fmap.Marker? findMarker(WidgetTester tester, String id) {
      final markerLayerFinder = find.byType(fmap.MarkerLayer);
      if (markerLayerFinder.evaluate().isEmpty) return null;
      final markerLayer = tester.widget<fmap.MarkerLayer>(markerLayerFinder);
      final key = ValueKey('map-marker-$id');
      for (final marker in markerLayer.markers) {
        if (marker.key == key) return marker;
      }
      return null;
    }

    testWidgets(
      'multi-marker independent concurrent interpolation preserves isolated tracking',
      (tester) async {
        final t0 = DateTime.utc(2026, 10, 16, 12, 0, 0);

        final initialMarkers = [
          MapMarkerData(
            id: 'bus-alpha',
            point: const GeoPoint(latitude: 11.3200, longitude: 75.9300),
            child: const Icon(Icons.directions_bus, key: Key('icon-alpha')),
            animatePosition: true,
            sequenceNumber: 1,
            epoch: 1,
            timestamp: t0,
            speedKmH: 20,
          ),
          MapMarkerData(
            id: 'bus-beta',
            point: const GeoPoint(latitude: 11.3250, longitude: 75.9350),
            child: const Icon(Icons.directions_bus, key: Key('icon-beta')),
            animatePosition: true,
            sequenceNumber: 1,
            epoch: 1,
            timestamp: t0,
            speedKmH: 15,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: TrackletMapView(
                  controller: controller,
                  markers: initialMarkers,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final mAlphaInit = findMarker(tester, 'bus-alpha');
        final mBetaInit = findMarker(tester, 'bus-beta');
        expect(mAlphaInit, isNotNull);
        expect(mBetaInit, isNotNull);
        expect(mAlphaInit!.point.latitude, closeTo(11.3200, 1e-4));
        expect(mBetaInit!.point.latitude, closeTo(11.3250, 1e-4));

        final t1 = t0.add(const Duration(seconds: 2));
        final updatedMarkers = [
          MapMarkerData(
            id: 'bus-alpha',
            point: const GeoPoint(latitude: 11.3202, longitude: 75.9302),
            child: const Icon(Icons.directions_bus, key: Key('icon-alpha')),
            animatePosition: true,
            sequenceNumber: 2,
            epoch: 1,
            timestamp: t1,
            speedKmH: 22,
          ),
          MapMarkerData(
            id: 'bus-beta',
            point: const GeoPoint(latitude: 11.3252, longitude: 75.9352),
            child: const Icon(Icons.directions_bus, key: Key('icon-beta')),
            animatePosition: true,
            sequenceNumber: 2,
            epoch: 1,
            timestamp: t1,
            speedKmH: 18,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: TrackletMapView(
                  controller: controller,
                  markers: updatedMarkers,
                ),
              ),
            ),
          ),
        );

        // Advance 300ms into interpolation using virtual clock
        await tester.pump(const Duration(milliseconds: 300));

        final mAlphaMid = findMarker(tester, 'bus-alpha')!;
        final mBetaMid = findMarker(tester, 'bus-beta')!;

        // bus-alpha should have moved forward from 11.3200 towards 11.3202
        expect(mAlphaMid.point.latitude, greaterThan(11.3200));
        expect(mAlphaMid.point.latitude, lessThan(11.3202));

        // bus-beta should have moved forward from 11.3250 towards 11.3252
        expect(mBetaMid.point.latitude, greaterThan(11.3250));
        expect(mBetaMid.point.latitude, lessThan(11.3252));

        // Complete animation
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        final mAlphaEnd = findMarker(tester, 'bus-alpha')!;
        final mBetaEnd = findMarker(tester, 'bus-beta')!;

        expect(mAlphaEnd.point.latitude, closeTo(11.3202, 1e-4));
        expect(mAlphaEnd.point.longitude, closeTo(75.9302, 1e-4));
        expect(mBetaEnd.point.latitude, closeTo(11.3252, 1e-4));
        expect(mBetaEnd.point.longitude, closeTo(75.9352, 1e-4));
      },
    );

    testWidgets(
      'snaps position immediately without interpolation when disableAnimations is true',
      (tester) async {
        final t0 = DateTime.utc(2026, 10, 16, 12, 0, 0);

        final initialMarker = [
          MapMarkerData(
            id: 'bus-reduced-motion',
            point: const GeoPoint(latitude: 11.3200, longitude: 75.9300),
            child: const Icon(Icons.directions_bus),
            animatePosition: true,
            sequenceNumber: 1,
            epoch: 1,
            timestamp: t0,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: SizedBox(
                  width: 800,
                  height: 600,
                  child: TrackletMapView(
                    controller: controller,
                    markers: initialMarker,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final updatedMarker = [
          MapMarkerData(
            id: 'bus-reduced-motion',
            point: const GeoPoint(latitude: 11.3240, longitude: 75.9340),
            child: const Icon(Icons.directions_bus),
            animatePosition: true,
            sequenceNumber: 2,
            epoch: 1,
            timestamp: t0.add(const Duration(seconds: 2)),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: SizedBox(
                  width: 800,
                  height: 600,
                  child: TrackletMapView(
                    controller: controller,
                    markers: updatedMarker,
                  ),
                ),
              ),
            ),
          ),
        );

        // Immediate pump with 0 duration: must already be at target without interpolation
        await tester.pump();

        final mSnap = findMarker(tester, 'bus-reduced-motion')!;
        expect(mSnap.point.latitude, closeTo(11.3240, 1e-5));
        expect(mSnap.point.longitude, closeTo(75.9340, 1e-5));
      },
    );

    testWidgets(
      'filters out Null Island and invalid coordinates from rendered markers',
      (tester) async {
        const invalidMarkers = [
          MapMarkerData(
            id: 'valid-bus',
            point: GeoPoint(latitude: 11.3216, longitude: 75.9337),
            child: Icon(Icons.directions_bus),
          ),
          MapMarkerData(
            id: 'null-island-bus',
            point: GeoPoint(latitude: 0.0, longitude: 0.0),
            child: Icon(Icons.directions_bus),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: TrackletMapView(
                  controller: controller,
                  markers: invalidMarkers,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(findMarker(tester, 'valid-bus'), isNotNull);
        expect(findMarker(tester, 'null-island-bus'), isNull);
      },
    );

    testWidgets('snaps marker when reboot session increments epoch', (
      tester,
    ) async {
      final t0 = DateTime.utc(2026, 10, 16, 12, 0, 0);

      final initialMarkers = [
        MapMarkerData(
          id: 'bus-reboot',
          point: const GeoPoint(latitude: 11.3200, longitude: 75.9300),
          child: const Icon(Icons.directions_bus),
          animatePosition: true,
          sequenceNumber: 250,
          epoch: 1,
          timestamp: t0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TrackletMapView(
                controller: controller,
                markers: initialMarkers,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tracker rebooted: epoch 2, sequence reset to 1
      final rebootedMarkers = [
        MapMarkerData(
          id: 'bus-reboot',
          point: const GeoPoint(latitude: 11.3230, longitude: 75.9330),
          child: const Icon(Icons.directions_bus),
          animatePosition: true,
          sequenceNumber: 1,
          epoch: 2,
          timestamp: t0.add(const Duration(seconds: 30)),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TrackletMapView(
                controller: controller,
                markers: rebootedMarkers,
              ),
            ),
          ),
        ),
      );

      // Immediate frame should snap to new position because epoch reset triggers snap
      await tester.pump();

      final mReboot = findMarker(tester, 'bus-reboot')!;
      expect(mReboot.point.latitude, closeTo(11.3230, 1e-4));
      expect(mReboot.point.longitude, closeTo(75.9330, 1e-4));
    });

    testWidgets(
      'TrackletMapController rejects moveTo and animatedMoveTo to Null Island (0, 0)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: TrackletMapView(controller: controller),
              ),
            ),
          ),
        );
        await tester.pump();

        final initialCenter = controller.center;
        expect(initialCenter.latitude, isNot(0.0));

        // Attempt moveTo Null Island
        controller.moveTo(const GeoPoint(latitude: 0, longitude: 0));
        await tester.pump();
        expect(controller.center.latitude, initialCenter.latitude);
        expect(controller.center.longitude, initialCenter.longitude);

        // Attempt fitBounds with only Null Island points
        controller.fitBounds([const GeoPoint(latitude: 0, longitude: 0)]);
        await tester.pump();
        expect(controller.center.latitude, initialCenter.latitude);
        expect(controller.center.longitude, initialCenter.longitude);
      },
    );
  });
}
