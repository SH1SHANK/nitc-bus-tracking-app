import 'package:flutter/widgets.dart';

import '../../core/geo/geo_point.dart';
import 'mapbox_web_bridge_stub.dart'
    if (dart.library.js_interop) 'mapbox_web_bridge_impl.dart'
    as impl;

/// Cross-platform abstraction for Web Mapbox GL JS map integration.
abstract class MapboxWebBridge {
  static bool get isSupported => impl.isMapboxWebSupported();

  static Widget buildMapboxWebView({
    required String viewId,
    required String accessToken,
    required String styleUrl,
    required GeoPoint initialCenter,
    required double initialZoom,
    required void Function(GeoPoint) onMapClick,
    required void Function(String) onBusClick,
    required void Function(String) onStopClick,
    required void Function(double, double, double) onCameraChange,
    required VoidCallback onUserGesture,
    required VoidCallback onLoad,
    required void Function(String) onError,
  }) {
    return impl.buildMapboxWebView(
      viewId: viewId,
      accessToken: accessToken,
      styleUrl: styleUrl,
      initialCenter: initialCenter,
      initialZoom: initialZoom,
      onMapClick: onMapClick,
      onBusClick: onBusClick,
      onStopClick: onStopClick,
      onCameraChange: onCameraChange,
      onUserGesture: onUserGesture,
      onLoad: onLoad,
      onError: onError,
    );
  }

  static void updateBuses(
    String viewId,
    List<Map<String, dynamic>> buses,
    String? selectedBusId,
  ) {
    impl.updateMapboxBuses(viewId, buses, selectedBusId);
  }

  static void updateRoutes(
    String viewId,
    List<Map<String, dynamic>> routes,
    String? selectedRouteId,
  ) {
    impl.updateMapboxRoutes(viewId, routes, selectedRouteId);
  }

  static void updateStops(
    String viewId,
    List<Map<String, dynamic>> stops,
    String? selectedStopId,
  ) {
    impl.updateMapboxStops(viewId, stops, selectedStopId);
  }

  static void updateUserLocation(
    String viewId,
    Map<String, dynamic>? location,
  ) {
    impl.updateMapboxUserLocation(viewId, location);
  }

  static void flyTo(String viewId, double lng, double lat, double? zoom) {
    impl.flyToMapbox(viewId, lng, lat, zoom);
  }

  static void fitBounds(
    String viewId,
    List<double> bounds,
    Map<String, int>? padding,
  ) {
    impl.fitMapboxBounds(viewId, bounds, padding);
  }

  static void setStyle(String viewId, String styleUrl) {
    impl.setMapboxStyle(viewId, styleUrl);
  }

  static void destroy(String viewId) {
    impl.destroyMapbox(viewId);
  }
}
