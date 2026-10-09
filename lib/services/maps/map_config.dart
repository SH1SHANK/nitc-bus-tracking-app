import '../../core/config/app_config.dart';
import '../../core/geo/geo_point.dart';

/// Configuration boundary for map providers, Mapbox styles, and spatial bounds.
class MapConfig {
  const MapConfig._();

  /// Center point of the NIT Calicut campus (11.3216 N, 75.9337 E).
  static const GeoPoint campusCenter = GeoPoint(
    latitude: AppConfig.campusCenterLat,
    longitude: AppConfig.campusCenterLng,
  );

  static const double defaultZoom = AppConfig.defaultZoom;
  static const double minZoom = 13.0;
  static const double maxZoom = 19.0;

  /// Mapbox public token from environment.
  static String get mapboxPublicToken => AppConfig.mapboxPublicToken;

  /// Whether a valid Mapbox public token is present.
  static bool get hasMapboxToken => AppConfig.hasMapboxToken;

  /// Light vector basemap; the map adapter suppresses its symbol layers and
  /// restyles discovered building and road layers for campus use.
  static const String mapboxCampusStyle = 'mapbox://styles/mapbox/light-v11';

  /// Kept for consumers that explicitly need the standard Streets style.
  static const String mapboxStreetsStyle = 'mapbox://styles/mapbox/streets-v12';
  static const String mapboxOutdoorsStyle =
      'mapbox://styles/mapbox/outdoors-v12';
  static const String mapboxLightStyle = 'mapbox://styles/mapbox/light-v11';

  /// Tile URL template with `{z}/{x}/{y}` placeholders for fallback tile rendering.
  static String get tileUrlTemplate => AppConfig.mapTileUrlTemplate;

  /// Attribution text required by tile provider.
  static String get attributionText => AppConfig.mapAttribution;

  /// NITC Campus Region Bounding Box for camera clamping
  static const double minLat = 11.2500;
  static const double maxLat = 11.4000;
  static const double minLng = 75.8500;
  static const double maxLng = 76.0500;
}
