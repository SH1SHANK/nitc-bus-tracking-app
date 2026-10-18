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

  // Map Tile Provider Configuration Boundary
  // Note: OpenStreetMap standard tiles are provided as a dev fallback.
  // In production, point MAP_TILE_URL_TEMPLATE to a dedicated tile server (MapTiler, Stadia, Protomaps, etc.)
  static const String mapTileUrlTemplate = String.fromEnvironment(
    'MAP_TILE_URL_TEMPLATE',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static const String mapAttribution = String.fromEnvironment(
    'MAP_ATTRIBUTION',
    defaultValue: '© OpenStreetMap contributors',
  );

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

  /// Mapbox raster tile URL template for flutter_map TileLayer based on dark/light mode.
  /// Converts `mapbox://styles/{owner}/{style_id}` into:
  /// `https://api.mapbox.com/styles/v1/{owner}/{style_id}/tiles/256/{z}/{x}/{y}{r}?access_token={token}`
  static String mapboxTileUrlTemplateForTheme(bool isDark) {
    if (!isMapboxConfigured) return '';
    final style = effectiveMapboxStyleUrlForTheme(isDark).trim();
    String owner = 'mapbox';
    String styleId = isDark ? 'dark-v11' : 'streets-v12';

    if (style.startsWith('mapbox://styles/')) {
      final path = style.substring('mapbox://styles/'.length);
      final parts = path.split('/');
      if (parts.length >= 2) {
        owner = parts[0];
        styleId = parts[1];
      }
    } else if (style.startsWith('http://') || style.startsWith('https://')) {
      final uri = Uri.tryParse(style);
      if (uri != null) {
        final segments = uri.pathSegments;
        final stylesIdx = segments.indexOf('styles');
        if (stylesIdx != -1 && segments.length > stylesIdx + 2) {
          final after = segments[stylesIdx + 1];
          if (after == 'v1' && segments.length > stylesIdx + 3) {
            owner = segments[stylesIdx + 2];
            styleId = segments[stylesIdx + 3];
          } else {
            owner = segments[stylesIdx + 1];
            styleId = segments[stylesIdx + 2];
          }
        }
      }
    }

    final token = effectiveMapboxPublicToken.trim();
    return 'https://api.mapbox.com/styles/v1/$owner/$styleId/tiles/256/{z}/{x}/{y}{r}?access_token=$token';
  }

  static String get mapboxTileUrlTemplate =>
      mapboxTileUrlTemplateForTheme(false);

  static const String mapboxAttribution =
      '© Mapbox © OpenStreetMap contributors';

  // Fastify Telemetry & Admin Backend Configuration
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://backend-bus-tracker-1.onrender.com',
  );

  static String get backendUrl =>
      isValidServiceUrl(_backendUrl, environment) ? _backendUrl : '';

  // Hardware Simulator Credentials (from Flutter Android App Workbench)
  static const String defaultSimulatorDeviceId = 'NITC-BUS-SIM-001';
  static const String defaultSimulatorSecret =
      'SimTrackerSecureKey2026_NitcPass#1';
  static const String defaultSimulatorBusNumber = 'BUS-SIM-001';

  // Campus Geolocation Anchor (NITC Campus Center: 11.3216, 75.9337)
  static const double campusCenterLat = 11.3216;
  static const double campusCenterLng = 75.9337;
  static const double defaultZoom = 16.5;
  static const String campusName = 'National Institute of Technology Calicut';
}
