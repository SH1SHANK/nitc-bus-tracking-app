import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/preferences/user_preferences.dart';
import '../design_system/theme/tracklet_theme.dart';
import '../design_system/tokens/motion.dart';
import '../services/notifications/notification_navigation.dart';
import '../services/notifications/notification_push_state.dart';
import '../services/notifications/onesignal_service.dart';
import 'router.dart';

/// Root Tracklet application widget.
class TrackletApp extends ConsumerStatefulWidget {
  const TrackletApp({super.key});

  @override
  ConsumerState<TrackletApp> createState() => _TrackletAppState();
}

class _TrackletAppState extends ConsumerState<TrackletApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_reconcilePushPreference());
    });
  }

  Future<void> _reconcilePushPreference() async {
    final preference =
        ref.read(userPreferencesProvider).pushNotificationsEnabled;
    final pushState = await OneSignalService.reconcilePushPreference(
      preference,
    );
    if (!mounted ||
        pushState == PushNotificationState.unavailable ||
        pushState == PushNotificationState.registrationPending) {
      return;
    }
    final enabled = pushState == PushNotificationState.enabled;
    if (preference != enabled) {
      await ref
          .read(userPreferencesProvider.notifier)
          .setPushNotificationsEnabled(enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        FlutterNativeSplash.remove();
      } catch (_) {
        // Silently ignore in test harnesses or unsupported platforms
      }
    });

    final router = ref.watch(routerProvider);
    OneSignalService.setNotificationClickListener((event) {
      router.go(notificationDestination(event.notification.additionalData));
    });
    final userPreferences = ref.watch(userPreferencesProvider);

    final themeMode = switch (userPreferences.themeMode) {
      'Dark' => ThemeMode.dark,
      'Light' => ThemeMode.light,
      _ => ThemeMode.system,
    };

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: TrackletTheme.lightTheme,
      darkTheme: TrackletTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: TrackletMotion.tabSwitch,
      themeAnimationCurve: TrackletMotion.standardCurve,
      routerConfig: router,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: TrackletTheme.systemUiOverlayStyle(isDark: isDark),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
