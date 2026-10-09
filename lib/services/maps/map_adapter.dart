import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../core/geo/geo_point.dart';
import '../../core/logging/app_logger.dart';
import '../../design_system/tokens/colors.dart';
import 'map_cartography.dart';
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
    this.isRouteStop = false,
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
  final bool isRouteStop;
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
  bool _mapboxExpected = false;
  VoidCallback? _pendingCameraAction;

  void setMapboxExpected(bool expected) {
    _mapboxExpected = expected;
  }

  void attachMapbox(mb.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _useMapbox = true;
    final pendingAction = _pendingCameraAction;
    _pendingCameraAction = null;
    pendingAction?.call();
  }

  void moveTo(GeoPoint point, {double? zoom}) {
    if (_mapboxExpected && !_useMapbox) {
      _pendingCameraAction = () => moveTo(point, zoom: zoom);
      return;
    }

    if (_useMapbox && _mapboxMap != null) {
      try {
        _mapboxMap!.flyTo(
          mb.CameraOptions(
            center: mb.Point(
              coordinates: mb.Position(point.longitude, point.latitude),
            ),
            zoom: zoom ?? MapConfig.defaultZoom,
          ),
          mb.MapAnimationOptions(duration: 600),
        );
        return;
      } catch (error) {
        AppLogger.warning('Mapbox moveTo camera failed: $error');
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
    if (_mapboxExpected && !_useMapbox) {
      final pointSnapshot = List<GeoPoint>.of(points);
      _pendingCameraAction = () => fitBounds(pointSnapshot, padding: padding);
      return;
    }

    if (_useMapbox && _mapboxMap != null) {
      final map = _mapboxMap!;
      final coordinates =
          points
              .where(_isValidPoint)
              .map(
                (point) => mb.Point(
                  coordinates: mb.Position(point.longitude, point.latitude),
                ),
              )
              .toList();
      if (coordinates.length < 2) return;

      map
          .cameraForCoordinates(
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
            if (_mapboxMap == map) {
              map.flyTo(cameraOptions, mb.MapAnimationOptions(duration: 800));
            }
          })
          .catchError((Object error) {
            AppLogger.warning('Mapbox fitBounds camera failed: $error');
          });
      return;
    }

    try {
      final latLngs =
          points
              .where(_isValidPoint)
              .map((point) => ll.LatLng(point.latitude, point.longitude))
              .toList();
      if (latLngs.length < 2) return;
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
    _pendingCameraAction = null;
    _fallbackController.dispose();
    _mapboxMap = null;
    _useMapbox = false;
  }
}

bool _isValidPoint(GeoPoint point) =>
    point.latitude.isFinite &&
    point.longitude.isFinite &&
    point.latitude >= -90 &&
    point.latitude <= 90 &&
    point.longitude >= -180 &&
    point.longitude <= 180;

/// Map adapter encapsulating Mapbox Maps SDK with an interactive fallback.
class TrackletMapView extends StatefulWidget {
  const TrackletMapView({
    super.key,
    required this.controller,
    this.initialCenter = MapConfig.campusCenter,
    this.initialZoom = MapConfig.defaultZoom,
    this.markers = const [],
    this.polylines = const [],
    this.labels = const [],
    this.onTap,
  });

  final TrackletMapController controller;
  final GeoPoint initialCenter;
  final double initialZoom;
  final List<MapMarkerData> markers;
  final List<MapPolylineData> polylines;
  final List<MapLabelFeature> labels;
  final void Function(GeoPoint point)? onTap;

  @override
  State<TrackletMapView> createState() => _TrackletMapViewState();
}

class _TrackletMapViewState extends State<TrackletMapView> {
  mb.PointAnnotationManager? _pointAnnotationManager;
  mb.PolylineAnnotationManager? _polylineAnnotationManager;
  mb.Cancelable? _pointTapListener;
  final Map<String, mb.PointAnnotation> _pointAnnotations = {};
  final Map<String, String> _pointSignatures = {};
  final Map<String, Uint8List> _markerImages = {};
  final Map<String, mb.PolylineAnnotation> _polylineAnnotations = {};
  final Map<String, String> _polylineSignatures = {};
  bool _mapboxReady = false;
  bool _styleReady = false;
  bool _styleConfigurationInProgress = false;
  bool _styleConfigurationPending = false;
  bool _syncInProgress = false;
  bool _syncPending = false;
  String? _buildingLabelsJson;
  String? _stopLabelsJson;

  @override
  void didUpdateWidget(covariant TrackletMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.setMapboxExpected(false);
    }
    if (_mapboxReady) _requestFeatureSync();
  }

  Future<void> _onMapboxCreated(mb.MapboxMap mapboxMap) async {
    widget.controller.attachMapbox(mapboxMap);
    try {
      final pointManager =
          await mapboxMap.annotations.createPointAnnotationManager();
      final polylineManager =
          await mapboxMap.annotations.createPolylineAnnotationManager();
      if (!mounted) {
        await pointManager.deleteAll();
        await polylineManager.deleteAll();
        return;
      }

      _pointAnnotationManager = pointManager;
      _polylineAnnotationManager = polylineManager;
      _pointTapListener = pointManager.tapEvents(
        onTap: (annotation) {
          final markerId = annotation.customData?['id'] as String?;
          if (markerId == null) return;
          for (final marker in widget.markers) {
            if (marker.id == markerId) {
              marker.onTap?.call();
              break;
            }
          }
        },
      );
      await pointManager.setIconAllowOverlap(true);
      await pointManager.setTextAllowOverlap(false);
      setState(() => _mapboxReady = true);
      await _requestStyleConfiguration();
      await _syncMapboxFeatures();
    } catch (error) {
      AppLogger.warning(
        'Failed to initialize Mapbox annotation managers: $error',
      );
    }
  }

  void _onMapboxStyleLoaded(mb.StyleLoadedEventData _) {
    _styleReady = false;
    _buildingLabelsJson = null;
    _stopLabelsJson = null;
    unawaited(_requestStyleConfiguration());
  }

  Future<void> _requestStyleConfiguration() async {
    if (_styleConfigurationInProgress) {
      _styleConfigurationPending = true;
      return;
    }
    _styleConfigurationInProgress = true;
    try {
      do {
        _styleConfigurationPending = false;
        final map = widget.controller._mapboxMap;
        if (map == null) return;
        _styleReady = false;
        await _configureCampusStyle(map);
        _styleReady = true;
        await _syncMapboxFeatures();
      } while (_styleConfigurationPending && mounted);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to configure the campus map style: $error',
        stackTrace: stackTrace,
      );
    } finally {
      _styleConfigurationInProgress = false;
    }
  }

  Future<void> _configureCampusStyle(mb.MapboxMap map) async {
    final style = map;
    final layers = await style.getStyleLayers();
    var hasCampusFootprints = false;

    for (final layer in layers.whereType<mb.StyleObjectInfo>()) {
      if (layer.id.startsWith('tracklet-')) continue;
      try {
        final properties = jsonDecode(
          await style.getStyleLayerProperties(layer.id),
        );
        if (properties is! Map<String, dynamic>) continue;
        final sourceLayer = properties['source-layer']?.toString();
        final treatment = TrackletMapCartography.treatmentFor(
          type: layer.type,
          sourceLayer: sourceLayer,
        );

        if (layer.type == 'fill-extrusion' &&
            sourceLayer?.toLowerCase() == 'building') {
          await style.setStyleLayerProperty(layer.id, 'visibility', 'none');
          continue;
        }
        if (treatment == MapBaseLayerTreatment.hideSymbols) {
          await style.setStyleLayerProperty(layer.id, 'visibility', 'none');
          continue;
        }
        if (treatment == MapBaseLayerTreatment.campusBuildingFootprint) {
          hasCampusFootprints = true;
        }
        for (final override
            in TrackletMapCartography.layerOverrides(treatment).entries) {
          await style.setStyleLayerProperty(
            layer.id,
            override.key,
            override.value,
          );
        }
      } catch (error) {
        AppLogger.warning(
          'Could not style Mapbox base layer ${layer.id}: $error',
        );
      }
    }

    if (!hasCampusFootprints) await _addDiscoveredFootprintLayer(style);

    if (!await style.styleSourceExists(
      TrackletMapCartography.campusBuildingSourceId,
    )) {
      await style.addSource(
        mb.GeoJsonSource(
          id: TrackletMapCartography.campusBuildingSourceId,
          dynamicData: true,
        ),
      );
    }
    if (!await style.styleSourceExists(
      TrackletMapCartography.stopLabelSourceId,
    )) {
      await style.addSource(
        mb.GeoJsonSource(
          id: TrackletMapCartography.stopLabelSourceId,
          dynamicData: true,
        ),
      );
    }

    for (final layer in TrackletMapCartography.labelLayerDefinitions()) {
      final id = layer['id']! as String;
      if (!await style.styleLayerExists(id)) {
        await style.addStyleLayer(jsonEncode(layer), null);
      }
    }

    _buildingLabelsJson = null;
    _stopLabelsJson = null;
    if (_pointAnnotationManager != null) {
      await _pointAnnotationManager!.deleteAll();
      _pointAnnotations.clear();
      _pointSignatures.clear();
    }
    if (_polylineAnnotationManager != null) {
      await _polylineAnnotationManager!.deleteAll();
      _polylineAnnotations.clear();
      _polylineSignatures.clear();
    }
  }

  Future<void> _addDiscoveredFootprintLayer(mb.StyleManager style) async {
    final sources = await style.getStyleSources();
    for (final source in sources.whereType<mb.StyleObjectInfo>()) {
      if (source.type != 'vector') continue;
      try {
        final properties = jsonDecode(
          await style.getStyleSourceProperties(source.id),
        );
        if (properties is! Map<String, dynamic>) continue;
        final url = properties['url']?.toString() ?? '';
        final isMapboxStreetsSource =
            source.id == 'composite' || url.contains('mapbox-streets');
        if (!isMapboxStreetsSource) continue;

        await style.addLayer(
          mb.FillLayer(
            id: 'tracklet-campus-building-footprints',
            sourceId: source.id,
            sourceLayer: 'building',
            minZoom: 14.5,
            fillColor: TrackletColors.mapBuilding.toARGB32(),
            fillOpacity: 0.96,
            fillOutlineColor: TrackletColors.mapBuildingOutline.toARGB32(),
          ),
        );
        return;
      } catch (error) {
        AppLogger.warning(
          'Could not add a discovered Mapbox building footprint layer: $error',
        );
      }
    }
    AppLogger.warning(
      'The active Mapbox style exposed no usable building footprint layer.',
    );
  }

  Future<void> _requestFeatureSync() async {
    if (_syncInProgress) {
      _syncPending = true;
      return;
    }
    await _syncMapboxFeatures();
  }

  Future<void> _syncMapboxFeatures() async {
    if (!_mapboxReady) return;
    if (_syncInProgress) {
      _syncPending = true;
      return;
    }

    _syncInProgress = true;
    try {
      do {
        _syncPending = false;
        final markerSnapshot = List<MapMarkerData>.of(widget.markers);
        final polylineSnapshot = List<MapPolylineData>.of(widget.polylines);
        if (_pointAnnotationManager != null) {
          try {
            await _syncMarkers(markerSnapshot);
          } catch (error) {
            AppLogger.warning('Failed to sync Mapbox markers: $error');
          }
        }
        if (_polylineAnnotationManager != null) {
          try {
            await _syncPolylines(polylineSnapshot);
          } catch (error) {
            AppLogger.warning('Failed to sync Mapbox polylines: $error');
          }
        }
        if (_styleReady) {
          try {
            await _syncLabelSources();
          } catch (error) {
            AppLogger.warning('Failed to sync Mapbox campus labels: $error');
          }
        }
      } while (_syncPending && mounted);
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _syncMarkers(List<MapMarkerData> markers) async {
    final manager = _pointAnnotationManager;
    if (manager == null) return;
    final validMarkers =
        markers.where((marker) => _isValidPoint(marker.point)).toList();
    final desiredIds = validMarkers.map((marker) => marker.id).toSet();

    for (final id in _pointAnnotations.keys.toList()) {
      if (desiredIds.contains(id)) continue;
      final annotation = _pointAnnotations.remove(id)!;
      _pointSignatures.remove(id);
      await manager.delete(annotation);
    }

    final additions = <MapMarkerData>[];
    final additionOptions = <mb.PointAnnotationOptions>[];
    for (final marker in validMarkers) {
      final signature = _markerSignature(marker);
      final existing = _pointAnnotations[marker.id];
      if (existing != null && _pointSignatures[marker.id] == signature) {
        continue;
      }

      final options = await _pointOptions(marker);
      if (existing == null) {
        additions.add(marker);
        additionOptions.add(options);
        continue;
      }

      await manager.update(
        mb.PointAnnotation(
          id: existing.id,
          geometry: options.geometry,
          image: options.image,
          textField: options.textField,
          textSize: options.textSize,
          textColor: options.textColor,
          textHaloColor: options.textHaloColor,
          textHaloWidth: options.textHaloWidth,
          textMaxWidth: options.textMaxWidth,
          textOffset: options.textOffset,
          customData: options.customData,
        ),
      );
      _pointSignatures[marker.id] = signature;
    }

    if (additionOptions.isEmpty) return;
    final created = await manager.createMulti(additionOptions);
    for (var index = 0; index < created.length; index++) {
      final annotation = created[index];
      if (annotation == null) continue;
      final marker = additions[index];
      _pointAnnotations[marker.id] = annotation;
      _pointSignatures[marker.id] = _markerSignature(marker);
    }
  }

  Future<mb.PointAnnotationOptions> _pointOptions(MapMarkerData marker) async {
    final image = await _markerImage(marker);
    return mb.PointAnnotationOptions(
      geometry: mb.Point(
        coordinates: mb.Position(marker.point.longitude, marker.point.latitude),
      ),
      image: image,
      customData: <String, Object>{'id': marker.id},
    );
  }

  Future<void> _syncLabelSources() async {
    final map = widget.controller._mapboxMap;
    if (map == null) return;
    final buildingLabels = widget.labels.where(
      (label) => label.kind == MapLabelKind.building,
    );
    final stopLabels = widget.labels.where(
      (label) => label.kind == MapLabelKind.stop,
    );
    final buildingJson = TrackletMapCartography.toGeoJson(buildingLabels);
    if (buildingJson != _buildingLabelsJson) {
      await map.setStyleSourceProperty(
        TrackletMapCartography.campusBuildingSourceId,
        'data',
        buildingJson,
      );
      _buildingLabelsJson = buildingJson;
    }
    final stopJson = TrackletMapCartography.toGeoJson(stopLabels);
    if (stopJson != _stopLabelsJson) {
      await map.setStyleSourceProperty(
        TrackletMapCartography.stopLabelSourceId,
        'data',
        stopJson,
      );
      _stopLabelsJson = stopJson;
    }
  }

  Future<Uint8List> _markerImage(MapMarkerData marker) async {
    final imageKey =
        marker.isSelected
            ? 'selected'
            : marker.isRouteStop
            ? 'route'
            : 'campus';
    final cached = _markerImages[imageKey];
    if (cached != null) return cached;

    const size = 28.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);
    final isSelected = marker.isSelected;
    final isRouteStop = marker.isRouteStop;
    final outline =
        Paint()
          ..color =
              isSelected || isRouteStop
                  ? TrackletColors.primary
                  : TrackletColors.textSecondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.5 : 2.2;
    final fill =
        Paint()
          ..color = isSelected ? TrackletColors.primary : Colors.white
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, isSelected ? 9 : 8, fill);
    canvas.drawCircle(center, isSelected ? 9 : 8, outline);
    if (isRouteStop && !isSelected) {
      canvas.drawCircle(
        center,
        3.2,
        Paint()
          ..color = TrackletColors.primary
          ..style = PaintingStyle.fill,
      );
    } else if (isSelected) {
      final check =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx - 3.2, center.dy)
          ..lineTo(center.dx - 0.8, center.dy + 2.5)
          ..lineTo(center.dx + 3.8, center.dy - 2.5),
        check,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    final result = bytes!.buffer.asUint8List();
    _markerImages[imageKey] = result;
    return result;
  }

  String _markerSignature(MapMarkerData marker) =>
      '${marker.point.latitude},${marker.point.longitude}|'
      '${marker.isSelected}|${marker.isRouteStop}|${marker.isMajorHub}';

  Future<void> _syncPolylines(List<MapPolylineData> polylines) async {
    final manager = _polylineAnnotationManager;
    if (manager == null) return;
    final validPolylines =
        polylines
            .where(
              (line) =>
                  line.points.length >= 2 && line.points.every(_isValidPoint),
            )
            .toList();
    final desiredIds = validPolylines.map((line) => line.id).toSet();

    for (final id in _polylineAnnotations.keys.toList()) {
      if (desiredIds.contains(id)) continue;
      final annotation = _polylineAnnotations.remove(id)!;
      _polylineSignatures.remove(id);
      await manager.delete(annotation);
    }

    for (final polyline in validPolylines) {
      final signature = _polylineSignature(polyline);
      final existing = _polylineAnnotations[polyline.id];
      if (existing != null && _polylineSignatures[polyline.id] == signature) {
        continue;
      }
      final options = _polylineOptions(polyline);
      if (existing == null) {
        _polylineAnnotations[polyline.id] = await manager.create(options);
      } else {
        await manager.update(
          mb.PolylineAnnotation(
            id: existing.id,
            geometry: options.geometry,
            lineColor: options.lineColor,
            lineWidth: options.lineWidth,
            lineOpacity: options.lineOpacity,
          ),
        );
      }
      _polylineSignatures[polyline.id] = signature;
    }
  }

  mb.PolylineAnnotationOptions _polylineOptions(MapPolylineData polyline) {
    return mb.PolylineAnnotationOptions(
      geometry: mb.LineString(
        coordinates:
            polyline.points
                .map((point) => mb.Position(point.longitude, point.latitude))
                .toList(),
      ),
      lineColor: polyline.color.toARGB32(),
      lineWidth: polyline.strokeWidth,
      lineOpacity: 0.9,
    );
  }

  String _polylineSignature(MapPolylineData line) =>
      '${line.points.map((point) => '${point.latitude},${point.longitude}').join(';')}|'
      '${line.color.toARGB32()}|${line.strokeWidth}|${line.isDotted}';

  @override
  void dispose() {
    _mapboxReady = false;
    _pointTapListener?.cancel();
    _pointAnnotationManager?.deleteAll();
    _polylineAnnotationManager?.deleteAll();
    if (widget.controller._mapboxMap != null) {
      widget.controller._mapboxMap = null;
      widget.controller._useMapbox = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useMapbox = MapConfig.hasMapboxToken && !kIsWeb;
    widget.controller.setMapboxExpected(useMapbox);

    if (useMapbox) {
      return mb.MapWidget(
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
        styleUri: MapConfig.mapboxCampusStyle,
        onMapCreated: _onMapboxCreated,
        onStyleLoadedListener: _onMapboxStyleLoaded,
      );
    }

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
            polylines:
                widget.polylines
                    .where(
                      (line) =>
                          line.points.length >= 2 &&
                          line.points.every(_isValidPoint),
                    )
                    .map(
                      (line) => fmap.Polyline(
                        points:
                            line.points
                                .map(
                                  (point) => ll.LatLng(
                                    point.latitude,
                                    point.longitude,
                                  ),
                                )
                                .toList(),
                        color: line.color,
                        strokeWidth: line.strokeWidth,
                        pattern:
                            line.isDotted
                                ? const fmap.StrokePattern.dotted()
                                : const fmap.StrokePattern.solid(),
                      ),
                    )
                    .toList(),
          ),
        if (widget.markers.isNotEmpty)
          fmap.MarkerLayer(
            markers:
                widget.markers
                    .where((marker) => _isValidPoint(marker.point))
                    .map(
                      (marker) => fmap.Marker(
                        key: ValueKey('map-stop-${marker.id}'),
                        point: ll.LatLng(
                          marker.point.latitude,
                          marker.point.longitude,
                        ),
                        width: marker.width,
                        height: marker.height,
                        alignment: marker.alignment,
                        child: marker.child,
                      ),
                    )
                    .toList(),
          ),
      ],
    );
  }
}
