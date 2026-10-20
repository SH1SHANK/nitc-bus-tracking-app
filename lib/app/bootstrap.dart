import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logging/app_logger.dart';
import '../data/supabase/supabase_client_provider.dart';
import '../design_system/tokens/colors.dart';
import '../services/notifications/onesignal_service.dart';
import '../services/storage/storage_service.dart';
import 'app.dart';

/// Bootstraps the application services, Riverpod overrides, and clean URL strategy.
Future<void> bootstrap() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  try {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  } catch (_) {
    // Gracefully ignore in non-native or test harnesses
  }
  _installGlobalErrorHandlers();

  // Configure edge-to-edge system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: TrackletColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Configure clean path URLs on Web (removes '#' fragment)
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  AppLogger.info('Bootstrapping BusTracker...');

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize Supabase if credentials are provided
  await initializeSupabase();

  // Initialize OneSignal Push Notifications (Client-side)
  await OneSignalService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
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
