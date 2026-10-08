import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/services/location/location_service.dart';

void main() {
  group('LocationState', () {
    test('defaults to unknown permission state and not loading', () {
      const state = LocationState();
      expect(state.permissionState, equals(LocationPermissionState.unknown));
      expect(state.hasPermission, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.currentLocation, isNull);
    });

    test('copyWith updates state values properly', () {
      const state = LocationState();
      final updated = state.copyWith(
        permissionState: LocationPermissionState.granted,
        isLoading: true,
      );

      expect(updated.permissionState, equals(LocationPermissionState.granted));
      expect(updated.hasPermission, isTrue);
      expect(updated.isLoading, isTrue);
    });
  });
}
