import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../core/logging/app_logger.dart';
import 'notification_push_state.dart';

class OneSignalService {
  static const String appId = '1cfe8b1f-46bf-4af5-acc7-0032fcd48efa';
  static bool _initialized = false;
  static bool _configured = false;
  static bool _clickListenerRegistered = false;

  static bool get isAvailable => _initialized && _configured;

  static bool get isPushEnabled =>
      isAvailable &&
      OneSignal.Notifications.permission &&
      (OneSignal.User.pushSubscription.optedIn ?? false) &&
      isRegisteredSubscription(OneSignal.User.pushSubscription.id);

  /// Initialize OneSignal with official App ID before runApp().
  static Future<void> initialize({String? customAppId}) async {
    if (_initialized) return;

    final targetAppId =
        customAppId ??
        const String.fromEnvironment('ONESIGNAL_APP_ID', defaultValue: appId);

    try {
      // Set log level for debugging during integration/development
      if (kDebugMode) {
        unawaited(OneSignal.Debug.setLogLevel(OSLogLevel.verbose));
      }

      final supportedPlatform =
          kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
      if (!supportedPlatform) return;
      await OneSignal.initialize(targetAppId);

      _configured = true;
      _initialized = true;
      AppLogger.info(
        'OneSignal initialized successfully with App ID: $targetAppId',
        tag: 'OneSignalService',
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to initialize OneSignal',
        error: e,
        stackTrace: st,
        tag: 'OneSignalService',
      );
    }
  }

  /// Evaluates whether a push subscription ID is a real server-assigned ID (non-empty & not local-)
  static bool isRegisteredSubscription(String? id) =>
      id != null && id.isNotEmpty && !id.startsWith('local-');

  /// Persists a subscription only after permission and OneSignal opt-in are active.
  static void setupPushSubscriptionObserver({
    void Function(String subscriptionId)? onRegistered,
  }) {
    void registerIfReady(String? id, bool optedIn) {
      if (optedIn && isRegisteredSubscription(id) && id != null) {
        onRegistered?.call(id);
      }
    }

    OneSignal.User.pushSubscription.addObserver((state) {
      registerIfReady(state.current.id, state.current.optedIn);
    });

    registerIfReady(
      OneSignal.User.pushSubscription.id,
      OneSignal.User.pushSubscription.optedIn ?? false,
    );
  }

  static Future<PushNotificationState> getPushNotificationState() async {
    if (!isAvailable) return PushNotificationState.unavailable;
    try {
      final canRequestPermission = await OneSignal.Notifications.canRequest();
      return resolvePushNotificationState(
        available: true,
        permissionGranted: OneSignal.Notifications.permission,
        canRequestPermission: canRequestPermission,
        optedIn: OneSignal.User.pushSubscription.optedIn ?? false,
        subscriptionId: OneSignal.User.pushSubscription.id,
      );
    } catch (e) {
      AppLogger.warning(
        'Error checking OneSignal push readiness: $e',
        tag: 'OneSignalService',
      );
      return PushNotificationState.unavailable;
    }
  }

  /// Requests permission only from the Settings action and waits for a real subscription ID.
  static Future<PushNotificationState> enablePushNotifications() async {
    if (!isAvailable) return PushNotificationState.unavailable;
    try {
      final permissionGranted = await OneSignal.Notifications.requestPermission(
        true,
      );
      if (!permissionGranted) return await getPushNotificationState();
      await OneSignal.User.pushSubscription.optIn();
      return await _waitForPushRegistration();
    } catch (e) {
      AppLogger.warning(
        'Error enabling OneSignal push notifications: $e',
        tag: 'OneSignalService',
      );
      final current = await getPushNotificationState();
      return current == PushNotificationState.disabled ||
              current == PushNotificationState.registrationPending
          ? PushNotificationState.registrationFailed
          : current;
    }
  }

  static Future<PushNotificationState> _waitForPushRegistration() async {
    if (isPushEnabled) return PushNotificationState.enabled;

    final registered = Completer<void>();
    late final OnPushSubscriptionChangeObserver observer;
    observer = (_) {
      if (isPushEnabled && !registered.isCompleted) registered.complete();
    };
    OneSignal.User.pushSubscription.addObserver(observer);
    try {
      if (isPushEnabled) return PushNotificationState.enabled;
      await registered.future.timeout(const Duration(seconds: 15));
      return PushNotificationState.enabled;
    } on TimeoutException {
      return PushNotificationState.registrationFailed;
    } finally {
      OneSignal.User.pushSubscription.removeObserver(observer);
    }
  }

  /// Stops OneSignal delivery for this device without changing auth or OS permission.
  static Future<bool> disablePushNotifications() async {
    if (!isAvailable) return false;
    if (!(OneSignal.User.pushSubscription.optedIn ?? false)) return true;
    final disabled = Completer<void>();
    late final OnPushSubscriptionChangeObserver observer;
    observer = (state) {
      if (!state.current.optedIn && !disabled.isCompleted) disabled.complete();
    };
    OneSignal.User.pushSubscription.addObserver(observer);
    try {
      await OneSignal.User.pushSubscription.optOut();
      if (!(OneSignal.User.pushSubscription.optedIn ?? false)) return true;
      await disabled.future.timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      AppLogger.warning(
        'Error disabling OneSignal push notifications: $e',
        tag: 'OneSignalService',
      );
      return false;
    } finally {
      OneSignal.User.pushSubscription.removeObserver(observer);
    }
  }

  /// Reconciles a saved explicit choice without ever prompting during startup.
  static Future<PushNotificationState> reconcilePushPreference(
    bool? preference,
  ) async {
    if (!isAvailable) return PushNotificationState.unavailable;
    if (preference == false &&
        (OneSignal.User.pushSubscription.optedIn ?? false)) {
      await disablePushNotifications();
    }
    return getPushNotificationState();
  }

  /// Associate authenticated Supabase user ID with OneSignal external_id
  static Future<void> login(String userId) async {
    if (!isAvailable) return;
    try {
      await OneSignal.login(userId);
      AppLogger.info(
        'Logged into OneSignal with authenticated user.',
        tag: 'OneSignalService',
      );
    } catch (e) {
      AppLogger.warning(
        'Error logging into OneSignal: $e',
        tag: 'OneSignalService',
      );
    }
  }

  /// Clear user association upon logout
  static Future<void> logout() async {
    if (!isAvailable) return;
    try {
      await OneSignal.logout();
      AppLogger.info('Logged out of OneSignal', tag: 'OneSignalService');
    } catch (e) {
      AppLogger.warning(
        'Error logging out of OneSignal: $e',
        tag: 'OneSignalService',
      );
    }
  }

  /// Set user email
  static void setEmail(String email) {
    try {
      OneSignal.User.addEmail(email);
    } catch (e) {
      AppLogger.warning(
        'Error setting email on OneSignal: $e',
        tag: 'OneSignalService',
      );
    }
  }

  /// Set user SMS number
  static void setSmsNumber(String number) {
    try {
      OneSignal.User.addSms(number);
    } catch (e) {
      AppLogger.warning(
        'Error setting SMS on OneSignal: $e',
        tag: 'OneSignalService',
      );
    }
  }

  /// Add custom tags to user
  static void setTag(String key, String value) {
    try {
      OneSignal.User.addTagWithKey(key, value);
    } catch (e) {
      AppLogger.warning(
        'Error setting tag on OneSignal: $e',
        tag: 'OneSignalService',
      );
    }
  }

  /// Retrieve current device push subscription ID if available
  static String? getSubscriptionId() {
    try {
      return OneSignal.User.pushSubscription.id;
    } catch (_) {
      return null;
    }
  }

  /// Add listener for notification click events
  static void setNotificationClickListener(
    void Function(OSNotificationClickEvent) handler,
  ) {
    if (!isAvailable || _clickListenerRegistered) return;
    try {
      OneSignal.Notifications.addClickListener(handler);
      _clickListenerRegistered = true;
    } catch (e) {
      AppLogger.warning(
        'Error setting click listener: $e',
        tag: 'OneSignalService',
      );
    }
  }

  /// Add listener for notification foreground will-display events
  static void setNotificationForegroundListener(
    void Function(OSNotificationWillDisplayEvent) handler,
  ) {
    try {
      OneSignal.Notifications.addForegroundWillDisplayListener(handler);
    } catch (e) {
      AppLogger.warning(
        'Error setting foreground listener: $e',
        tag: 'OneSignalService',
      );
    }
  }
}
