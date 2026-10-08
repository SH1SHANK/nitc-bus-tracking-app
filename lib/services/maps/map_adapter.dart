import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../core/geo/geo_point.dart';
import 'map_config.dart';

/// Marker representation data passed from feature layer into the map adapter.
class MapMarkerData {
  const MapMarkerData({
    required this.id,
    required this.point,
    required this.child,
    this.width = 44.0,
    this.height = 44.0,
    this.alignment = Alignment.center,
  });

  final String id;
  final GeoPoint point;
  final Widget child;
  final double width;
  final double height;
  final Alignment alignment;
}

/// Polyline representation data passed from feature layer into the map adapter.
class MapPolylineData {
  const MapPolylineData({
    required this.id,
    required this.points,
    required this.color,
    this.strokeWidth = 4.0,
    this.isDotted = false,
  });

  final String id;
  final List<GeoPoint> points;
  final Color color;
  final double strokeWidth;
  final bool isDotted;
}

/// Controller handle exposed to feature code for moving camera safely with [GeoPoint].
class TrackletMapController {
  TrackletMapController() : _mapController = MapController();

  final MapController _mapController;

  void moveTo(GeoPoint point, {double? zoom}) {
    _mapController.move(
      ll.LatLng(point.latitude, point.longitude),
      zoom ?? MapConfig.defaultZoom,
    );
  }

  void fitBounds(
    List<GeoPoint> points, {
    EdgeInsets padding = const EdgeInsets.all(48),
  }) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      moveTo(points.first);
      return;
    }

    final latLngs = points
        .map((p) => ll.LatLng(p.latitude, p.longitude))
        .toList();
    final bounds = LatLngBounds.fromPoints(latLngs);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: padding),
    );
  }

  void dispose() {
    _mapController.dispose();
  }
}

/// Map adapter widget encapsulating flutter_map and tile rendering.
class TrackletMapView extends StatelessWidget {
  const TrackletMapView({
    super.key,
    required this.controller,
    this.initialCenter = MapConfig.campusCenter,
    this.initialZoom = MapConfig.defaultZoom,
    this.markers = const [],
    this.polylines = const [],
    this.onTap,
  });

  final TrackletMapController controller;
  final GeoPoint initialCenter;
  final double initialZoom;
  final List<MapMarkerData> markers;
  final List<MapPolylineData> polylines;
  final void Function(GeoPoint point)? onTap;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller._mapController,
      options: MapOptions(
        initialCenter: ll.LatLng(
          initialCenter.latitude,
          initialCenter.longitude,
        ),
        initialZoom: initialZoom,
        minZoom: MapConfig.minZoom,
        maxZoom: MapConfig.maxZoom,
        cameraConstraint: CameraConstraint.containCenter(
          bounds: LatLngBounds(
            const ll.LatLng(MapConfig.minLat, MapConfig.minLng),
            const ll.LatLng(MapConfig.maxLat, MapConfig.maxLng),
          ),
        ),
        onTap: (tapPosition, point) {
          onTap?.call(
            GeoPoint(latitude: point.latitude, longitude: point.longitude),
          );
        },
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.tileUrlTemplate,
          userAgentPackageName: 'in.ac.nitc.tracklet',
        ),
        if (polylines.isNotEmpty)
          PolylineLayer(
            polylines: polylines
                .map(
                  (p) => Polyline(
                    points: p.points
                        .map((pt) => ll.LatLng(pt.latitude, pt.longitude))
                        .toList(),
                    color: p.color,
                    strokeWidth: p.strokeWidth,
                    pattern: p.isDotted
                        ? const StrokePattern.dotted()
                        : const StrokePattern.solid(),
                  ),
                )
                .toList(),
          ),
        if (markers.isNotEmpty)
          MarkerLayer(
            markers: markers
                .map(
                  (m) => Marker(
                    point: ll.LatLng(m.point.latitude, m.point.longitude),
                    width: m.width,
                    height: m.height,
                    alignment: m.alignment,
                    child: m.child,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
