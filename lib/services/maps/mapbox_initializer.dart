import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/logging/app_logger.dart';
import 'map_config.dart';

/// Initializes the Mapbox Maps SDK with the configured public access token.
class MapboxInitializer {
  const MapboxInitializer._();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Sets the public access token on the Mapbox SDK.
  ///
  /// Fails gracefully if the token is missing or empty, avoiding unhandled exceptions.
  static Future<void> initialize() async {
    final token = MapConfig.mapboxPublicToken.trim();
    if (token.isEmpty) {
      AppLogger.warning(
        'Mapbox public token is empty. Mapbox maps will run in fallback mode.',
        tag: 'MapboxInitializer',
      );
      _isInitialized = false;
      return;
    }

    try {
      MapboxOptions.setAccessToken(token);
      _isInitialized = true;
      AppLogger.info(
        'Mapbox Maps SDK initialized successfully with public client token.',
        tag: 'MapboxInitializer',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to set Mapbox access token',
        error: e,
        stackTrace: stackTrace,
        tag: 'MapboxInitializer',
      );
      _isInitialized = false;
    }
  }
}
