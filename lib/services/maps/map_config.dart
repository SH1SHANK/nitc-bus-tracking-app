import '../../core/config/app_config.dart';
import '../../core/geo/geo_point.dart';

/// Configuration boundary for map tile providers and spatial bounds.
class MapConfig {
  const MapConfig._();

  /// Center point of the NIT Calicut campus (11.3216 N, 75.9337 E).
  static const GeoPoint campusCenter = GeoPoint(
    latitude: AppConfig.campusCenterLat,
    longitude: AppConfig.campusCenterLng,
  );

  static const double defaultZoom = AppConfig.defaultZoom;
  static const double minZoom = 14.0;
  static const double maxZoom = 18.5;

  /// Tile URL template with `{z}/{x}/{y}` placeholders.
  ///
  /// Boundary note: For production deployments, replace with your dedicated tile service
  /// endpoint (e.g., MapTiler, Stadia, Protomaps, AWS Location Service) via compile-time `--dart-define`.
  static String get tileUrlTemplate => AppConfig.mapTileUrlTemplate;

  /// Attribution text required by tile provider.
  static String get attributionText => AppConfig.mapAttribution;

  /// NITC Campus Region Bounding Box for camera clamping
  static const double minLat = 11.2500;
  static const double maxLat = 11.4000;
  static const double minLng = 75.8500;
  static const double maxLng = 76.0500;
}
