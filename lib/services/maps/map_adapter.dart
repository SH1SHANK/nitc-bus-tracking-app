import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/geo/geo_point.dart';
import '../../core/logging/app_logger.dart';
import '../../data/transit/bus_telemetry.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import 'map_cartography.dart';
import 'map_config.dart';
import 'bus_model_style.dart';

/// Marker data shared by the map feature and the Mapbox style source.
class MapMarkerData {
  const MapMarkerData({
    required this.id,
    required this.point,
    required this.child,
    this.title,
    this.subtitle,
    this.isSelected = false,
    this.isRouteStop = false,
    this.isMajorHub = false,
    this.accentColor,
    this.onTap,
    this.animatePosition = false,
    this.sequenceNumber,
    this.epoch,
    this.timestamp,
    this.speedKmH,
    this.showLabel = true,
    this.headingDegrees,
    this.show3dModel = false,
    this.busBodyColor,
    this.width = 48,
    this.height = 48,
    this.alignment = Alignment.center,
  });

  final String id;
  final GeoPoint point;

  /// Retained for source compatibility; Mapbox renders the corresponding data
  /// through style layers so Android and web use the same representation.
  final Widget child;
  final String? title;
  final String? subtitle;
  final bool isSelected;
  final bool isRouteStop;
  final bool isMajorHub;
  final Color? accentColor;
  final VoidCallback? onTap;
  final bool animatePosition;
  final int? sequenceNumber;
  final int? epoch;
  final DateTime? timestamp;
  final double? speedKmH;
  final bool showLabel;
  final double? headingDegrees;
  final bool show3dModel;

  /// Custom body tint for this bus; null preserves material_4's GLB color.
  final Color? busBodyColor;
  final double width;
  final double height;
  final Alignment alignment;
}

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

class _MarkerTransition {
  const _MarkerTransition({
    required this.from,
    required this.to,
    required this.startedAt,
    required this.duration,
    required this.fromHeading,
    required this.toHeading,
  });

  final GeoPoint from;
  final GeoPoint to;
  final DateTime startedAt;
  final Duration duration;
  final double? fromHeading;
  final double? toHeading;
}

/// Map camera façade used by the feature layer on Android and web.
class TrackletMapController {
  MapboxMap? _map;
  GeoPoint _center = MapConfig.campusCenter;
  double _zoom = MapConfig.defaultZoom;

  GeoPoint get center => _center;
  double get zoom => _zoom;

  Future<void> attach(MapboxMap map) async {
    _map = map;
    await map.setBounds(
      CameraBoundsOptions(
        bounds: CoordinateBounds(
          southwest: Point(
            coordinates: Position(MapConfig.minLng, MapConfig.minLat),
          ),
          northeast: Point(
            coordinates: Position(MapConfig.maxLng, MapConfig.maxLat),
          ),
          infiniteBounds: false,
        ),
        minZoom: MapConfig.minZoom,
        maxZoom: MapConfig.maxZoom,
      ),
    );
    await map.setCamera(_cameraOptions(_center, _zoom));
  }

  void updateCamera(CameraState state) {
    final coordinates = state.center.coordinates;
    _center = GeoPoint(
      latitude: coordinates.lat.toDouble(),
      longitude: coordinates.lng.toDouble(),
    );
    _zoom = state.zoom;
  }

  void moveTo(GeoPoint point, {double? zoom}) {
    if (!_isValidPoint(point)) return;
    _center = point;
    _zoom = zoom ?? _zoom;
    final map = _map;
    if (map != null) _sendCamera(map.setCamera(_cameraOptions(point, _zoom)));
  }

  void animatedMoveTo(
    TickerProvider vsync,
    GeoPoint point, {
    double? zoom,
    Duration duration = const Duration(milliseconds: 380),
    Curve curve = Curves.easeOutCubic,
    bool disableAnimations = false,
  }) {
    if (!_isValidPoint(point)) return;
    _center = point;
    _zoom = zoom ?? _zoom;
    final map = _map;
    if (map == null) return;
    final camera = _cameraOptions(point, _zoom);
    if (disableAnimations) {
      _sendCamera(map.setCamera(camera));
    } else {
      _sendCamera(
        map.easeTo(
          camera,
          MapAnimationOptions(duration: duration.inMilliseconds),
        ),
      );
    }
  }

  void fitBounds(
    List<GeoPoint> points, {
    EdgeInsets padding = const EdgeInsets.all(TrackletSpacing.mapViewportInset),
  }) => unawaited(_fitBounds(points, padding, animated: false));

  void animatedFitBounds(
    TickerProvider vsync,
    List<GeoPoint> points, {
    EdgeInsets padding = const EdgeInsets.all(TrackletSpacing.mapViewportInset),
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
    bool disableAnimations = false,
  }) => unawaited(
    _fitBounds(
      points,
      padding,
      animated: !disableAnimations,
      duration: duration,
    ),
  );

  Future<void> _fitBounds(
    List<GeoPoint> points,
    EdgeInsets padding, {
    required bool animated,
    Duration duration = const Duration(milliseconds: 400),
  }) async {
    final map = _map;
    final valid = points.where(_isValidPoint).toList();
    if (map == null || valid.isEmpty) return;
    if (valid.length == 1) {
      _center = valid.single;
      final camera = _cameraOptions(valid.single, _zoom);
      try {
        if (animated) {
          await map.easeTo(
            camera,
            MapAnimationOptions(duration: duration.inMilliseconds),
          );
        } else {
          await map.setCamera(camera);
        }
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Map camera bounds update failed: $error',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return;
    }
    try {
      final camera = await map.cameraForCoordinatesPadding(
        valid.map(_mapPoint).toList(),
        CameraOptions(zoom: _zoom),
        MbxEdgeInsets(
          top: padding.top,
          left: padding.left,
          bottom: padding.bottom,
          right: padding.right,
        ),
        null,
        null,
      );
      if (animated) {
        await map.easeTo(
          camera,
          MapAnimationOptions(duration: duration.inMilliseconds),
        );
      } else {
        await map.setCamera(camera);
      }
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Map camera bounds update failed: $error',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void recenterCampus({TickerProvider? vsync, bool disableAnimations = false}) {
    if (vsync == null) {
      moveTo(MapConfig.campusCenter, zoom: MapConfig.defaultZoom);
    } else {
      animatedMoveTo(
        vsync,
        MapConfig.campusCenter,
        zoom: MapConfig.defaultZoom,
        disableAnimations: disableAnimations,
      );
    }
  }

  void dispose() => _map = null;

  void _sendCamera(Future<void> action) {
    unawaited(
      action.catchError((Object error, StackTrace stackTrace) {
        AppLogger.warning(
          'Map camera update failed: $error',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }
}

bool _isValidPoint(GeoPoint point) => BusTelemetry.isValidPoint(point);

Point _mapPoint(GeoPoint point) =>
    Point(coordinates: Position(point.longitude, point.latitude));

CameraOptions _cameraOptions(GeoPoint point, double zoom) =>
    CameraOptions(center: _mapPoint(point), zoom: zoom);

/// Single Mapbox Maps SDK view for Android and web.
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
    this.onUserGesture,
    this.onZoomChanged,
  });

  final TrackletMapController controller;
  final GeoPoint initialCenter;
  final double initialZoom;
  final List<MapMarkerData> markers;
  final List<MapPolylineData> polylines;
  final List<MapLabelFeature> labels;
  final void Function(GeoPoint point)? onTap;
  final VoidCallback? onUserGesture;
  final ValueChanged<double>? onZoomChanged;

  @override
  State<TrackletMapView> createState() => _TrackletMapViewState();
}

class _TrackletMapViewState extends State<TrackletMapView>
    with WidgetsBindingObserver {
  static const _markerSource = 'tracklet-markers';
  static const _routeSource = 'tracklet-routes';
  static const _labelSource = TrackletMapCartography.stopLabelSourceId;
  static const _buildingLabelSource =
      TrackletMapCartography.campusBuildingSourceId;
  static const _markerLayer = 'tracklet-marker-circles';
  static const _markerTextLayer = 'tracklet-marker-labels';
  static const _directionLayer = 'tracklet-directions';
  static const _busModelSource = 'tracklet-live-bus-models';
  static const _busModelLayer = 'tracklet-live-bus-model-layer';
  static const _busModelAssetUri = 'asset://${BusModelStyle.assetPath}';

  MapboxMap? _map;
  StreamSubscription<MapContentGestureContext>? _panSubscription;
  StreamSubscription<MapContentGestureContext>? _zoomSubscription;
  Timer? _markerAnimationTimer;
  bool _markerFrameSyncing = false;
  bool _markerFramePending = false;
  final Map<String, _MarkerTransition> _markerTransitions = {};
  final Map<String, GeoPoint> _renderedMarkerPoints = {};
  final Map<String, double> _renderedMarkerHeadings = {};
  String? _lastMarkerData;
  String? _lastRouteData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_markerTransitions.isNotEmpty) _startMarkerAnimationTimer();
    } else {
      _markerAnimationTimer?.cancel();
      _markerAnimationTimer = null;
    }
  }

  bool _styleReady = false;
  bool _busModelLayerInstalled = false;
  bool _busModelUnavailable = false;
  Set<String> _busModelIds = {};
  final Map<String, GeoPoint> _busModelAnchors = {};
  final Map<String, String> _busModelFeatureState = {};
  String? _error;
  String? _styleUri;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final styleUri = AppConfig.effectiveMapboxStyleUrlForTheme(dark);
    if (_styleUri != null && styleUri != _styleUri) {
      _styleReady = false;
      final map = _map;
      if (map != null) {
        unawaited(
          map.setStyleURI(styleUri).catchError((Object error) {
            AppLogger.warning(
              'Map style update failed: $error',
              tag: 'TrackletMapView',
            );
          }),
        );
      }
    }
    _styleUri = styleUri;
  }

  @override
  void didUpdateWidget(covariant TrackletMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _prepareMarkerTransitions(oldWidget.markers);
    if (_styleReady) _syncMapData(oldWidget: oldWidget);
  }

  void _prepareMarkerTransitions(List<MapMarkerData> previousMarkers) {
    final previousById = {
      for (final marker in previousMarkers) marker.id: marker,
    };
    final activeIds = <String>{};
    final now = DateTime.now();
    for (final marker in widget.markers) {
      if (!marker.id.startsWith('bus-') ||
          !marker.animatePosition ||
          !_isValidPoint(marker.point)) {
        continue;
      }
      activeIds.add(marker.id);
      final previous = previousById[marker.id];
      final from = _renderedMarkerPoints[marker.id] ?? previous?.point;
      if (from == null || !_isValidPoint(from)) {
        _renderedMarkerPoints[marker.id] = marker.point;
        continue;
      }
      if (from == marker.point) continue;
      if (BusTelemetry.isLargeJump(from, marker.point)) {
        _renderedMarkerPoints[marker.id] = marker.point;
        _markerTransitions.remove(marker.id);
        continue;
      }
      final previousTime = previous?.timestamp;
      final cadence =
          previousTime == null || marker.timestamp == null
              ? BusTelemetry.pollingInterval
              : marker.timestamp!.difference(previousTime);
      if (cadence <= Duration.zero ||
          cadence > BusTelemetry.maxInterpolationGap) {
        _renderedMarkerPoints[marker.id] = marker.point;
        _markerTransitions.remove(marker.id);
        continue;
      }
      final duration = BusTelemetry.animationDuration(cadence);
      final fromHeading =
          _renderedMarkerHeadings[marker.id] ?? previous?.headingDegrees;
      final toHeading = marker.headingDegrees;
      if (toHeading == null && fromHeading != null) {
        _renderedMarkerHeadings[marker.id] = fromHeading;
      }
      _markerTransitions[marker.id] = _MarkerTransition(
        from: from,
        to: marker.point,
        startedAt: now,
        duration: duration,
        fromHeading: fromHeading,
        toHeading: toHeading,
      );
    }
    _renderedMarkerPoints.removeWhere((id, _) => !activeIds.contains(id));
    _renderedMarkerHeadings.removeWhere((id, _) => !activeIds.contains(id));
    _markerTransitions.removeWhere((id, _) => !activeIds.contains(id));
    if (_markerTransitions.isEmpty) {
      _markerAnimationTimer?.cancel();
      _markerAnimationTimer = null;
    } else {
      _startMarkerAnimationTimer();
    }
  }

  void _startMarkerAnimationTimer() {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        _markerTransitions.isEmpty) {
      return;
    }
    _markerAnimationTimer ??= Timer.periodic(
      const Duration(milliseconds: 33),
      (_) => _syncMarkerFrame(),
    );
  }

  GeoPoint _displayedPoint(MapMarkerData marker) =>
      _renderedMarkerPoints[marker.id] ?? marker.point;

  double? _displayedHeading(MapMarkerData marker) =>
      _renderedMarkerHeadings[marker.id] ?? marker.headingDegrees;

  Future<void> _syncMarkerFrame() async {
    if (!_styleReady || _map == null || !mounted) return;
    if (_markerFrameSyncing) {
      _markerFramePending = true;
      return;
    }
    _markerFrameSyncing = true;
    final now = DateTime.now();
    for (final entry in _markerTransitions.entries.toList()) {
      final transition = entry.value;
      final fraction = (now.difference(transition.startedAt).inMicroseconds /
              transition.duration.inMicroseconds)
          .clamp(0.0, 1.0);
      _renderedMarkerPoints[entry.key] = BusTelemetry.interpolatePoint(
        transition.from,
        transition.to,
        fraction,
      );
      if (transition.fromHeading != null && transition.toHeading != null) {
        _renderedMarkerHeadings[entry.key] = BusTelemetry.interpolateHeading(
          transition.fromHeading!,
          transition.toHeading!,
          fraction,
        );
      }
      if (fraction >= 1) {
        _renderedMarkerPoints[entry.key] = transition.to;
        _markerTransitions.remove(entry.key);
        final marker =
            widget.markers.where((item) => item.id == entry.key).firstOrNull;
        if (marker != null && marker.headingDegrees != null) {
          _renderedMarkerHeadings[entry.key] = marker.headingDegrees!;
        }
      }
    }
    try {
      await _syncBusModels();
      final data = _markerData();
      if (data != _lastMarkerData) {
        await _map!.setStyleSourceProperty(_markerSource, 'data', data);
        _lastMarkerData = data;
      }
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Bus marker animation update failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'TrackletMapView',
      );
    } finally {
      _markerFrameSyncing = false;
      if (_markerTransitions.isEmpty) {
        _markerAnimationTimer?.cancel();
        _markerAnimationTimer = null;
      }
      if (_markerFramePending) {
        _markerFramePending = false;
        unawaited(_syncMarkerFrame());
      }
    }
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    try {
      await widget.controller.attach(map);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Mapbox camera configuration failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'TrackletMapView',
      );
    }
    map.addInteraction(
      TapInteraction.onMap((context) => unawaited(_onMapTap(context))),
    );
    _panSubscription = map.gestures.pan.gestureEvents.listen(
      (_) => widget.onUserGesture?.call(),
    );
    _zoomSubscription = map.gestures.zoom.gestureEvents.listen(
      (_) => widget.onUserGesture?.call(),
    );
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    _styleReady = false;
    _lastMarkerData = null;
    _lastRouteData = null;
    _busModelLayerInstalled = false;
    _busModelUnavailable = false;
    _busModelIds.clear();
    _busModelAnchors.clear();
    _busModelFeatureState.clear();
    try {
      await _installStyleLayers();
      _styleReady = true;
      _error = null;
      await _syncMapData();
    } catch (error, stackTrace) {
      _error = 'Map setup failed. Check your connection and try again.';
      AppLogger.error(
        'Mapbox style setup failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'TrackletMapView',
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _installStyleLayers() async {
    final map = _map;
    if (map == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await _styleBaseMap(map);
    await _syncBusModels();
    await map.addStyleSource(_markerSource, _geoJsonSource(_markerData()));
    await map.addStyleSource(_routeSource, _geoJsonSource(_routeData()));
    await map.addStyleSource(
      _labelSource,
      _geoJsonSource(
        TrackletMapCartography.toGeoJson(
          widget.labels.where((label) => label.kind == MapLabelKind.stop),
        ),
      ),
    );
    await map.addStyleSource(
      _buildingLabelSource,
      _geoJsonSource(
        TrackletMapCartography.toGeoJson(
          widget.labels.where((label) => label.kind == MapLabelKind.building),
        ),
      ),
    );
    await map.addStyleLayer(
      jsonEncode({
        'id': 'tracklet-route-lines',
        'type': 'line',
        'source': _routeSource,
        'filter': [
          '!=',
          ['get', 'dotted'],
          true,
        ],
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {
          'line-color': ['get', 'color'],
          'line-width': ['get', 'width'],
          'line-opacity': ['get', 'opacity'],
        },
      }),
      null,
    );
    await map.addStyleLayer(
      jsonEncode({
        'id': 'tracklet-route-dotted-lines',
        'type': 'line',
        'source': _routeSource,
        'filter': [
          '==',
          ['get', 'dotted'],
          true,
        ],
        'layout': {'line-cap': 'round', 'line-join': 'round'},
        'paint': {
          'line-color': ['get', 'color'],
          'line-width': ['get', 'width'],
          'line-opacity': ['get', 'opacity'],
          'line-dasharray': [2, 2],
        },
      }),
      null,
    );
    await map.addStyleLayer(
      jsonEncode({
        'id': _markerLayer,
        'type': 'circle',
        'source': _markerSource,
        'filter': [
          'all',
          [
            '!=',
            ['get', 'kind'],
            'direction',
          ],
          [
            '!=',
            ['get', 'model3d'],
            true,
          ],
        ],
        'paint': {
          'circle-radius': ['get', 'radius'],
          'circle-color': ['get', 'color'],
          'circle-stroke-color': ['get', 'stroke'],
          'circle-stroke-width': ['get', 'strokeWidth'],
        },
      }),
      null,
    );
    await map.addStyleLayer(
      jsonEncode({
        'id': _markerTextLayer,
        'type': 'symbol',
        'source': _markerSource,
        'filter': [
          'all',
          [
            '!=',
            ['get', 'kind'],
            'direction',
          ],
          [
            '!=',
            ['get', 'label'],
            '',
          ],
        ],
        'layout': {
          'text-field': ['get', 'label'],
          'text-font': ['DIN Pro Medium', 'Arial Unicode MS Regular'],
          'text-size': ['get', 'textSize'],
          'text-anchor': ['get', 'textAnchor'],
          'text-offset': ['get', 'textOffset'],
          'text-allow-overlap': false,
          'text-ignore-placement': false,
        },
        'paint': {
          'text-color': ['get', 'labelColor'],
          'text-halo-color': ['get', 'halo'],
          'text-halo-width': 1.5,
        },
      }),
      null,
    );
    await map.addStyleLayer(
      jsonEncode({
        'id': _directionLayer,
        'type': 'symbol',
        'source': _markerSource,
        'filter': [
          '==',
          ['get', 'kind'],
          'direction',
        ],
        'layout': {
          'text-field': '➤',
          'text-font': ['DIN Pro Medium', 'Arial Unicode MS Regular'],
          'text-size': 16,
          'text-rotate': ['get', 'rotation'],
          'text-rotation-alignment': 'map',
          'text-allow-overlap': true,
        },
        'paint': {
          'text-color': ['get', 'color'],
          'text-halo-color': '#ffffff',
          'text-halo-width': 1,
        },
      }),
      null,
    );
    for (final definition in TrackletMapCartography.labelLayerDefinitions(
      isDark: isDark,
    )) {
      await map.addStyleLayer(jsonEncode(definition), null);
    }
  }

  Future<void> _syncBusModels() async {
    final map = _map;
    if (map == null || _busModelUnavailable) return;
    final models =
        widget.markers
            .where(
              (marker) => marker.show3dModel && _isValidPoint(marker.point),
            )
            .toList();
    final modelIds = models.map((marker) => marker.id).toSet();
    if (modelIds.length != _busModelIds.length ||
        !modelIds.containsAll(_busModelIds)) {
      try {
        if (_busModelLayerInstalled) {
          await map.removeStyleLayer(_busModelLayer);
          await map.removeStyleSource(_busModelSource);
          _busModelLayerInstalled = false;
        }
        _busModelIds = modelIds;
        _busModelAnchors
          ..clear()
          ..addEntries(
            models.map((marker) => MapEntry(marker.id, marker.point)),
          );
        _busModelFeatureState.clear();
        if (models.isEmpty) return;

        final modelUri =
            await MapboxMapsOptions.getFlutterAssetPath(_busModelAssetUri) ??
            _busModelAssetUri;
        await map.addSource(
          ModelSource(
            id: _busModelSource,
            models: [
              for (final marker in models)
                ModelSourceModel(
                  id: marker.id,
                  uri: modelUri,
                  position: [
                    _displayedPoint(marker).longitude,
                    _displayedPoint(marker).latitude,
                  ],
                  orientation: const [0, 0, 0],
                  materialOverrideNames: [BusModelStyle.bodyMaterialName],
                  featureProperties: {'trackletId': marker.id},
                ),
            ],
          ),
        );
        await map.addLayer(
          ModelLayer(id: _busModelLayer, sourceId: _busModelSource)
            ..modelScaleExpression = BusModelStyle.modelScaleExpression
            ..modelType = ModelType.LOCATION_INDICATOR
            ..modelColorExpression = BusModelStyle.bodyColorExpression
            ..modelColorMixIntensityExpression =
                BusModelStyle.bodyColorMixIntensityExpression
            ..modelRotationExpression = const ['feature-state', 'rotation']
            ..modelTranslationExpression = const [
              'feature-state',
              'translation',
            ],
        );
        _busModelLayerInstalled = true;
      } catch (error, stackTrace) {
        _busModelUnavailable = true;
        _busModelLayerInstalled = false;
        _busModelIds.clear();
        _busModelAnchors.clear();
        _busModelFeatureState.clear();
        AppLogger.warning(
          '3D bus models unavailable; keeping 2D bus markers: $error',
          error: error,
          stackTrace: stackTrace,
          tag: 'TrackletMapView',
        );
        try {
          await map.removeStyleLayer(_busModelLayer);
        } catch (_) {}
        try {
          await map.removeStyleSource(_busModelSource);
        } catch (_) {}
      }
    }

    if (!_busModelLayerInstalled) return;
    for (final marker in models) {
      final anchor = _busModelAnchors[marker.id];
      if (anchor == null) continue;
      final state = jsonEncode({
        'bodyColorEnabled': marker.busBodyColor != null,
        'bodyColor':
            marker.busBodyColor == null
                ? '#ffffff'
                : _hex(marker.busBodyColor!),
        'rotation': BusModelStyle.rotation(_displayedHeading(marker)),
        'translation': BusModelStyle.translation(
          anchor,
          _displayedPoint(marker),
        ),
      });
      if (_busModelFeatureState[marker.id] == state) continue;
      try {
        await map.setFeatureState(_busModelSource, null, marker.id, state);
        _busModelFeatureState[marker.id] = state;
      } catch (error, stackTrace) {
        _busModelUnavailable = true;
        _busModelLayerInstalled = false;
        AppLogger.warning(
          '3D bus model update failed; keeping 2D bus markers: $error',
          error: error,
          stackTrace: stackTrace,
          tag: 'TrackletMapView',
        );
        try {
          await map.removeStyleLayer(_busModelLayer);
        } catch (_) {}
        try {
          await map.removeStyleSource(_busModelSource);
        } catch (_) {}
        break;
      }
    }
  }

  Future<void> _styleBaseMap(MapboxMap map) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final layers = await map.getStyleLayers();
    for (final layer in layers.whereType<StyleObjectInfo>()) {
      try {
        final properties = jsonDecode(
          await map.getStyleLayerProperties(layer.id),
        );
        final sourceLayer =
            properties is Map ? properties['source-layer'] as String? : null;
        final treatment = TrackletMapCartography.treatmentFor(
          type: layer.type,
          sourceLayer: sourceLayer,
        );
        for (final entry
            in TrackletMapCartography.layerOverrides(
              treatment,
              isDark: isDark,
            ).entries) {
          await map.setStyleLayerProperty(layer.id, entry.key, entry.value);
        }
      } catch (error) {
        AppLogger.warning(
          'Map style layer ${layer.id} could not be themed: $error',
          tag: 'TrackletMapView',
        );
      }
    }
  }

  Future<void> _syncMapData({TrackletMapView? oldWidget}) async {
    final map = _map;
    if (map == null || !_styleReady) return;
    try {
      await _syncBusModels();
      final markerData = _markerData();
      if (markerData != _lastMarkerData) {
        await map.setStyleSourceProperty(_markerSource, 'data', markerData);
        _lastMarkerData = markerData;
      }
      final routeData = _routeData();
      if (routeData != _lastRouteData) {
        await map.setStyleSourceProperty(_routeSource, 'data', routeData);
        _lastRouteData = routeData;
      }
      if (oldWidget == null || !identical(widget.labels, oldWidget.labels)) {
        await map.setStyleSourceProperty(
          _labelSource,
          'data',
          TrackletMapCartography.toGeoJson(
            widget.labels.where((label) => label.kind == MapLabelKind.stop),
          ),
        );
        await map.setStyleSourceProperty(
          _buildingLabelSource,
          'data',
          TrackletMapCartography.toGeoJson(
            widget.labels.where((label) => label.kind == MapLabelKind.building),
          ),
        );
      }
    } catch (error, stackTrace) {
      _error = 'Map data could not be updated. The map will retry on refresh.';
      AppLogger.error(
        'Mapbox feature update failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'TrackletMapView',
      );
      if (mounted) setState(() {});
    }
  }

  Future<void> _onMapTap(MapContentGestureContext context) async {
    final map = _map;
    if (map == null) return;
    try {
      final results = await map.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenBox(
          ScreenBox(
            min: ScreenCoordinate(
              x: context.touchPosition.x - 24,
              y: context.touchPosition.y - 24,
            ),
            max: ScreenCoordinate(
              x: context.touchPosition.x + 24,
              y: context.touchPosition.y + 24,
            ),
          ),
        ),
        RenderedQueryOptions(
          layerIds: [
            _markerLayer,
            _markerTextLayer,
            _directionLayer,
            if (_busModelLayerInstalled) _busModelLayer,
          ],
        ),
      );
      for (final result in results) {
        final properties = result?.queriedFeature.feature['properties'];
        final id =
            (properties is Map ? properties['trackletId'] : null)?.toString() ??
            result?.queriedFeature.feature['id']?.toString();
        final marker =
            widget.markers.where((item) => item.id == id).firstOrNull;
        if (marker?.onTap != null) {
          marker!.onTap!();
          return;
        }
      }
      final coordinates = context.touchPosition;
      final point = await map.coordinateForPixel(coordinates);
      widget.onTap?.call(
        GeoPoint(
          latitude: point.coordinates.lat.toDouble(),
          longitude: point.coordinates.lng.toDouble(),
        ),
      );
    } catch (error) {
      AppLogger.warning(
        'Map tap hit testing failed: $error',
        tag: 'TrackletMapView',
      );
    }
  }

  String _markerData() {
    final features = <Map<String, Object?>>[];
    for (final marker in widget.markers) {
      if (!_isValidPoint(marker.point)) continue;
      final isBus = marker.id.startsWith('bus-');
      final isUser = marker.id == 'user-location-marker';
      final isDirection = marker.id.startsWith('route-direction-');
      final kind =
          isBus
              ? 'bus'
              : isUser
              ? 'user'
              : isDirection
              ? 'direction'
              : 'stop';
      final stale =
          marker.subtitle?.toLowerCase().contains('stale') == true ||
          marker.subtitle?.toLowerCase().contains('offline') == true ||
          marker.subtitle?.toLowerCase().contains('no location') == true;
      final stationary =
          marker.subtitle?.toLowerCase().contains('stationary') == true;
      final color = _hex(
        isUser
            ? TrackletColors.primary
            : stale
            ? TrackletColors.busOffline
            : stationary
            ? TrackletColors.warningStrong
            : marker.accentColor ?? TrackletColors.primary,
      );
      final label = isBus && marker.showLabel ? (marker.title ?? '') : '';
      final displayedPoint = _applyScreenOffset(
        marker,
        _displayedPoint(marker),
      );
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [displayedPoint.longitude, displayedPoint.latitude],
        },
        'properties': {
          'trackletId': marker.id,
          'kind': kind,
          'color': color,
          'stroke': marker.isSelected ? '#FFFFFF' : color,
          'strokeWidth': marker.isSelected ? 3 : (isUser ? 2 : 1.5),
          'radius':
              isUser
                  ? 8
                  : isDirection
                  ? 0
                  : marker.isSelected
                  ? 10
                  : isBus
                  ? 8
                  : marker.isMajorHub
                  ? 7
                  : 5.5,
          'label': marker.showLabel ? label : '',
          'labelColor': marker.isSelected ? '#342B74' : '#34313E',
          'halo': '#FFFFFF',
          'textSize': marker.isMajorHub || marker.isSelected ? 11 : 10,
          'textAnchor': 'top',
          'textOffset': [0, isBus ? 1.15 : 1.35],
          'rotation': _displayedHeading(marker) ?? 0,
          'model3d':
              _busModelLayerInstalled &&
              marker.show3dModel &&
              !_busModelUnavailable,
        },
      });
    }
    return jsonEncode({'type': 'FeatureCollection', 'features': features});
  }

  String _routeData() {
    final features = <Map<String, Object?>>[];
    for (final line in widget.polylines) {
      final points = line.points.where(_isValidPoint).toList();
      if (points.length < 2) continue;
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            for (final point in points) [point.longitude, point.latitude],
          ],
        },
        'properties': {
          'color': _hex(line.color),
          'width': line.strokeWidth,
          'opacity': 1.0,
          'dotted': line.isDotted,
        },
      });
    }
    return jsonEncode({'type': 'FeatureCollection', 'features': features});
  }

  GeoPoint _applyScreenOffset(MapMarkerData marker, GeoPoint point) {
    if (marker.alignment == Alignment.center) return point;
    final zoomScale =
        40075016.686 *
        math.cos(point.latitude * math.pi / 180) /
        (512 * math.pow(2, widget.controller.zoom));
    final xOffsetMeters = -marker.alignment.x * marker.width / 2 * zoomScale;
    final yOffsetMeters = -marker.alignment.y * marker.height / 2 * zoomScale;
    return GeoPoint(
      latitude: point.latitude - yOffsetMeters / 111320,
      longitude:
          point.longitude +
          xOffsetMeters / (111320 * math.cos(point.latitude * math.pi / 180)),
    );
  }

  String _geoJsonSource(String data) =>
      jsonEncode({'type': 'geojson', 'data': jsonDecode(data)});

  String _hex(Color color) =>
      '#${(color.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}';

  void _onCameraChanged(CameraChangedEventData event) {
    widget.controller.updateCamera(event.cameraState);
    widget.onZoomChanged?.call(event.cameraState.zoom);
  }

  void _onMapLoadError(MapLoadingErrorEventData event) {
    _error = 'Map tiles could not be loaded. Check your connection.';
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _markerAnimationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _panSubscription?.cancel();
    _zoomSubscription?.cancel();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isMapboxConfigured) {
      return const Center(
        child: Text('Mapbox access token is not configured.'),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        MapWidget(
          styleUri: _styleUri ?? AppConfig.effectiveMapboxStyleUrl,
          viewport: CameraViewportState(
            center: _mapPoint(widget.initialCenter),
            zoom: widget.initialZoom,
          ),
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
          onCameraChangeListener: _onCameraChanged,
          onMapLoadErrorListener: _onMapLoadError,
        ),
        if (_error case final error?)
          Positioned(
            left: TrackletSpacing.md,
            right: TrackletSpacing.md,
            bottom: TrackletSpacing.md,
            child: Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(TrackletSpacing.sm),
                child: Text(
                  error,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
