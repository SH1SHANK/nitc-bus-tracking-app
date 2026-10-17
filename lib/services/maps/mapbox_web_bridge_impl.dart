import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../../core/geo/geo_point.dart';

@JS('TrackletMapbox.isSupported')
external bool _isSupported();

@JS('TrackletMapbox.initMap')
external bool _initMap(
  JSString viewId,
  JSAny container,
  JSString configJson,
  JSAny callbacks,
);

@JS('TrackletMapbox.updateBuses')
external void _updateBuses(
  JSString viewId,
  JSString busesJson,
  JSString? selectedBusId,
);

@JS('TrackletMapbox.updateRoutes')
external void _updateRoutes(
  JSString viewId,
  JSString routesJson,
  JSString? selectedRouteId,
);

@JS('TrackletMapbox.updateStops')
external void _updateStops(
  JSString viewId,
  JSString stopsJson,
  JSString? selectedStopId,
);

@JS('TrackletMapbox.updateUserLocation')
external void _updateUserLocation(JSString viewId, JSString? locationJson);

@JS('TrackletMapbox.flyTo')
external void _flyTo(
  JSString viewId,
  JSNumber lng,
  JSNumber lat,
  JSNumber? zoom,
);

@JS('TrackletMapbox.fitBounds')
external void _fitBounds(
  JSString viewId,
  JSArray<JSNumber> bounds,
  JSAny? padding,
);

@JS('TrackletMapbox.destroy')
external void _destroy(JSString viewId);

bool isMapboxWebSupported() {
  try {
    return _isSupported();
  } catch (_) {
    return false;
  }
}

final Set<String> _registeredViews = {};

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
  final viewType = 'tracklet-mapbox-web-view-$viewId';

  if (!_registeredViews.contains(viewType)) {
    _registeredViews.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
      final div = web.document.createElement('div') as web.HTMLDivElement;
      div.id = 'mapbox-container-$viewId';
      div.style.width = '100%';
      div.style.height = '100%';

      // Initialize map asynchronously after DOM mount
      web.window.requestAnimationFrame(
        (JSNumber _) {
          final configJson = jsonEncode({
            'accessToken': accessToken,
            'styleUrl': styleUrl,
            'centerLat': initialCenter.latitude,
            'centerLng': initialCenter.longitude,
            'zoom': initialZoom,
          });

          final callbacks = JSObject();
          callbacks['onMapClick'] =
              ((JSNumber lat, JSNumber lng) {
                onMapClick(
                  GeoPoint(
                    latitude: lat.toDartDouble,
                    longitude: lng.toDartDouble,
                  ),
                );
              }).toJS;
          callbacks['onBusClick'] =
              ((JSString busId) {
                onBusClick(busId.toDart);
              }).toJS;
          callbacks['onStopClick'] =
              ((JSString stopId) {
                onStopClick(stopId.toDart);
              }).toJS;
          callbacks['onCameraChange'] =
              ((JSNumber lat, JSNumber lng, JSNumber zoom) {
                onCameraChange(
                  lat.toDartDouble,
                  lng.toDartDouble,
                  zoom.toDartDouble,
                );
              }).toJS;
          callbacks['onUserGesture'] =
              (() {
                onUserGesture();
              }).toJS;
          callbacks['onLoad'] =
              (() {
                onLoad();
              }).toJS;
          callbacks['onError'] =
              ((JSString err) {
                onError(err.toDart);
              }).toJS;

          _initMap(viewId.toJS, div as JSAny, configJson.toJS, callbacks);
        }.toJS,
      );

      return div;
    });
  }

  return HtmlElementView(viewType: viewType);
}

void updateMapboxBuses(
  String viewId,
  List<Map<String, dynamic>> buses,
  String? selectedBusId,
) {
  try {
    _updateBuses(viewId.toJS, jsonEncode(buses).toJS, selectedBusId?.toJS);
  } catch (_) {}
}

void updateMapboxRoutes(
  String viewId,
  List<Map<String, dynamic>> routes,
  String? selectedRouteId,
) {
  try {
    _updateMapboxRoutes(viewId, routes, selectedRouteId);
  } catch (_) {}
}

void _updateMapboxRoutes(
  String viewId,
  List<Map<String, dynamic>> routes,
  String? selectedRouteId,
) {
  _updateRoutes(viewId.toJS, jsonEncode(routes).toJS, selectedRouteId?.toJS);
}

void updateMapboxStops(
  String viewId,
  List<Map<String, dynamic>> stops,
  String? selectedStopId,
) {
  try {
    _updateStops(viewId.toJS, jsonEncode(stops).toJS, selectedStopId?.toJS);
  } catch (_) {}
}

void updateMapboxUserLocation(String viewId, Map<String, dynamic>? location) {
  try {
    _updateUserLocation(
      viewId.toJS,
      location == null ? null : jsonEncode(location).toJS,
    );
  } catch (_) {}
}

void flyToMapbox(String viewId, double lng, double lat, double? zoom) {
  try {
    _flyTo(viewId.toJS, lng.toJS, lat.toJS, zoom?.toJS);
  } catch (_) {}
}

void fitMapboxBounds(
  String viewId,
  List<double> bounds,
  Map<String, int>? padding,
) {
  try {
    final jsBounds = bounds.map((b) => b.toJS).toList().toJS;
    JSObject? jsPad;
    if (padding != null) {
      jsPad = JSObject();
      padding.forEach((k, v) {
        jsPad![k] = v.toJS;
      });
    }
    _fitBounds(viewId.toJS, jsBounds, jsPad);
  } catch (_) {}
}

void destroyMapbox(String viewId) {
  try {
    _destroy(viewId.toJS);
  } catch (_) {}
}
