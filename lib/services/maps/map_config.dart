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

  /// Campus display bounds retained from the former offline map camera limits.
  static const double minLat = 11.3050;
  static const double maxLat = 11.3280;
  static const double minLng = 75.9220;
  static const double maxLng = 75.9460;

  /// Zoom level thresholds for progressive detail filtering.
  static const double zoomBucketDetailed = 18.5;
  static const double zoomBucketMedium = 16.5;
  static const double buildingSelectionZoom = 17.6;

  /// Marker dimensions for consistent map styling.
  static const double busMarkerSize = 48.0;
  static const double selectedBusMarkerSize = 44.0;
  static const double unselectedBusMarkerSize = 40.0;
  static const double userMarkerSize = 32.0;
  static const double stopMarkerSizeCompact = 48.0;
  static const double stopMarkerWidthExpanded = 112.0;
  static const double stopMarkerHeightExpanded = 60.0;
  static const double routeArrowDistanceMeters = 180.0;
}
