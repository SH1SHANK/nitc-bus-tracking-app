import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../core/logging/app_logger.dart';

class OneSignalService {
  static const String appId = '1cfe8b1f-46bf-4af5-acc7-0032fcd48efa';
  static bool _initialized = false;
  static bool _configured = false;
  static bool _dialogShown = false;

  static bool get isAvailable => _initialized && _configured;

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

      if (kIsWeb) {
        await OneSignal.initialize(targetAppId);
      } else if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        await OneSignal.initialize(targetAppId);
      }

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

  /// Displays the official OneSignal SDK integration complete dialog once
  static void showIntegrationCompleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Your OneSignal SDK integration is complete!'),
            content: const Text(
              'You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  unawaited(OneSignal.Notifications.requestPermission(true));
                },
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  /// Sets up the push subscription observer to confirm server-assigned registration
  /// and trigger the verification dialog as mandated by OneSignal integration guidelines.
  static void setupPushSubscriptionObserver(
    BuildContext context, {
    void Function(String subscriptionId)? onRegistered,
  }) {
    void maybeShow(String? id) {
      if (isRegisteredSubscription(id) && !_dialogShown) {
        _dialogShown = true;
        if (context.mounted) {
          showIntegrationCompleteDialog(context);
        }
        if (id != null && onRegistered != null) {
          onRegistered(id);
        }
      }
    }

    OneSignal.User.pushSubscription.addObserver((state) {
      maybeShow(state.current.id);
    });

    // Evaluate current value immediately in case ID was assigned before observer attached
    maybeShow(OneSignal.User.pushSubscription.id);
  }

  /// Request push notification permissions from user
  static Future<bool> requestPermission() async {
    try {
      return await OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      AppLogger.warning(
        'Error requesting OneSignal permission: $e',
        tag: 'OneSignalService',
      );
      return false;
    }
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
    try {
      OneSignal.Notifications.addClickListener(handler);
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
