import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../design_system/theme/tracklet_theme.dart';
import 'router.dart';

/// Root Tracklet application widget.
class TrackletApp extends ConsumerWidget {
  const TrackletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: TrackletTheme.lightTheme,
      routerConfig: router,
    );
  }
}
