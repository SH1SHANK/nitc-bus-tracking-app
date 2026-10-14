import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../core/geo/geo_point.dart';
import '../../core/logging/app_logger.dart';
import '../../data/transit/bus_telemetry.dart';
import '../../design_system/components/tracklet_error_state.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import 'map_cartography.dart';
import 'map_config.dart';
import 'offline_map_manager.dart';

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
    this.accentColor,
    this.onTap,
    this.animatePosition = false,
    this.sequenceNumber,
    this.epoch,
    this.timestamp,
    this.speedKmH,
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
  final Color? accentColor;
  final VoidCallback? onTap;
  final bool animatePosition;
  final int? sequenceNumber;
  final int? epoch;
  final DateTime? timestamp;
  final double? speedKmH;
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
  TrackletMapController() : _mapController = fmap.MapController();

  final fmap.MapController _mapController;
  AnimationController? _activeAnimation;

  void moveTo(GeoPoint point, {double? zoom}) {
    _activeAnimation?.stop();
    _activeAnimation = null;
    try {
      _mapController.move(
        ll.LatLng(point.latitude, point.longitude),
        zoom ?? MapConfig.defaultZoom,
      );
    } catch (e) {
      AppLogger.warning('Camera moveTo failed: $e');
    }
  }

  void animatedMoveTo(
    TickerProvider vsync,
    GeoPoint target, {
    double? zoom,
    Duration duration = const Duration(milliseconds: 380),
    Curve curve = Curves.easeOutCubic,
    bool disableAnimations = false,
  }) {
    if (disableAnimations) {
      moveTo(target, zoom: zoom);
      return;
    }

    _activeAnimation?.stop();
    final startLatLng = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;
    final endLatLng = ll.LatLng(target.latitude, target.longitude);
    final endZoom = zoom ?? startZoom;

    final controller = AnimationController(vsync: vsync, duration: duration);
    _activeAnimation = controller;
    final animation = CurvedAnimation(parent: controller, curve: curve);

    controller.addListener(() {
      try {
        final currentLat =
            startLatLng.latitude +
            (endLatLng.latitude - startLatLng.latitude) * animation.value;
        final currentLng =
            startLatLng.longitude +
            (endLatLng.longitude - startLatLng.longitude) * animation.value;
        final currentZoom = startZoom + (endZoom - startZoom) * animation.value;
        _mapController.move(ll.LatLng(currentLat, currentLng), currentZoom);
      } catch (e) {
        AppLogger.warning('Camera animatedMoveTo tick failed: $e');
      }
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
        if (_activeAnimation == controller) {
          _activeAnimation = null;
        }
      }
    });

    controller.forward();
  }

  void fitBounds(
    List<GeoPoint> points, {
    EdgeInsets padding = const EdgeInsets.all(48),
  }) {
    _activeAnimation?.stop();
    _activeAnimation = null;
    if (points.isEmpty) return;
    if (points.length == 1) {
      moveTo(points.first);
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
      _mapController.fitCamera(
        fmap.CameraFit.bounds(bounds: bounds, padding: padding),
      );
    } catch (e) {
      AppLogger.warning('Camera fitBounds failed: $e');
    }
  }

  void animatedFitBounds(
    TickerProvider vsync,
    List<GeoPoint> points, {
    EdgeInsets padding = const EdgeInsets.all(48),
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
    bool disableAnimations = false,
  }) {
    if (disableAnimations || points.isEmpty) {
      fitBounds(points, padding: padding);
      return;
    }

    if (points.length == 1) {
      animatedMoveTo(
        vsync,
        points.first,
        duration: duration,
        curve: curve,
        disableAnimations: disableAnimations,
      );
      return;
    }

    // Direct fit camera via flutter_map CameraFit which guarantees bounds containment
    fitBounds(points, padding: padding);
  }

  void recenterCampus({TickerProvider? vsync, bool disableAnimations = false}) {
    if (vsync != null && !disableAnimations) {
      animatedMoveTo(
        vsync,
        MapConfig.campusCenter,
        zoom: MapConfig.defaultZoom,
      );
    } else {
      moveTo(MapConfig.campusCenter, zoom: MapConfig.defaultZoom);
    }
  }

  void dispose() {
    _activeAnimation?.stop();
    _activeAnimation?.dispose();
    _activeAnimation = null;
    _mapController.dispose();
  }
}

bool _isValidPoint(GeoPoint point) =>
    point.latitude.isFinite &&
    point.longitude.isFinite &&
    point.latitude >= -90 &&
    point.latitude <= 90 &&
    point.longitude >= -180 &&
    point.longitude <= 180;

class _AnimatedMarkerLayer extends StatefulWidget {
  const _AnimatedMarkerLayer({required this.markers});

  final List<MapMarkerData> markers;

  @override
  State<_AnimatedMarkerLayer> createState() => _AnimatedMarkerLayerState();
}

class _AnimatedMarkerLayerState extends State<_AnimatedMarkerLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  final Map<String, GeoPoint> _from = {};
  final Map<String, GeoPoint> _to = {};
  final Map<String, MapMarkerData> _accepted = {};

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, value: 1);
    for (final marker in widget.markers) {
      if (_isValidPoint(marker.point)) {
        _from[marker.id] = _to[marker.id] = marker.point;
        _accepted[marker.id] = marker;
      }
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    var shouldAnimate = false;
    final ids = widget.markers.map((marker) => marker.id).toSet();
    _from.removeWhere((id, _) => !ids.contains(id));
    _to.removeWhere((id, _) => !ids.contains(id));
    _accepted.removeWhere((id, _) => !ids.contains(id));

    for (final marker in widget.markers) {
      if (!_isValidPoint(marker.point)) continue;
      final previous = _accepted[marker.id];
      if (previous == null || !marker.animatePosition) {
        _from[marker.id] = _to[marker.id] = marker.point;
        _accepted[marker.id] = marker;
        continue;
      }

      final previousTime = previous.timestamp;
      final incomingTime = marker.timestamp;
      final previousSequence = previous.sequenceNumber;
      final incomingSequence = marker.sequenceNumber;
      if (previousTime == null ||
          incomingTime == null ||
          !BusTelemetry.shouldAcceptPacket(
            previousEpoch: previous.epoch,
            incomingEpoch: marker.epoch,
            previousSequence: previousSequence,
            previousTimestamp: previousTime,
            incomingSequence: incomingSequence,
            incomingTimestamp: incomingTime,
          )) {
        continue;
      }

      final isSequenceReset = BusTelemetry.isSequenceReset(
        previousSequence,
        incomingSequence,
      );
      final isEpochReset = BusTelemetry.isEpochReset(
        previous.epoch,
        marker.epoch,
      );
      if (_animation.isAnimating) {
        _from[marker.id] = BusTelemetry.interpolatePoint(
          _from[marker.id] ?? _to[marker.id] ?? previous.point,
          _to[marker.id] ?? previous.point,
          _animation.value,
        );
      } else {
        _from[marker.id] = _to[marker.id] ?? previous.point;
      }
      if ((previous.speedKmH ?? double.infinity) < 2 &&
          (marker.speedKmH ?? double.infinity) < 2 &&
          BusTelemetry.distanceMeters(_from[marker.id]!, marker.point) < 8) {
        _accepted[marker.id] = marker;
        continue;
      }
      _to[marker.id] = marker.point;
      _accepted[marker.id] = marker;
      if (isEpochReset ||
          isSequenceReset ||
          BusTelemetry.isLargeJump(_from[marker.id]!, marker.point)) {
        _from[marker.id] = marker.point;
      } else {
        _animation.duration = BusTelemetry.animationDuration(
          incomingTime.difference(previousTime),
        );
        shouldAnimate = true;
      }
    }
    if (shouldAnimate) _animation.forward(from: 0);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder:
        (context, _) => fmap.MarkerLayer(
          markers: [
            for (final incoming in widget.markers)
              if (_isValidPoint(incoming.point)) _buildMarker(incoming),
          ],
        ),
  );

  ll.LatLng _displayedPoint(MapMarkerData marker) {
    final from = _from[marker.id] ?? marker.point;
    final to = _to[marker.id] ?? marker.point;
    final point =
        marker.animatePosition
            ? BusTelemetry.interpolatePoint(from, to, _animation.value)
            : marker.point;
    return ll.LatLng(point.latitude, point.longitude);
  }

  fmap.Marker _buildMarker(MapMarkerData incoming) {
    return fmap.Marker(
      key: ValueKey('map-marker-${incoming.id}'),
      point: _displayedPoint(incoming),
      width: incoming.width,
      height: incoming.height,
      alignment: incoming.alignment,
      child: incoming.child,
    );
  }
}

/// Primary map view backed by the local QGIS-generated NITC MBTiles offline raster basemap.
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
    this.offlineMapManager,
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
  final OfflineMapManager? offlineMapManager;

  @override
  State<TrackletMapView> createState() => _TrackletMapViewState();
}

class _TrackletMapViewState extends State<TrackletMapView> {
  late final OfflineMapManager _mapManager;
  MbTilesTileProvider? _tileProvider;
  String? _initError;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _mapManager = widget.offlineMapManager ?? OfflineMapManager();
    _initOfflineMap();
  }

  Future<void> _initOfflineMap() async {
    if (kIsWeb) {
      setState(() {
        _initError =
            'Offline MBTiles maps are not supported on Flutter Web platforms.';
      });
      return;
    }

    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      await _mapManager.initialize();
      final provider = _mapManager.createTileProvider();
      if (!mounted) {
        provider.dispose();
        return;
      }
      setState(() {
        _tileProvider = provider;
        _isInitializing = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize offline MBTiles tile provider: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'TrackletMapView',
      );
      if (!mounted) return;
      setState(() {
        _tileProvider = null;
        _isInitializing = false;
        _initError = 'Failed to load offline campus map: $e';
      });
    }
  }

  @override
  void dispose() {
    _tileProvider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      debugPrint('TrackletMapView: building web view');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(TrackletSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: TrackletColors.textSecondary,
              ),
              const SizedBox(height: TrackletSpacing.md),
              Text(
                'Offline Campus Map Unsupported on Web',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: TrackletColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TrackletSpacing.xs),
              const Text(
                'The offline NITC raster map requires native SQLite filesystem access and is available on the Android app.',
                style: TextStyle(color: TrackletColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final mapWidget = fmap.FlutterMap(
      key: const ValueKey('tracklet_offline_mbtiles_map_view'),
      mapController: widget.controller._mapController,
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
        onPositionChanged: (camera, hasGesture) {
          widget.onZoomChanged?.call(camera.zoom);
          if (hasGesture) widget.onUserGesture?.call();
        },
        onTap: (tapPosition, point) {
          widget.onTap?.call(
            GeoPoint(latitude: point.latitude, longitude: point.longitude),
          );
        },
      ),
      children: [
        if (_tileProvider != null)
          fmap.TileLayer(
            tileProvider: _tileProvider,
            maxZoom: MapConfig.maxZoom,
            minZoom: MapConfig.minZoom,
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
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                        pattern:
                            line.isDotted
                                ? const fmap.StrokePattern.dotted()
                                : const fmap.StrokePattern.solid(),
                      ),
                    )
                    .toList(),
          ),
        if (widget.markers.isNotEmpty)
          _AnimatedMarkerLayer(markers: widget.markers),
      ],
    );

    if (_isInitializing) {
      return Stack(
        children: [
          mapWidget,
          const Positioned(
            top: TrackletSpacing.md,
            right: TrackletSpacing.md,
            child: SizedBox(
              key: ValueKey('tracklet_map_initializing'),
              width: 24,
              height: 24,
            ),
          ),
        ],
      );
    }

    if (_initError != null && _tileProvider == null) {
      return Stack(
        children: [
          mapWidget,
          Positioned(
            bottom: TrackletSpacing.screenMargin,
            left: TrackletSpacing.screenMargin,
            right: TrackletSpacing.screenMargin,
            child: TrackletErrorState(
              title: 'Offline Basemap Unavailable',
              message:
                  _initError ?? 'Offline MBTiles database could not be loaded.',
              onRetry: _initOfflineMap,
            ),
          ),
        ],
      );
    }

    return mapWidget;
  }
}
