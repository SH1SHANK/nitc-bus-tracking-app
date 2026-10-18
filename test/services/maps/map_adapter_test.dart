import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/config/app_config.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/services/maps/map_adapter.dart';
import 'package:tracklet/services/maps/map_config.dart';
import 'package:tracklet/services/maps/network_connectivity.dart';

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

  group('Mapbox Primary & Local MBTiles Fallback Tests', () {
    late TrackletMapController controller;

    setUp(() {
      controller = TrackletMapController();
      AppConfig.testMapboxTokenOverride = 'pk.test_valid_mapbox_token_12345';
      AppConfig.testMapboxStyleOverride = 'mapbox://styles/mapbox/streets-v12';
      NetworkConnectivity.testOverride = null;
    });

    tearDown(() {
      controller.dispose();
      AppConfig.testMapboxTokenOverride = null;
      AppConfig.testMapboxStyleOverride = null;
      NetworkConnectivity.testOverride = null;
    });

    test('AppConfig and MapConfig generate valid Mapbox raster tile URL templates', () {
      expect(AppConfig.isMapboxConfigured, isTrue);
      expect(
        AppConfig.mapboxTileUrlTemplate,
        'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}{r}?access_token=pk.test_valid_mapbox_token_12345',
      );
      expect(
        MapConfig.mapboxTileUrlTemplate,
        AppConfig.mapboxTileUrlTemplate,
      );

      // Custom user style test
      AppConfig.testMapboxStyleOverride =
          'mapbox://styles/tracklet_team/custom_dark_v1';
      expect(
        AppConfig.mapboxTileUrlTemplate,
        'https://api.mapbox.com/styles/v1/tracklet_team/custom_dark_v1/tiles/256/{z}/{x}/{y}{r}?access_token=pk.test_valid_mapbox_token_12345',
      );
    });

    testWidgets('renders Mapbox primary tile layer when online and configured', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TrackletMapView(
                controller: controller,
                isOnline: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Primary Mapbox tile layer is present in widget tree
      expect(find.byKey(const ValueKey('tracklet_mapbox_tile_layer')), findsOneWidget);
      // Offline fallback badge is not shown while online
      expect(find.byKey(const ValueKey('tracklet_offline_map_badge')), findsNothing);
    });

    Future<void> pumpUntilMapReady(WidgetTester tester) async {
      await tester.pump();
      await tester.runAsync(() async {
        for (var i = 0; i < 50; i++) {
          if (find.byKey(const ValueKey('tracklet_map_initializing')).evaluate().isEmpty) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pump();
    }

    testWidgets('falls back to local MBTiles and displays offline badge when offline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TrackletMapView(
                controller: controller,
                isOnline: false,
              ),
            ),
          ),
        ),
      );
      await pumpUntilMapReady(tester);

      // Mapbox primary tile layer is deactivated to stop network requests
      expect(find.byKey(const ValueKey('tracklet_mapbox_tile_layer')), findsNothing);
      // Local MBTiles basemap layer is present
      expect(find.byKey(const ValueKey('tracklet_offline_mbtiles_tile_layer')), findsOneWidget);
      // Offline fallback badge is visible to user
      expect(find.byKey(const ValueKey('tracklet_offline_map_badge')), findsOneWidget);
      expect(find.text('Offline Campus Map'), findsOneWidget);
    });

    testWidgets('switches from online Mapbox to offline local MBTiles on isOnline toggle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TrackletMapView(
                controller: controller,
                isOnline: true,
              ),
            ),
          ),
        ),
      );
      await pumpUntilMapReady(tester);
      expect(find.byKey(const ValueKey('tracklet_mapbox_tile_layer')), findsOneWidget);
      expect(find.byKey(const ValueKey('tracklet_offline_map_badge')), findsNothing);

      // Transition to offline
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TrackletMapView(
                controller: controller,
                isOnline: false,
              ),
            ),
          ),
        ),
      );
      await pumpUntilMapReady(tester);

      expect(find.byKey(const ValueKey('tracklet_mapbox_tile_layer')), findsNothing);
      expect(find.byKey(const ValueKey('tracklet_offline_mbtiles_tile_layer')), findsOneWidget);
      expect(find.byKey(const ValueKey('tracklet_offline_map_badge')), findsOneWidget);

      // Reconnect online
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TrackletMapView(
                controller: controller,
                isOnline: true,
              ),
            ),
          ),
        ),
      );
      await pumpUntilMapReady(tester);

      expect(find.byKey(const ValueKey('tracklet_mapbox_tile_layer')), findsOneWidget);
      expect(find.byKey(const ValueKey('tracklet_offline_map_badge')), findsNothing);
    });

    testWidgets('falls back to local MBTiles when tile error callback is invoked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TrackletMapView(
                controller: controller,
                isOnline: true,
              ),
            ),
          ),
        ),
      );
      await pumpUntilMapReady(tester);
      expect(find.byKey(const ValueKey('tracklet_mapbox_tile_layer')), findsOneWidget);

      // Extract Mapbox TileLayer widget and invoke errorTileCallback
      final tileLayer = tester.widget<fmap.TileLayer>(
        find.byKey(const ValueKey('tracklet_mapbox_tile_layer')),
      );
      expect(tileLayer.errorTileCallback, isNotNull);

      // Simulate network socket exception on tile request
      final tileImage = fmap.TileImage(
        vsync: const TestVSync(),
        coordinates: const fmap.TileCoordinates(1, 1, 1),
        imageProvider: const AssetImage('assets/branding/bustracker_bus_icon.png'),
        onLoadComplete: (_) {},
        onLoadError: (_, _, _) {},
        tileDisplay: const fmap.TileDisplay.instantaneous(),
        errorImage: null,
        cancelLoading: Completer<void>(),
      );

      tileLayer.errorTileCallback!(
        tileImage,
        'SocketException: Failed host lookup: api.mapbox.com',
        null,
      );

      await pumpUntilMapReady(tester);

      // Mapbox is deactivated and offline fallback badge appears
      expect(find.byKey(const ValueKey('tracklet_mapbox_tile_layer')), findsNothing);
      expect(find.byKey(const ValueKey('tracklet_offline_mbtiles_tile_layer')), findsOneWidget);
      expect(find.byKey(const ValueKey('tracklet_offline_map_badge')), findsOneWidget);
    });

    testWidgets('uses local MBTiles directly when Mapbox token is unconfigured', (tester) async {
      AppConfig.testMapboxTokenOverride = ''; // Unconfigured

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
      await pumpUntilMapReady(tester);

      expect(find.byKey(const ValueKey('tracklet_mapbox_tile_layer')), findsNothing);
      expect(find.byKey(const ValueKey('tracklet_offline_mbtiles_tile_layer')), findsOneWidget);
      // Since Mapbox was never configured, offline badge is not needed
      expect(find.byKey(const ValueKey('tracklet_offline_map_badge')), findsNothing);
    });
  });
}
