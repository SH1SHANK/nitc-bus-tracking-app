import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logging/app_logger.dart';
import '../data/supabase/supabase_client_provider.dart';
import '../services/maps/mapbox_initializer.dart';
import '../services/notifications/notification_service.dart';
import '../services/storage/storage_service.dart';
import 'app.dart';

/// Bootstraps the application services, Riverpod overrides, and clean URL strategy.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandlers();

  // Configure clean path URLs on Web (removes '#' fragment)
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  AppLogger.info('Bootstrapping Tracklet...');

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize Supabase if credentials are provided
  await initializeSupabase();

  // Initialize OneSignal
  final notificationService = OneSignalNotificationService();
  await notificationService.initialize();

  // Initialize Mapbox Maps SDK access token
  await MapboxInitializer.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const TrackletApp(),
    ),
  );
}

void _installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Unhandled Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
      tag: 'FlutterError',
    );
  };

  ui.PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.error(
      'Unhandled asynchronous error',
      error: error,
      stackTrace: stackTrace,
      tag: 'PlatformDispatcher',
    );
    return true;
  };
}
