import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/preferences/user_preferences.dart';
import '../design_system/theme/tracklet_theme.dart';
import 'router.dart';

/// Root Tracklet application widget.
class TrackletApp extends ConsumerWidget {
  const TrackletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
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
