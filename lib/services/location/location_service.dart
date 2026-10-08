import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/geo/geo_point.dart';
import '../../core/logging/app_logger.dart';

enum LocationPermissionState {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
  unknown,
}

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

  LocationState copyWith({
    GeoPoint? currentLocation,
    LocationPermissionState? permissionState,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      permissionState: permissionState ?? this.permissionState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Platform-neutral location service wrapper around geolocator.
class LocationService {
  LocationService();

  StreamSubscription<Position>? _positionSubscription;

  Future<LocationPermissionState> checkPermission() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return LocationPermissionState.serviceDisabled;
    }

    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  Future<LocationPermissionState> requestPermission() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return LocationPermissionState.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return _mapPermission(permission);
  }

  Future<GeoPoint?> getCurrentLocation() async {
    final perm = await requestPermission();
    if (perm != LocationPermissionState.granted) {
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return GeoPoint(latitude: pos.latitude, longitude: pos.longitude);
    } catch (e, st) {
      AppLogger.warning(
        'Failed to obtain current location: $e',
        stackTrace: st,
      );
      return null;
    }
  }

  Stream<GeoPoint> streamLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
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
      LocationPermission.deniedForever =>
        LocationPermissionState.permanentlyDenied,
      LocationPermission.unableToDetermine => LocationPermissionState.unknown,
    };
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(service.dispose);
  return service;
});

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    return const LocationState();
  }

  Future<void> requestAndFetchLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final service = ref.read(locationServiceProvider);

    final perm = await service.requestPermission();
    if (perm != LocationPermissionState.granted) {
      state = state.copyWith(
        isLoading: false,
        permissionState: perm,
        errorMessage: _getErrorMessage(perm),
      );
      return;
    }

    final point = await service.getCurrentLocation();
    state = state.copyWith(
      isLoading: false,
      permissionState: LocationPermissionState.granted,
      currentLocation: point,
    );
  }

  static String _getErrorMessage(LocationPermissionState perm) {
    return switch (perm) {
      LocationPermissionState.serviceDisabled =>
        'Location services are disabled on your device.',
      LocationPermissionState.denied => 'Location permission was denied.',
      LocationPermissionState.permanentlyDenied =>
        'Location permission is permanently denied.',
      _ => 'Unable to determine location.',
    };
  }
}

final locationStateProvider = NotifierProvider<LocationNotifier, LocationState>(
  () {
    return LocationNotifier();
  },
);
