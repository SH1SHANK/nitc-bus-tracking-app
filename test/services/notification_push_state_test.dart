import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/services/notifications/notification_push_state.dart';

void main() {
  group('resolvePushNotificationState', () {
    test(
      'distinguishes unavailable, permission-required, and denied states',
      () {
        expect(
          resolvePushNotificationState(available: false),
          PushNotificationState.unavailable,
        );
        expect(
          resolvePushNotificationState(
            available: true,
            permissionGranted: false,
            canRequestPermission: true,
          ),
          PushNotificationState.permissionRequired,
        );
        expect(
          resolvePushNotificationState(
            available: true,
            permissionGranted: false,
            canRequestPermission: false,
          ),
          PushNotificationState.permissionDenied,
        );
      },
    );

    test('requires opt-in and a registered subscription before enabled', () {
      expect(
        resolvePushNotificationState(
          available: true,
          permissionGranted: true,
          optedIn: false,
        ),
        PushNotificationState.disabled,
      );
      expect(
        resolvePushNotificationState(
          available: true,
          permissionGranted: true,
          optedIn: true,
          subscriptionId: 'local-pending',
        ),
        PushNotificationState.registrationPending,
      );
      expect(
        resolvePushNotificationState(
          available: true,
          permissionGranted: true,
          optedIn: true,
          subscriptionId: 'subscription-id',
        ),
        PushNotificationState.enabled,
      );
    });
  });
}
