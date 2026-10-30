import 'package:flutter/foundation.dart';

/// Compile-time & runtime environment configuration for Tracklet.
///
/// Values can be supplied via `--dart-define` or `--dart-define-from-file=config/env.json`.
class AppConfig {
  const AppConfig._();

  static const String appName = 'BusTracker';
  static const String appVersion = '1.0.0';

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const bool isProduction = environment == 'production';

  /// Opt in with `--dart-define=INCLUDE_SIMULATED_BUSES=true` for map testing.
  /// Production builds always keep simulator rows out of rider results.
  static const bool includeSimulatedBuses =
      !isProduction &&
      bool.fromEnvironment('INCLUDE_SIMULATED_BUSES', defaultValue: false);

  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fnngudikrvelpuhngtlw.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZubmd1ZGlrcnZlbHB1aG5ndGx3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE0Mjc0MDAsImV4cCI6MjEwNzAwMzQwMH0.K7L2ESSZjV3R7OCwcOy_WA8XNCivIrUqZGRMitRrMEc',
  );

  static bool get hasSupabaseCredentials =>
      hasValidSupabaseConfiguration(supabaseUrl, supabaseAnonKey, environment);

  static bool hasValidSupabaseConfiguration(
    String url,
    String anonKey,
    String selectedEnvironment,
  ) =>
      isSupportedEnvironment(selectedEnvironment) &&
      isValidServiceUrl(url, selectedEnvironment) &&
      anonKey.trim().isNotEmpty;

  static bool isSupportedEnvironment(String value) =>
      const {'development', 'staging', 'production'}.contains(value);

  static bool isValidServiceUrl(String value, String environment) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return false;
    }
    if (environment == 'development') {
      return uri.scheme == 'https' ||
          (uri.scheme == 'http' &&
              const {'localhost', '127.0.0.1', '10.0.2.2'}.contains(uri.host));
    }
    return const {'staging', 'production'}.contains(environment) &&
        uri.scheme == 'https';
  }

  // Supabase CAPTCHA Bot Protection Configuration (Cloudflare Turnstile or hCaptcha)
  static const bool captchaEnabled = bool.fromEnvironment(
    'CAPTCHA_ENABLED',
    defaultValue: true,
  );

  static const String captchaSiteKey = String.fromEnvironment(
    'CAPTCHA_SITE_KEY',
    defaultValue: '0x4AAAAAAFXxHTiFZHgWmlcA',
  );

  static const String captchaProvider = String.fromEnvironment(
    'CAPTCHA_PROVIDER',
    defaultValue: 'turnstile', // 'turnstile' or 'hcaptcha'
  );

  static bool get isCaptchaConfigured =>
      captchaEnabled && captchaSiteKey.isNotEmpty;

  // Mapbox Configuration
  static const String mapboxPublicToken = String.fromEnvironment(
    'MAPBOX_PUBLIC_TOKEN',
    defaultValue: String.fromEnvironment('MAP_PUBLIC_KEY', defaultValue: ''),
  );

  static const String mapboxStyleUrl = String.fromEnvironment(
    'MAPBOX_STYLE_URL',
    defaultValue: 'mapbox://styles/mapbox/streets-v12',
  );

  static const String mapboxDarkStyleUrl = String.fromEnvironment(
    'MAPBOX_DARK_STYLE_URL',
    defaultValue: 'mapbox://styles/mapbox/dark-v11',
  );

  @visibleForTesting
  static String? testMapboxTokenOverride;

  @visibleForTesting
  static String? testMapboxStyleOverride;

  @visibleForTesting
  static String? testMapboxDarkStyleOverride;

  static String get effectiveMapboxPublicToken =>
      testMapboxTokenOverride ?? mapboxPublicToken;

  static String get effectiveMapboxStyleUrl =>
      testMapboxStyleOverride ?? mapboxStyleUrl;

  static String get effectiveMapboxDarkStyleUrl =>
      testMapboxDarkStyleOverride ?? mapboxDarkStyleUrl;

  static String effectiveMapboxStyleUrlForTheme(bool isDark) =>
      isDark ? effectiveMapboxDarkStyleUrl : effectiveMapboxStyleUrl;

  static bool get isMapboxConfigured =>
      effectiveMapboxPublicToken.trim().isNotEmpty;

  // Fastify Telemetry & Admin Backend Configuration
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://backend-bus-tracker-1.onrender.com',
  );

  static String get backendUrl =>
      isValidServiceUrl(_backendUrl, environment) ? _backendUrl : '';

  // Campus Geolocation Anchor (NITC Campus Center: 11.3216, 75.9337)
  static const double campusCenterLat = 11.3216;
  static const double campusCenterLng = 75.9337;
  static const double defaultZoom = 16.5;
  static const String campusName = 'National Institute of Technology Calicut';
}
