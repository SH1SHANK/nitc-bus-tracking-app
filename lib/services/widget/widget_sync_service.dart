import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/logging/app_logger.dart';
import '../../data/transit/bus.dart';
import '../../data/transit/bus_route.dart';
import '../../data/transit/stop.dart';

class WidgetSyncService {
  static const MethodChannel _channel = MethodChannel(
    'in.ac.nitc.tracklet/widget',
  );

  /// Synchronize reference stops and route-stop maps to native Android widget store.
  static Future<void> syncReferenceData({
    required List<Stop> stops,
    required List<BusRoute> routes,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final stopsJson = jsonEncode(
        stops
            .map(
              (s) => {
                'id': s.id,
                'name': s.name,
                'latitude': s.location.latitude,
                'longitude': s.location.longitude,
              },
            )
            .toList(),
      );

      final routeStopsMap = <String, List<String>>{};
      for (final r in routes) {
        routeStopsMap[r.id] = r.stopIds;
      }
      final routeStopsJson = jsonEncode(routeStopsMap);

      await _channel.invokeMethod('syncReferenceData', {
        'stopsJson': stopsJson,
        'routeStopsJson': routeStopsJson,
      });
      AppLogger.info(
        'Widget reference data synchronized',
        tag: 'WidgetSyncService',
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to sync widget reference data',
        error: e,
        stackTrace: st,
        tag: 'WidgetSyncService',
      );
    }
  }

  /// Inform native widget of user's latest GPS position for automatic nearest stop resolution.
  static Future<void> setUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _channel.invokeMethod('setUserLocation', {
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (e) {
      AppLogger.warning(
        'Failed to sync user location to widget: $e',
        tag: 'WidgetSyncService',
      );
    }
  }

  /// Update pinned stop override (or pass null to return to automatic nearest-stop mode).
  static Future<void> setPinnedStop({String? stopId, String? stopName}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _channel.invokeMethod('setPinnedStop', {
        'stopId': stopId,
        'stopName': stopName,
      });
      AppLogger.info(
        'Widget pinned stop updated: $stopName',
        tag: 'WidgetSyncService',
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to set pinned stop for widget: $e',
        tag: 'WidgetSyncService',
      );
    }
  }

  /// Push current live nearest bus state directly to native widget cache when home/map updates.
  static Future<void> updateWidgetState({
    required String stopName,
    Bus? bus,
    double? distanceMeters,
    String? errorMessage,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _channel.invokeMethod('updateWidgetData', {
        'stopName': stopName,
        'busName': bus?.name,
        'distanceMeters': distanceMeters,
        'telemetryEpochMs':
            bus?.lastUpdated.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
        'isStale': bus?.isStale ?? false,
        'errorMessage': errorMessage,
      });
    } catch (e) {
      AppLogger.warning(
        'Failed to push state to widget: $e',
        tag: 'WidgetSyncService',
      );
    }
  }

  /// Request immediate native background refresh via WorkManager.
  static Future<void> requestRefresh() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _channel.invokeMethod('refreshWidget');
    } catch (e) {
      AppLogger.warning(
        'Failed to request widget refresh: $e',
        tag: 'WidgetSyncService',
      );
    }
  }
}
