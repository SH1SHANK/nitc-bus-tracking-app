import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../core/geo/geo_point.dart';
import '../../core/logging/app_logger.dart';
import 'map_config.dart';

/// Marker representation data passed from feature layer into the map adapter.
class MapMarkerData {
  const MapMarkerData({
    required this.id,
    required this.point,
    required this.child,
    this.title,
    this.subtitle,
    this.width = 48.0,
    this.height = 48.0,
    this.alignment = Alignment.center,
    this.isSelected = false,
    this.isMajorHub = false,
    this.onTap,
    this.animatePosition = false,
  });

  final String id;
  final GeoPoint point;
  final Widget child;
  final String? title;
  final String? subtitle;
  final double width;
  final double height;
  final Alignment alignment;
  final bool isSelected;
  final bool isMajorHub;
  final VoidCallback? onTap;
  final bool animatePosition;
}

/// Polyline representation data passed from feature layer into the map adapter.
class MapPolylineData {
  const MapPolylineData({
    required this.id,
    required this.points,
    required this.color,
    this.strokeWidth = 4.5,
    this.isDotted = false,
  });

  final String id;
  final List<GeoPoint> points;
  final Color color;
  final double strokeWidth;
  final bool isDotted;
}

/// Unified map controller handle exposed to feature code for camera manipulations.
class TrackletMapController {
  TrackletMapController() : _fallbackController = fmap.MapController();

  final fmap.MapController _fallbackController;
  mb.MapboxMap? _mapboxMap;
  bool _useMapbox = false;

  void attachMapbox(mb.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _useMapbox = true;
  }

  void moveTo(GeoPoint point, {double? zoom}) {
    if (_useMapbox && _mapboxMap != null) {
      try {
        _mapboxMap?.flyTo(
          mb.CameraOptions(
            center: mb.Point(
              coordinates: mb.Position(point.longitude, point.latitude),
            ),
            zoom: zoom ?? MapConfig.defaultZoom,
          ),
          mb.MapAnimationOptions(duration: 600),
        );
        return;
      } catch (e) {
        AppLogger.warning('Mapbox moveTo camera failed: $e');
      }
    }

    try {
      _fallbackController.move(
        ll.LatLng(point.latitude, point.longitude),
        zoom ?? MapConfig.defaultZoom,
      );
    } catch (_) {}
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

    if (_useMapbox && _mapboxMap != null) {
      try {
        final coordinates = points
            .map(
              (p) =>
                  mb.Point(coordinates: mb.Position(p.longitude, p.latitude)),
            )
            .toList();

        _mapboxMap
            ?.cameraForCoordinates(
              coordinates,
              mb.MbxEdgeInsets(
                top: padding.top,
                left: padding.left,
                bottom: padding.bottom,
                right: padding.right,
              ),
              null,
              null,
            )
            .then((cameraOptions) {
              _mapboxMap?.flyTo(
                cameraOptions,
                mb.MapAnimationOptions(duration: 800),
              );
            });
        return;
      } catch (e) {
        AppLogger.warning('Mapbox fitBounds failed: $e');
      }
    }

    try {
      final latLngs = points
          .map((p) => ll.LatLng(p.latitude, p.longitude))
          .toList();
      final bounds = fmap.LatLngBounds.fromPoints(latLngs);
      _fallbackController.fitCamera(
        fmap.CameraFit.bounds(bounds: bounds, padding: padding),
      );
    } catch (_) {}
  }

  void recenterCampus() {
    moveTo(MapConfig.campusCenter, zoom: MapConfig.defaultZoom);
  }

  void dispose() {
    _fallbackController.dispose();
    _mapboxMap = null;
  }
}

/// Map adapter widget encapsulating Mapbox Maps SDK with graceful interactive fallback.
class TrackletMapView extends StatefulWidget {
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
  State<TrackletMapView> createState() => _TrackletMapViewState();
}

class _TrackletMapViewState extends State<TrackletMapView> {
  mb.PointAnnotationManager? _pointAnnotationManager;
  mb.PolylineAnnotationManager? _polylineAnnotationManager;
  bool _mapboxReady = false;

  @override
  void didUpdateWidget(covariant TrackletMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mapboxReady) {
      _syncMapboxFeatures();
    }
  }

  Future<void> _onMapboxCreated(mb.MapboxMap mapboxMap) async {
    widget.controller.attachMapbox(mapboxMap);
    try {
      _pointAnnotationManager = await mapboxMap.annotations
          .createPointAnnotationManager();
      _polylineAnnotationManager = await mapboxMap.annotations
          .createPolylineAnnotationManager();

      _pointAnnotationManager?.tapEvents(
        onTap: (annotation) {
          final customId = annotation.customData?['id'] as String?;
          final marker = widget.markers
              .where(
                (m) =>
                    m.id == annotation.id ||
                    (customId != null && m.id == customId),
              )
              .firstOrNull;
          marker?.onTap?.call();
        },
      );

      if (mounted) {
        setState(() {
          _mapboxReady = true;
        });
        await _syncMapboxFeatures();
      }
    } catch (e) {
      AppLogger.warning('Failed to initialize Mapbox annotation managers: $e');
    }
  }

  Future<void> _syncMapboxFeatures() async {
    if (!_mapboxReady ||
        _pointAnnotationManager == null ||
        _polylineAnnotationManager == null) {
      return;
    }

    try {
      await _pointAnnotationManager?.deleteAll();
      if (widget.markers.isNotEmpty) {
        final pointOptionsList = widget.markers.map((m) {
          return mb.PointAnnotationOptions(
            geometry: mb.Point(
              coordinates: mb.Position(m.point.longitude, m.point.latitude),
            ),
            textField: m.title ?? '',
            textSize: 12.0,
            textColor: Colors.black.toARGB32(),
            customData: <String, Object>{'id': m.id},
          );
        }).toList();

        if (pointOptionsList.isNotEmpty) {
          await _pointAnnotationManager?.createMulti(pointOptionsList);
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to sync Mapbox markers: $e');
    }

    try {
      await _polylineAnnotationManager?.deleteAll();
      if (widget.polylines.isNotEmpty) {
        final polylineOptionsList = widget.polylines
            .where((p) => p.points.length >= 2)
            .map((p) {
              return mb.PolylineAnnotationOptions(
                geometry: mb.LineString(
                  coordinates: p.points
                      .map((pt) => mb.Position(pt.longitude, pt.latitude))
                      .toList(),
                ),
                lineColor: p.color.toARGB32(),
                lineWidth: p.strokeWidth,
                lineOpacity: 0.9,
              );
            })
            .toList();

        if (polylineOptionsList.isNotEmpty) {
          await _polylineAnnotationManager?.createMulti(polylineOptionsList);
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to sync Mapbox polylines: $e');
    }
  }

  @override
  void dispose() {
    _mapboxReady = false;
    _pointAnnotationManager?.deleteAll();
    _polylineAnnotationManager?.deleteAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useMapbox = MapConfig.hasMapboxToken && !kIsWeb;

    if (useMapbox) {
      return Stack(
        children: [
          mb.MapWidget(
            key: const ValueKey('tracklet_mapbox_widget'),
            viewport: mb.CameraViewportState(
              center: mb.Point(
                coordinates: mb.Position(
                  widget.initialCenter.longitude,
                  widget.initialCenter.latitude,
                ),
              ),
              zoom: widget.initialZoom,
            ),
            styleUri: MapConfig.mapboxStreetsStyle,
            onMapCreated: _onMapboxCreated,
          ),
          if (widget.markers.isNotEmpty)
            const Positioned.fill(
              child: IgnorePointer(ignoring: true, child: SizedBox.shrink()),
            ),
        ],
      );
    }

    // Interactive fallback map view for web, dev without tokens, and widget tests
    return fmap.FlutterMap(
      key: const ValueKey('tracklet_fallback_map_view'),
      mapController: widget.controller._fallbackController,
      options: fmap.MapOptions(
        initialCenter: ll.LatLng(
          widget.initialCenter.latitude,
          widget.initialCenter.longitude,
        ),
        initialZoom: widget.initialZoom,
        minZoom: MapConfig.minZoom,
        maxZoom: MapConfig.maxZoom,
        cameraConstraint: fmap.CameraConstraint.containCenter(
          bounds: fmap.LatLngBounds(
            const ll.LatLng(MapConfig.minLat, MapConfig.minLng),
            const ll.LatLng(MapConfig.maxLat, MapConfig.maxLng),
          ),
        ),
        onTap: (tapPosition, point) {
          widget.onTap?.call(
            GeoPoint(latitude: point.latitude, longitude: point.longitude),
          );
        },
      ),
      children: [
        fmap.TileLayer(
          urlTemplate: MapConfig.tileUrlTemplate,
          userAgentPackageName: 'in.ac.nitc.tracklet',
        ),
        if (widget.polylines.isNotEmpty)
          fmap.PolylineLayer(
            polylines: widget.polylines
                .where((p) => p.points.length >= 2)
                .map(
                  (p) => fmap.Polyline(
                    points: p.points
                        .map((pt) => ll.LatLng(pt.latitude, pt.longitude))
                        .toList(),
                    color: p.color,
                    strokeWidth: p.strokeWidth,
                    pattern: p.isDotted
                        ? const fmap.StrokePattern.dotted()
                        : const fmap.StrokePattern.solid(),
                  ),
                )
                .toList(),
          ),
        if (widget.markers.isNotEmpty)
          fmap.MarkerLayer(
            markers: widget.markers
                .map(
                  (m) => fmap.Marker(
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
