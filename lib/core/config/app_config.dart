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
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

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

  // Mapbox Web Configuration
  static const String mapboxPublicToken = String.fromEnvironment(
    'MAPBOX_PUBLIC_TOKEN',
    defaultValue: '',
  );

  static const String mapboxStyleUrl = String.fromEnvironment(
    'MAPBOX_STYLE_URL',
    defaultValue: 'mapbox://styles/mapbox/streets-v12',
  );

  static bool get isMapboxConfigured => mapboxPublicToken.trim().isNotEmpty;

  // Fastify Telemetry & Admin Backend Configuration
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://bus-telemetry-api.onrender.com',
  );

  // Campus Geolocation Anchor (NITC Campus Center: 11.3216, 75.9337)
  static const double campusCenterLat = 11.3216;
  static const double campusCenterLng = 75.9337;
  static const double defaultZoom = 16.5;
  static const String campusName = 'National Institute of Technology Calicut';
}
