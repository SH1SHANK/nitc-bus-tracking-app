import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';

/// Notification service boundary encapsulating OneSignal push notification integration.
abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<void> setExternalUserId(String externalId);
  Future<void> removeExternalUserId();
  Future<void> setTag(String key, String value);
  Future<void> deleteTag(String key);
  void setNotificationClickListener(void Function(String? route) onClick);
}

class OneSignalNotificationService implements NotificationService {
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!AppConfig.hasOneSignalAppId) {
      AppLogger.info(
        'OneSignal App ID not configured. Notification service initialized in dummy mode.',
      );
      _isInitialized = true;
      return;
    }

    try {
      if (kIsWeb) {
        // OneSignal Web SDK initializes via web script or web integration
        AppLogger.info(
          'OneSignal Web initialization ready with ID: ${AppConfig.onesignalAppId}',
        );
      } else {
        await OneSignal.Debug.setLogLevel(OSLogLevel.warn);
        await OneSignal.initialize(AppConfig.onesignalAppId);
      }
      _isInitialized = true;
      AppLogger.info('OneSignal initialized successfully.');
    } catch (e, st) {
      AppLogger.warning('OneSignal initialization failed: $e', stackTrace: st);
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!AppConfig.hasOneSignalAppId) return false;

    try {
      if (kIsWeb) {
        return false;
      }
      return await OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      AppLogger.warning('Failed to request notification permission: $e');
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    if (!AppConfig.hasOneSignalAppId) return false;

    try {
      if (kIsWeb) {
        return false;
      }
      return OneSignal.Notifications.permission;
    } catch (e) {
      AppLogger.warning('Failed to query notification permission status: $e');
      return false;
    }
  }

  @override
  Future<void> setExternalUserId(String externalId) async {
    if (!AppConfig.hasOneSignalAppId) return;
    try {
      if (!kIsWeb) {
        await OneSignal.login(externalId);
      }
    } catch (e) {
      AppLogger.warning('Failed to set external user ID on OneSignal: $e');
    }
  }

  @override
  Future<void> removeExternalUserId() async {
    if (!AppConfig.hasOneSignalAppId) return;
    try {
      if (!kIsWeb) {
        await OneSignal.logout();
      }
    } catch (e) {
      AppLogger.warning('Failed to logout from OneSignal: $e');
    }
  }

  @override
  Future<void> setTag(String key, String value) async {
    if (!AppConfig.hasOneSignalAppId) return;
    try {
      if (!kIsWeb) {
        unawaited(OneSignal.User.addTagWithKey(key, value));
      }
    } catch (e) {
      AppLogger.warning('Failed to add OneSignal tag: $e');
    }
  }

  @override
  Future<void> deleteTag(String key) async {
    if (!AppConfig.hasOneSignalAppId) return;
    try {
      if (!kIsWeb) {
        unawaited(OneSignal.User.removeTag(key));
      }
    } catch (e) {
      AppLogger.warning('Failed to remove OneSignal tag: $e');
    }
  }

  @override
  void setNotificationClickListener(void Function(String? route) onClick) {
    if (!AppConfig.hasOneSignalAppId || kIsWeb) return;
    try {
      OneSignal.Notifications.addClickListener((event) {
        final additionalData = event.notification.additionalData;
        final route = additionalData?['route'] as String?;
        onClick(route);
      });
    } catch (e) {
      AppLogger.warning('Failed to attach notification click listener: $e');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return OneSignalNotificationService();
});
