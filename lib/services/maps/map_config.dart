import '../../core/config/app_config.dart';
import '../../core/geo/geo_point.dart';

/// Configuration boundary for map camera defaults, zoom constraints, and spatial bounds.
class MapConfig {
  const MapConfig._();

  /// Center point of the NIT Calicut campus (11.3216 N, 75.9337 E).
  static const GeoPoint campusCenter = GeoPoint(
    latitude: AppConfig.campusCenterLat,
    longitude: AppConfig.campusCenterLng,
  );

  static const double defaultZoom = 16.5;
  static const double minZoom = 15.0;
  static const double maxZoom = 20.0;

  /// Tile URL template with `{z}/{x}/{y}` placeholders for fallback tile rendering.
  static String get tileUrlTemplate => AppConfig.mapTileUrlTemplate;

  /// Attribution text required by tile provider.
  static String get attributionText => AppConfig.mapAttribution;

  /// NITC Campus Region Bounding Box matching QGIS MBTiles extent
  /// (with slight padding for camera bounds clamping).
  static const double minLat = 11.3050;
  static const double maxLat = 11.3280;
  static const double minLng = 75.9220;
  static const double maxLng = 75.9460;
}
