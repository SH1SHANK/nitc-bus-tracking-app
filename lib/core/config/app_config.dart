/// Compile-time & runtime environment configuration for Tracklet.
///
/// Values can be supplied via `--dart-define` or `--dart-define-from-file=config/env.json`.
class AppConfig {
  const AppConfig._();

  static const String appName = 'Tracklet';
  static const String appVersion = '1.0.0';

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const bool isProduction = environment == 'production';

  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // Mapbox public client configuration. Never place a secret token here.
  static const String mapboxPublicToken = String.fromEnvironment(
    'MAPBOX_PUBLIC_TOKEN',
    defaultValue: '',
  );

  // OneSignal Configuration
  static const String onesignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: '',
  );

  static bool get hasOneSignalAppId => onesignalAppId.isNotEmpty;

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

  // Campus Geolocation Anchor (NITC Campus Center: 11.3216, 75.9337)
  static const double campusCenterLat = 11.3216;
  static const double campusCenterLng = 75.9337;
  static const double defaultZoom = 16.5;
  static const String campusName = 'National Institute of Technology Calicut';
}
