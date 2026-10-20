enum PushNotificationState {
  checking,
  unavailable,
  permissionRequired,
  permissionDenied,
  disabled,
  registrationPending,
  registrationFailed,
  enabled,
}

PushNotificationState resolvePushNotificationState({
  required bool available,
  bool permissionGranted = false,
  bool canRequestPermission = false,
  bool optedIn = false,
  String? subscriptionId,
}) {
  if (!available) return PushNotificationState.unavailable;
  if (!permissionGranted) {
    return canRequestPermission
        ? PushNotificationState.permissionRequired
        : PushNotificationState.permissionDenied;
  }
  if (!optedIn) return PushNotificationState.disabled;
  if (subscriptionId == null ||
      subscriptionId.isEmpty ||
      subscriptionId.startsWith('local-')) {
    return PushNotificationState.registrationPending;
  }
  return PushNotificationState.enabled;
}
