import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';

/// Initializes Supabase SDK if credentials are provided in [AppConfig].
Future<void> initializeSupabase() async {
  if (AppConfig.hasSupabaseCredentials) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppConfig.supabaseAnonKey,
      );
      AppLogger.info('Supabase initialized successfully');
    } catch (e, st) {
      AppLogger.error(
        'Failed to initialize Supabase',
        error: e,
        stackTrace: st,
      );
    }
  } else {
    AppLogger.info(
      'Supabase credentials are not configured; transit data is unavailable.',
    );
  }
}

/// Riverpod provider for accessing Supabase client instance safely.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (AppConfig.hasSupabaseCredentials) {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
  return null;
});
