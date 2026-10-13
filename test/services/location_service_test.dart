import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/geo/geo_point.dart';
import 'package:tracklet/services/location/location_service.dart';

class FakeLocationService extends LocationService {
  LocationPermissionState checkPermissionResult =
      LocationPermissionState.unknown;
  LocationPermissionState requestPermissionResult =
      LocationPermissionState.unknown;
  GeoPoint? currentLocationResult;
  bool isServiceEnabledResult = true;
  bool openAppSettingsCalled = false;
  bool openLocationSettingsCalled = false;

  @override
  Future<LocationPermissionState> checkPermission() async =>
      checkPermissionResult;

  @override
  Future<LocationPermissionState> requestPermission() async =>
      requestPermissionResult;

  @override
  Future<bool> isLocationServiceEnabled() async => isServiceEnabledResult;

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalled = true;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCalled = true;
    return true;
  }

  @override
  Future<GeoPoint?> getCurrentLocation({
    Duration timeLimit = const Duration(seconds: 10),
  }) async => currentLocationResult;
}

void main() {
  group('LocationPermissionState Enum & Helpers', () {
    test('verifies state helper getters', () {
      expect(LocationPermissionState.granted.isGranted, isTrue);
      expect(LocationPermissionState.granted.isDenied, isFalse);
      expect(LocationPermissionState.granted.isDeniedForever, isFalse);
      expect(LocationPermissionState.granted.isServiceDisabled, isFalse);

      expect(LocationPermissionState.denied.isGranted, isFalse);
      expect(LocationPermissionState.denied.isDenied, isTrue);
      expect(LocationPermissionState.denied.isDeniedForever, isFalse);

      expect(LocationPermissionState.deniedForever.isGranted, isFalse);
      expect(LocationPermissionState.deniedForever.isDenied, isTrue);
      expect(LocationPermissionState.deniedForever.isDeniedForever, isTrue);

      expect(LocationPermissionState.serviceDisabled.isServiceDisabled, isTrue);
      expect(LocationPermissionState.unsupported.isGranted, isFalse);
      expect(LocationPermissionState.unavailable.isGranted, isFalse);
      expect(LocationPermissionState.checking.isGranted, isFalse);
      expect(LocationPermissionState.error.isGranted, isFalse);
      expect(LocationPermissionState.notRequested.isGranted, isFalse);
    });
  });

  group('LocationState', () {
    test('defaults to unknown permission state and not loading', () {
      const state = LocationState();
      expect(state.permissionState, equals(LocationPermissionState.unknown));
      expect(state.hasPermission, isFalse);
      expect(state.isDeniedForever, isFalse);
      expect(state.isServiceDisabled, isFalse);
      expect(state.isUnavailable, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.currentLocation, isNull);
      expect(state.errorMessage, isNull);
    });

    test(
      'evaluates isUnavailable for both unavailable and unsupported states',
      () {
        const state1 = LocationState(
          permissionState: LocationPermissionState.unavailable,
        );
        expect(state1.isUnavailable, isTrue);

        const state2 = LocationState(
          permissionState: LocationPermissionState.unsupported,
        );
        expect(state2.isUnavailable, isTrue);

        const state3 = LocationState(
          permissionState: LocationPermissionState.granted,
        );
        expect(state3.isUnavailable, isFalse);
      },
    );

    test(
      'copyWith updates state values and supports clearing error/location',
      () {
        const state = LocationState(
          currentLocation: GeoPoint(latitude: 11.32, longitude: 75.93),
          permissionState: LocationPermissionState.granted,
          isLoading: false,
          errorMessage: 'Sample error',
        );

        final cleared = state.copyWith(clearError: true, clearLocation: true);

        expect(cleared.currentLocation, isNull);
        expect(cleared.errorMessage, isNull);
        expect(
          cleared.permissionState,
          equals(LocationPermissionState.granted),
        );
      },
    );
  });

  group('LocationNotifier Unit Tests', () {
    late ProviderContainer container;
    late FakeLocationService fakeService;

    setUp(() {
      fakeService = FakeLocationService();
      container = ProviderContainer(
        overrides: [locationServiceProvider.overrideWithValue(fakeService)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('refreshPermission updates permissionState in notifier', () async {
      fakeService.checkPermissionResult = LocationPermissionState.granted;
      final notifier = container.read(locationStateProvider.notifier);

      final perm = await notifier.refreshPermission();
      expect(perm, equals(LocationPermissionState.granted));
      expect(
        container.read(locationStateProvider).permissionState,
        equals(LocationPermissionState.granted),
      );
    });

    test(
      'refreshLocationIfPermitted ignores fetch when permission is denied',
      () async {
        fakeService.checkPermissionResult = LocationPermissionState.denied;
        fakeService.currentLocationResult = const GeoPoint(
          latitude: 11.32,
          longitude: 75.93,
        );
        final notifier = container.read(locationStateProvider.notifier);

        await notifier.refreshLocationIfPermitted();
        final state = container.read(locationStateProvider);

        expect(state.permissionState, equals(LocationPermissionState.denied));
        expect(state.currentLocation, isNull);
      },
    );

    test(
      'refreshLocationIfPermitted fetches position when permission is granted',
      () async {
        fakeService.checkPermissionResult = LocationPermissionState.granted;
        fakeService.currentLocationResult = const GeoPoint(
          latitude: 11.321,
          longitude: 75.934,
        );
        final notifier = container.read(locationStateProvider.notifier);

        await notifier.refreshLocationIfPermitted();
        final state = container.read(locationStateProvider);

        expect(state.permissionState, equals(LocationPermissionState.granted));
        expect(
          state.currentLocation,
          equals(const GeoPoint(latitude: 11.321, longitude: 75.934)),
        );
        expect(state.isLoading, isFalse);
      },
    );

    test(
      'requestPermission updates state with deniedForever and clear error message',
      () async {
        fakeService.requestPermissionResult =
            LocationPermissionState.deniedForever;
        final notifier = container.read(locationStateProvider.notifier);

        final perm = await notifier.requestPermission();
        final state = container.read(locationStateProvider);

        expect(perm, equals(LocationPermissionState.deniedForever));
        expect(
          state.permissionState,
          equals(LocationPermissionState.deniedForever),
        );
        expect(state.isDeniedForever, isTrue);
        expect(state.errorMessage, contains('permanently denied'));
      },
    );

    test('requestPermission updates state with serviceDisabled', () async {
      fakeService.requestPermissionResult =
          LocationPermissionState.serviceDisabled;
      final notifier = container.read(locationStateProvider.notifier);

      final perm = await notifier.requestPermission();
      final state = container.read(locationStateProvider);

      expect(perm, equals(LocationPermissionState.serviceDisabled));
      expect(state.isServiceDisabled, isTrue);
      expect(state.errorMessage, contains('disabled'));
    });

    test('requestAndFetchLocation acquires position successfully', () async {
      fakeService.requestPermissionResult = LocationPermissionState.granted;
      fakeService.currentLocationResult = const GeoPoint(
        latitude: 11.322,
        longitude: 75.933,
      );
      final notifier = container.read(locationStateProvider.notifier);

      final point = await notifier.requestAndFetchLocation();
      final state = container.read(locationStateProvider);

      expect(
        point,
        equals(const GeoPoint(latitude: 11.322, longitude: 75.933)),
      );
      expect(state.hasPermission, isTrue);
      expect(state.currentLocation, equals(point));
      expect(state.errorMessage, isNull);
    });

    test(
      'requestAndFetchLocation sets unavailable state when position returns null',
      () async {
        fakeService.requestPermissionResult = LocationPermissionState.granted;
        fakeService.currentLocationResult = null;
        final notifier = container.read(locationStateProvider.notifier);

        final point = await notifier.requestAndFetchLocation();
        final state = container.read(locationStateProvider);

        expect(point, isNull);
        expect(
          state.permissionState,
          equals(LocationPermissionState.unavailable),
        );
        expect(state.isUnavailable, isTrue);
        expect(
          state.errorMessage,
          contains('Unable to obtain current GPS location'),
        );
      },
    );
  });
}
