import 'package:flutter/widgets.dart';

import '../../core/geo/geo_point.dart';

bool isMapboxWebSupported() => false;

Widget buildMapboxWebView({
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
  return const SizedBox.shrink();
}

void updateMapboxBuses(
  String viewId,
  List<Map<String, dynamic>> buses,
  String? selectedBusId,
) {}

void updateMapboxRoutes(
  String viewId,
  List<Map<String, dynamic>> routes,
  String? selectedRouteId,
) {}

void updateMapboxStops(
  String viewId,
  List<Map<String, dynamic>> stops,
  String? selectedStopId,
) {}

void updateMapboxUserLocation(String viewId, Map<String, dynamic>? location) {}

void flyToMapbox(String viewId, double lng, double lat, double? zoom) {}

void fitMapboxBounds(
  String viewId,
  List<double> bounds,
  Map<String, int>? padding,
) {}

void setMapboxStyle(String viewId, String styleUrl) {}

void destroyMapbox(String viewId) {}
