import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/geo/geo_point.dart';
import '../../core/logging/app_logger.dart';

/// Exhaustive typed location permission and availability states.
enum LocationPermissionState {
  /// Initial unknown state before any check is performed.
  unknown,

  /// Asynchronously checking or requesting permission.
  checking,

  /// Permission has never been requested from the user.
  notRequested,

  /// Location permission granted (foreground while in use or always).
  granted,

  /// User denied the permission request (can be re-prompted).
  denied,

  /// User selected 'Don't ask again' or denied permanently (requires system settings).
  deniedForever,

  /// Device or browser location services (GPS) are toggled off.
  serviceDisabled,

  /// Platform or browser does not support geolocation (e.g. non-HTTPS web context).
  unsupported,

  /// Location hardware or satellites are temporarily unavailable / timed out.
  unavailable,

  /// Platform error or exception while checking/requesting location.
  error;

  bool get isGranted => this == LocationPermissionState.granted;
  bool get isDeniedForever => this == LocationPermissionState.deniedForever;
  bool get isServiceDisabled => this == LocationPermissionState.serviceDisabled;
  bool get isDenied =>
      this == LocationPermissionState.denied ||
      this == LocationPermissionState.deniedForever;
}

/// Immutable state containing current coordinates, permission state, and status.
class LocationState {
  const LocationState({
    this.currentLocation,
    this.permissionState = LocationPermissionState.unknown,
    this.isLoading = false,
    this.errorMessage,
  });

  final GeoPoint? currentLocation;
  final LocationPermissionState permissionState;
  final bool isLoading;
  final String? errorMessage;

  bool get hasPermission => permissionState == LocationPermissionState.granted;
  bool get isDeniedForever =>
      permissionState == LocationPermissionState.deniedForever;
  bool get isServiceDisabled =>
      permissionState == LocationPermissionState.serviceDisabled;
  bool get isUnavailable =>
      permissionState == LocationPermissionState.unavailable ||
      permissionState == LocationPermissionState.unsupported;

  LocationState copyWith({
    GeoPoint? currentLocation,
    LocationPermissionState? permissionState,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearLocation = false,
  }) {
    return LocationState(
      currentLocation:
          clearLocation ? null : (currentLocation ?? this.currentLocation),
      permissionState: permissionState ?? this.permissionState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Platform-neutral location service wrapper around [Geolocator].
class LocationService {
  LocationService();

  StreamSubscription<Position>? _positionSubscription;

  /// Verifies whether device location service is enabled and queries permission state.
  Future<LocationPermissionState> checkPermission() async {
    try {
      final isServiceEnabled = await isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return LocationPermissionState.serviceDisabled;
      }

      final permission = await Geolocator.checkPermission();
      return _mapPermission(permission);
    } on LocationServiceDisabledException {
      return LocationPermissionState.serviceDisabled;
    } on UnsupportedError {
      return LocationPermissionState.unsupported;
    } catch (e, st) {
      AppLogger.warning(
        'Failed to check location permission: $e',
        stackTrace: st,
      );
      return LocationPermissionState.error;
    }
  }

  /// Requests foreground location permission from the platform or browser.
  Future<LocationPermissionState> requestPermission() async {
    try {
      final isServiceEnabled = await isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return LocationPermissionState.serviceDisabled;
      }

      final current = await Geolocator.checkPermission();
      if (current == LocationPermission.always ||
          current == LocationPermission.whileInUse) {
        return LocationPermissionState.granted;
      }
      if (current == LocationPermission.deniedForever) {
        return LocationPermissionState.deniedForever;
      }

      final permission = await Geolocator.requestPermission();
      return _mapPermission(permission);
    } on LocationServiceDisabledException {
      return LocationPermissionState.serviceDisabled;
    } on UnsupportedError {
      return LocationPermissionState.unsupported;
    } catch (e, st) {
      AppLogger.warning(
        'Failed to request location permission: $e',
        stackTrace: st,
      );
      return LocationPermissionState.error;
    }
  }

  /// Checks if hardware/system location services are enabled.
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  /// Opens the device settings page for this app on supported platforms.
  Future<bool> openAppSettings() async {
    if (kIsWeb) return false;
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      AppLogger.warning('Failed to open app settings: $e');
      return false;
    }
  }

  /// Opens the system location settings page on supported platforms.
  Future<bool> openLocationSettings() async {
    if (kIsWeb) return false;
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      AppLogger.warning('Failed to open location settings: $e');
      return false;
    }
  }

  /// Retrieves the current foreground coordinates with bounded timeout.
  ///
  /// Returns `null` if permission is not granted, GPS is disabled, or fix times out.
  /// Never synthesizes fake coordinates in production.
  Future<GeoPoint?> getCurrentLocation({
    Duration timeLimit = const Duration(seconds: 10),
  }) async {
    try {
      final perm = await checkPermission();
      if (perm != LocationPermissionState.granted) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
      return GeoPoint(latitude: pos.latitude, longitude: pos.longitude);
    } on TimeoutException {
      AppLogger.warning(
        'Location request timed out after ${timeLimit.inSeconds}s',
      );
      return null;
    } on LocationServiceDisabledException {
      AppLogger.warning('Location services disabled during position fetch');
      return null;
    } catch (e, st) {
      AppLogger.warning(
        'Failed to obtain current location: $e',
        stackTrace: st,
      );
      return null;
    }
  }

  /// Streams position updates for continuous live tracking while in foreground.
  Stream<GeoPoint> streamLocation({
    int distanceFilter = 5,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).map((pos) => GeoPoint(latitude: pos.latitude, longitude: pos.longitude));
  }

  void dispose() {
    _positionSubscription?.cancel();
  }

  static LocationPermissionState _mapPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationPermissionState.granted,
      LocationPermission.denied => LocationPermissionState.denied,
      LocationPermission.deniedForever => LocationPermissionState.deniedForever,
      LocationPermission.unableToDetermine =>
        LocationPermissionState.notRequested,
    };
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(service.dispose);
  return service;
});

class LocationNotifier extends Notifier<LocationState> {
  bool _isOperationInProgress = false;

  @override
  LocationState build() {
    return const LocationState();
  }

  /// Refreshes the cached permission state without prompting the user.
  Future<LocationPermissionState> refreshPermission() async {
    final service = ref.read(locationServiceProvider);
    try {
      final perm = await service.checkPermission();
      if (state.permissionState != perm) {
        state = state.copyWith(permissionState: perm, clearError: true);
      }
      return perm;
    } catch (_) {
      state = state.copyWith(permissionState: LocationPermissionState.error);
      return LocationPermissionState.error;
    }
  }

  /// Checks permission and fetches position only if permission was already granted.
  Future<void> refreshLocationIfPermitted() async {
    if (_isOperationInProgress) return;
    _isOperationInProgress = true;
    try {
      final service = ref.read(locationServiceProvider);
      final permission = await service.checkPermission();
      state = state.copyWith(permissionState: permission);
      if (permission != LocationPermissionState.granted) return;

      final point = await service.getCurrentLocation();
      if (point != null) {
        state = state.copyWith(
          currentLocation: point,
          permissionState: LocationPermissionState.granted,
          isLoading: false,
          clearError: true,
        );
      }
    } catch (_) {
      // Location is optional; keep existing state
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// Requests permission from the user and updates the permission state.
  Future<LocationPermissionState> requestPermission() async {
    if (_isOperationInProgress) return state.permissionState;
    _isOperationInProgress = true;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final service = ref.read(locationServiceProvider);
      final perm = await service.requestPermission();
      state = state.copyWith(
        isLoading: false,
        permissionState: perm,
        errorMessage:
            perm == LocationPermissionState.granted
                ? null
                : _getErrorMessage(perm),
      );
      return perm;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        permissionState: LocationPermissionState.error,
        errorMessage:
            'An error occurred while requesting location permissions.',
      );
      return LocationPermissionState.error;
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// Requests permission and immediately acquires a GPS position if granted.
  Future<GeoPoint?> requestAndFetchLocation() async {
    if (_isOperationInProgress) return state.currentLocation;
    _isOperationInProgress = true;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final service = ref.read(locationServiceProvider);
      final perm = await service.requestPermission();

      if (perm != LocationPermissionState.granted) {
        state = state.copyWith(
          isLoading: false,
          permissionState: perm,
          errorMessage: _getErrorMessage(perm),
        );
        return null;
      }

      final point = await service.getCurrentLocation();
      if (point != null) {
        state = state.copyWith(
          isLoading: false,
          permissionState: LocationPermissionState.granted,
          currentLocation: point,
          clearError: true,
        );
        return point;
      } else {
        state = state.copyWith(
          isLoading: false,
          permissionState: LocationPermissionState.unavailable,
          errorMessage:
              'Unable to obtain current GPS location. Please check satellite visibility.',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        permissionState: LocationPermissionState.error,
        errorMessage: 'An unexpected error occurred while obtaining location.',
      );
      return null;
    } finally {
      _isOperationInProgress = false;
    }
  }

  static String _getErrorMessage(LocationPermissionState perm) {
    return switch (perm) {
      LocationPermissionState.serviceDisabled =>
        'Location services (GPS) are disabled on your device.',
      LocationPermissionState.denied => 'Location permission was denied.',
      LocationPermissionState.deniedForever =>
        'Location permission is permanently denied. Please enable it in device settings.',
      LocationPermissionState.unsupported =>
        'Location access is unsupported in this browser/environment (requires HTTPS).',
      LocationPermissionState.unavailable =>
        'GPS signal is currently unavailable.',
      LocationPermissionState.error =>
        'An error occurred while accessing location services.',
      _ => 'Unable to determine location.',
    };
  }
}

final locationStateProvider = NotifierProvider<LocationNotifier, LocationState>(
  () => LocationNotifier(),
);
