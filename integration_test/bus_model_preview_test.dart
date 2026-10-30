import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:tracklet/core/config/app_config.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/data/campus/campus_building_repository.dart';
import 'package:tracklet/data/transit/bus.dart';
import 'package:tracklet/data/transit/bus_position.dart';
import 'package:tracklet/data/transit/transit_repository.dart';
import 'package:tracklet/design_system/theme/tracklet_theme.dart';
import 'package:tracklet/features/home/providers/home_provider.dart';
import 'package:tracklet/features/map/map_screen.dart';
import 'package:tracklet/services/location/location_service.dart';

import '../test/features/map/map_screen_test.dart' as fixtures;

class _PreviewLocationNotifier extends LocationNotifier {
  @override
  LocationState build() =>
      const LocationState(permissionState: LocationPermissionState.denied);

  @override
  Future<void> refreshLocationIfPermitted() async {}

  @override
  Future<GeoPoint?> requestAndFetchLocation() async => null;
}

class _PreviewRoot extends StatefulWidget {
  const _PreviewRoot({super.key});

  @override
  State<_PreviewRoot> createState() => _PreviewRootState();
}

class _PreviewRootState extends State<_PreviewRoot> {
  bool dark = false;
  bool recolored = false;

  void setRecolored(bool value) => setState(() => recolored = value);

  void setDark(bool value) => setState(() => dark = value);

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: TrackletTheme.lightTheme,
    darkTheme: TrackletTheme.darkTheme,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: MapScreen(
      busBodyColors:
          recolored ? const {'preview-bus': Color(0xff20bba8)} : const {},
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('renders and recolors the live bus model across themes', (
    tester,
  ) async {
    MapboxOptions.setAccessToken(AppConfig.effectiveMapboxPublicToken.trim());
    final now = DateTime.now();
    final bus = Bus(
      id: 'preview-bus',
      name: 'Preview bus',
      numberPlate: 'PREVIEW',
      routeId: 'route-1',
      status: BusStatus.live,
      position: BusPosition(
        point: const GeoPoint(latitude: 11.32168, longitude: 75.93367),
        heading: 90,
        speedKmH: 18,
        timestamp: now,
      ),
      lastUpdated: now,
    );
    final rootKey = GlobalKey<_PreviewRootState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transitRepositoryProvider.overrideWithValue(
            fixtures.TestTransitRepository(),
          ),
          campusBuildingRepositoryProvider.overrideWithValue(
            fixtures.TestCampusBuildingRepository(),
          ),
          activeBusesStreamProvider.overrideWith((ref) => Stream.value([bus])),
          locationStateProvider.overrideWith(_PreviewLocationNotifier.new),
        ],
        child: _PreviewRoot(key: rootKey),
      ),
    );
    await tester.pump();
    await Future<void>.delayed(const Duration(seconds: 60));
    debugPrint('BUS_MODEL_DEFAULT_READY');
    await Future<void>.delayed(const Duration(seconds: 5));

    rootKey.currentState!.setRecolored(true);
    await tester.pump();
    await Future<void>.delayed(const Duration(seconds: 5));
    debugPrint('BUS_MODEL_CUSTOM_COLOR_READY');

    rootKey.currentState!.setDark(true);
    await tester.pump();
    await Future<void>.delayed(const Duration(seconds: 60));
    debugPrint('BUS_MODEL_DARK_READY');
    await Future<void>.delayed(const Duration(seconds: 5));
  });
}
