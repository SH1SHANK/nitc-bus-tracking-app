import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../core/config/app_config.dart';
import '../../core/geo/geo_point.dart';
import '../../core/logging/app_logger.dart';
import '../../data/transit/bus_telemetry.dart';
import '../../design_system/components/tracklet_error_state.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'map_cartography.dart';
import 'map_config.dart';
import 'mapbox_web_bridge.dart';
import 'network_connectivity.dart';
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

abstract class _WebMapController {
  void moveTo(GeoPoint point, {double? zoom});
  void animatedMoveTo(GeoPoint point, {double? zoom});
  void fitBounds(
    List<GeoPoint> points, {
    EdgeInsets padding = const EdgeInsets.all(TrackletSpacing.mapViewportInset),
  });
  void animatedFitBounds(
    List<GeoPoint> points, {
    EdgeInsets padding = const EdgeInsets.all(TrackletSpacing.mapViewportInset),
  });
  GeoPoint get center;
  double get zoom;
}

/// Unified map controller handle exposed to feature code for camera manipulations.
class TrackletMapController {
  TrackletMapController() : _mapController = fmap.MapController();

  final fmap.MapController _mapController;
  AnimationController? _activeAnimation;
  _WebMapController? _webMapController;

  void moveTo(GeoPoint point, {double? zoom}) {
    if (!BusTelemetry.isValidPoint(point)) {
      AppLogger.warning('Camera moveTo rejected invalid point: $point');
      return;
    }
    if (kIsWeb && _webMapController != null) {
      _webMapController!.moveTo(point, zoom: zoom);
      return;
    }
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
    if (!BusTelemetry.isValidPoint(target)) {
      AppLogger.warning(
        'Camera animatedMoveTo rejected invalid target: $target',
      );
      return;
    }
    if (kIsWeb && _webMapController != null) {
      _webMapController!.animatedMoveTo(target, zoom: zoom);
      return;
    }
    if (disableAnimations) {
      moveTo(target, zoom: zoom);
      return;
    }

    _activeAnimation?.stop();
    _activeAnimation?.dispose();
    _activeAnimation = null;
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
    EdgeInsets padding = const EdgeInsets.all(TrackletSpacing.mapViewportInset),
  }) {
    if (kIsWeb && _webMapController != null) {
      _webMapController!.fitBounds(points, padding: padding);
      return;
    }
    _activeAnimation?.stop();
    _activeAnimation?.dispose();
    _activeAnimation = null;
    final validPoints = points.where(_isValidPoint).toList();
    if (validPoints.isEmpty) return;
    if (validPoints.length == 1) {
      moveTo(validPoints.first);
      return;
    }

    try {
      final latLngs =
          validPoints
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
    EdgeInsets padding = const EdgeInsets.all(TrackletSpacing.mapViewportInset),
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
    bool disableAnimations = false,
  }) {
    if (kIsWeb && _webMapController != null) {
      _webMapController!.animatedFitBounds(points, padding: padding);
      return;
    }
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

  GeoPoint get center {
    if (kIsWeb && _webMapController != null) {
      return _webMapController!.center;
    }
    final cameraCenter = _mapController.camera.center;
    return GeoPoint(
      latitude: cameraCenter.latitude,
      longitude: cameraCenter.longitude,
    );
  }

  double get zoom {
    if (kIsWeb && _webMapController != null) {
      return _webMapController!.zoom;
    }
    return _mapController.camera.zoom;
  }

  void dispose() {
    _activeAnimation?.stop();
    _activeAnimation?.dispose();
    _activeAnimation = null;
    _webMapController = null;
    _mapController.dispose();
  }
}

bool _isValidPoint(GeoPoint point) => BusTelemetry.isValidPoint(point);

class _MarkerTrack {
  _MarkerTrack({
    required this.from,
    required this.to,
    required this.startElapsed,
    required this.duration,
    required this.marker,
  });

  GeoPoint from;
  GeoPoint to;
  Duration startElapsed;
  Duration duration;
  MapMarkerData marker;

  bool isComplete(Duration currentElapsed) {
    if (duration == Duration.zero) return true;
    return (currentElapsed - startElapsed) >= duration;
  }

  GeoPoint currentPoint(
    Duration currentElapsed, {
    bool disableAnimations = false,
  }) {
    if (disableAnimations || duration == Duration.zero) return to;
    final elapsed = currentElapsed - startElapsed;
    if (elapsed >= duration) return to;
    if (elapsed.isNegative) return from;
    final t = (elapsed.inMicroseconds / duration.inMicroseconds).clamp(
      0.0,
      1.0,
    );
    final curvedT = Curves.easeOutCubic.transform(t);
    return BusTelemetry.interpolatePoint(from, to, curvedT);
  }
}

class _AnimatedMarkerLayer extends StatefulWidget {
  const _AnimatedMarkerLayer({required this.markers});

  final List<MapMarkerData> markers;

  @override
  State<_AnimatedMarkerLayer> createState() => _AnimatedMarkerLayerState();
}

class _AnimatedMarkerLayerState extends State<_AnimatedMarkerLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final Map<String, _MarkerTrack> _tracks = {};
  Duration _currentElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    for (final marker in widget.markers) {
      if (BusTelemetry.isValidPoint(marker.point)) {
        _tracks[marker.id] = _MarkerTrack(
          from: marker.point,
          to: marker.point,
          startElapsed: Duration.zero,
          duration: Duration.zero,
          marker: marker,
        );
      }
    }
  }

  void _onTick(Duration elapsed) {
    _currentElapsed = elapsed;
    var hasActive = false;
    for (final track in _tracks.values) {
      if (!track.isComplete(elapsed)) {
        hasActive = true;
        break;
      }
    }
    setState(() {});
    if (!hasActive && _ticker.isActive) {
      _ticker.stop();
      _currentElapsed = Duration.zero;
      for (final track in _tracks.values) {
        track.duration = Duration.zero;
      }
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final currentIds = <String>{};
    var needsAnimation = false;

    for (final marker in widget.markers) {
      if (!BusTelemetry.isValidPoint(marker.point)) continue;
      currentIds.add(marker.id);
      final existing = _tracks[marker.id];

      if (existing == null || !marker.animatePosition || disableAnimations) {
        _tracks[marker.id] = _MarkerTrack(
          from: marker.point,
          to: marker.point,
          startElapsed: Duration.zero,
          duration: Duration.zero,
          marker: marker,
        );
        continue;
      }

      final prevMarker = existing.marker;
      final prevTime = prevMarker.timestamp;
      final incomingTime = marker.timestamp;
      final prevSeq = prevMarker.sequenceNumber;
      final incomingSeq = marker.sequenceNumber;

      if (prevTime == null ||
          incomingTime == null ||
          !BusTelemetry.shouldAcceptPacket(
            previousEpoch: prevMarker.epoch,
            incomingEpoch: marker.epoch,
            previousSequence: prevSeq,
            previousTimestamp: prevTime,
            incomingSequence: incomingSeq,
            incomingTimestamp: incomingTime,
          )) {
        existing.marker = marker;
        continue;
      }

      final currentPos = existing.currentPoint(
        _currentElapsed,
        disableAnimations: disableAnimations,
      );
      final isSeqReset = BusTelemetry.isSequenceReset(prevSeq, incomingSeq);
      final isEpochReset = BusTelemetry.isEpochReset(
        prevMarker.epoch,
        marker.epoch,
      );
      final isLargeJump = BusTelemetry.isLargeJump(currentPos, marker.point);
      final isStationaryJitter =
          (prevMarker.speedKmH ?? double.infinity) <
              BusTelemetry.stationarySpeedThresholdKmH &&
          (marker.speedKmH ?? double.infinity) <
              BusTelemetry.stationarySpeedThresholdKmH &&
          BusTelemetry.distanceMeters(currentPos, marker.point) <
              BusTelemetry.stationaryDistanceThresholdMeters;
      final timeDifference = incomingTime.difference(prevTime);

      if (isEpochReset ||
          isSeqReset ||
          isLargeJump ||
          isStationaryJitter ||
          timeDifference > BusTelemetry.maxInterpolationGap) {
        existing.from = marker.point;
        existing.to = marker.point;
        existing.startElapsed = Duration.zero;
        existing.duration = Duration.zero;
        existing.marker = marker;
      } else {
        existing.from = currentPos;
        existing.to = marker.point;
        existing.startElapsed =
            _ticker.isActive ? _currentElapsed : Duration.zero;
        existing.duration = BusTelemetry.animationDuration(timeDifference);
        existing.marker = marker;
        needsAnimation = true;
      }
    }

    _tracks.removeWhere((id, _) => !currentIds.contains(id));

    if (needsAnimation && !_ticker.isActive && !disableAnimations) {
      _currentElapsed = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  ll.LatLng _displayedPoint(
    MapMarkerData marker, {
    required bool disableAnimations,
  }) {
    final track = _tracks[marker.id];
    if (track == null) {
      return ll.LatLng(marker.point.latitude, marker.point.longitude);
    }
    final point = track.currentPoint(
      _currentElapsed,
      disableAnimations: disableAnimations,
    );
    return ll.LatLng(point.latitude, point.longitude);
  }

  fmap.Marker _buildMarker(
    MapMarkerData incoming, {
    required bool disableAnimations,
  }) {
    return fmap.Marker(
      key: ValueKey('map-marker-${incoming.id}'),
      point: _displayedPoint(incoming, disableAnimations: disableAnimations),
      width: incoming.width,
      height: incoming.height,
      alignment: incoming.alignment,
      child: RepaintBoundary(child: incoming.child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return fmap.MarkerLayer(
      markers: [
        for (final incoming in widget.markers)
          if (BusTelemetry.isValidPoint(incoming.point))
            _buildMarker(incoming, disableAnimations: disableAnimations),
      ],
    );
  }
}

/// Primary map view backed by Mapbox online raster tiles with local QGIS-generated NITC MBTiles offline fallback.
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
    this.isOnline,
    this.showOfflineBadge = true,
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
  final bool? isOnline;
  final bool showOfflineBadge;

  @override
  State<TrackletMapView> createState() => _TrackletMapViewState();
}

class _TrackletMapViewState extends State<TrackletMapView> {
  late final OfflineMapManager _mapManager;
  MbTilesTileProvider? _tileProvider;
  String? _initError;
  bool _isInitializing = false;
  bool _useOsmFallback = false;

  late bool _isMapboxOnline;
  int _consecutiveTileErrors = 0;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _mapManager = widget.offlineMapManager ?? OfflineMapManager();
    _isMapboxOnline = (widget.isOnline ?? true) && AppConfig.isMapboxConfigured;
    if (!kIsWeb) {
      _initOfflineMap();
      if (_isMapboxOnline && widget.isOnline == null) {
        _checkInitialConnectivity();
      }
    }
  }

  Future<void> _checkInitialConnectivity() async {
    final online = await NetworkConnectivity.isHostReachable('api.mapbox.com');
    if (!mounted) return;
    if (!online && _isMapboxOnline) {
      AppLogger.info(
        'Initial network check unreachable for Mapbox. Falling back to offline local MBTiles.',
        tag: 'TrackletMapView',
      );
      setState(() {
        _isMapboxOnline = false;
      });
      _scheduleReconnectionCheck();
    }
  }

  void _onMapboxTileError(Object error) {
    _consecutiveTileErrors++;
    final isNetwork = _isNetworkError(error);
    if (_consecutiveTileErrors >= 3 || isNetwork) {
      if (mounted && _isMapboxOnline) {
        AppLogger.warning(
          'Mapbox tile loading error ($error). Falling back to offline local MBTiles.',
          tag: 'TrackletMapView',
        );
        setState(() {
          _isMapboxOnline = false;
        });
        _scheduleReconnectionCheck();
      }
    }
  }

  bool _isNetworkError(Object error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('socketexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('clientexception') ||
        errorStr.contains('httpexception') ||
        errorStr.contains('handshake') ||
        errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout') ||
        errorStr.contains('401') ||
        errorStr.contains('403') ||
        errorStr.contains('404') ||
        errorStr.contains('500');
  }

  void _scheduleReconnectionCheck() {
    _reconnectTimer?.cancel();
    if (widget.isOnline != null || !AppConfig.isMapboxConfigured) return;
    _reconnectTimer = Timer.periodic(const Duration(seconds: 25), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final online = await NetworkConnectivity.isHostReachable(
        'api.mapbox.com',
      );
      if (online && mounted) {
        timer.cancel();
        AppLogger.info(
          'Network reachability restored. Re-enabling Mapbox primary map.',
          tag: 'TrackletMapView',
        );
        setState(() {
          _isMapboxOnline = true;
          _consecutiveTileErrors = 0;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant TrackletMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline != oldWidget.isOnline) {
      setState(() {
        _isMapboxOnline =
            (widget.isOnline ?? true) && AppConfig.isMapboxConfigured;
        _consecutiveTileErrors = 0;
      });
      if (!_isMapboxOnline && widget.isOnline == null) {
        _scheduleReconnectionCheck();
      } else if (_isMapboxOnline) {
        _reconnectTimer?.cancel();
      }
    }
  }

  Future<void> _initOfflineMap() async {
    if (kIsWeb) return;

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
    _reconnectTimer?.cancel();
    _tileProvider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      if (AppConfig.isMapboxConfigured && _isMapboxOnline) {
        return _TrackletWebMapboxView(
          key: const ValueKey('tracklet_mapbox_web_view'),
          controller: widget.controller,
          initialCenter: widget.initialCenter,
          initialZoom: widget.initialZoom,
          markers: widget.markers,
          polylines: widget.polylines,
          labels: widget.labels,
          onTap: widget.onTap,
          onUserGesture: widget.onUserGesture,
          onZoomChanged: widget.onZoomChanged,
        );
      }

      if (!_useOsmFallback) {
        return _MapboxWebConfigPlaceholder(
          onUseOsmFallback: () => setState(() => _useOsmFallback = true),
        );
      }
    }

    final isFallbackActive =
        AppConfig.isMapboxConfigured &&
        !_isMapboxOnline &&
        _tileProvider != null;

    final isDark = TrackletColors.isDark(context);
    final mapboxTileUrl = AppConfig.mapboxTileUrlTemplateForTheme(isDark);

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
        // 1. Local MBTiles fallback basemap layer (rendered when offline or as base)
        if (_tileProvider != null)
          fmap.TileLayer(
            key: const ValueKey('tracklet_offline_mbtiles_tile_layer'),
            tileProvider: _tileProvider,
            maxZoom: MapConfig.maxZoom,
            minZoom: MapConfig.minZoom,
          )
        else if (kIsWeb && _useOsmFallback)
          fmap.TileLayer(
            key: const ValueKey('tracklet_osm_fallback_tile_layer'),
            urlTemplate: AppConfig.mapTileUrlTemplate,
            userAgentPackageName: 'org.nitc.tracklet',
            maxZoom: MapConfig.maxZoom,
            minZoom: MapConfig.minZoom,
          ),

        // 2. Mapbox Primary Online Tile Layer
        if (_isMapboxOnline &&
            AppConfig.isMapboxConfigured &&
            mapboxTileUrl.isNotEmpty)
          fmap.TileLayer(
            key: const ValueKey('tracklet_mapbox_tile_layer'),
            urlTemplate: mapboxTileUrl,
            userAgentPackageName: 'org.nitc.tracklet',
            maxZoom: MapConfig.maxZoom,
            minZoom: MapConfig.minZoom,
            retinaMode: fmap.RetinaMode.isHighDensity(context),
            tileBuilder: (context, tileWidget, tile) {
              if (_consecutiveTileErrors > 0) {
                _consecutiveTileErrors = 0;
              }
              return tileWidget;
            },
            errorTileCallback: (tile, error, stackTrace) {
              _onMapboxTileError(error);
            },
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

    if (_initError != null && _tileProvider == null && !_isMapboxOnline) {
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

    if (_isInitializing || (isFallbackActive && widget.showOfflineBadge)) {
      return Stack(
        children: [
          mapWidget,
          if (_isInitializing)
            const Positioned(
              top: TrackletSpacing.md,
              right: TrackletSpacing.md,
              child: SizedBox(
                key: ValueKey('tracklet_map_initializing'),
                width: 24,
                height: 24,
              ),
            ),
          if (isFallbackActive && widget.showOfflineBadge)
            Positioned(
              bottom: TrackletSpacing.screenMargin,
              left: TrackletSpacing.screenMargin,
              child: Material(
                key: const ValueKey('tracklet_offline_map_badge'),
                color: TrackletColors.adaptiveSurfaceElevated(
                  context,
                ).withValues(alpha: 0.92),
                borderRadius: TrackletRadii.roundedPill,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TrackletSpacing.compactMd,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        TrackletIcons.cloudOff,
                        size: 14,
                        color: TrackletColors.adaptiveTextSecondary(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Offline Campus Map',
                        style: TrackletTypography.caption.copyWith(
                          fontWeight: TrackletTypography.weightSemiBold,
                          color: TrackletColors.adaptiveTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return mapWidget;
  }
}

class _TrackletWebMapboxView extends StatefulWidget {
  const _TrackletWebMapboxView({
    super.key,
    required this.controller,
    required this.initialCenter,
    required this.initialZoom,
    required this.markers,
    required this.polylines,
    required this.labels,
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
  State<_TrackletWebMapboxView> createState() => _TrackletWebMapboxViewState();
}

class _TrackletWebMapboxViewState extends State<_TrackletWebMapboxView>
    implements _WebMapController {
  late final String _viewId;
  late GeoPoint _currentCenter;
  late double _currentZoom;
  bool _isLoaded = false;
  String? _errorMessage;
  bool? _lastIsDark;

  @override
  GeoPoint get center => _currentCenter;

  @override
  double get zoom => _currentZoom;

  @override
  void initState() {
    super.initState();
    _viewId = 'map-${identityHashCode(this)}';
    _currentCenter = widget.initialCenter;
    _currentZoom = widget.initialZoom;
    widget.controller._webMapController = this;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = TrackletColors.isDark(context);
    if (_lastIsDark != null && _lastIsDark != isDark && _isLoaded) {
      final styleUrl = AppConfig.effectiveMapboxStyleUrlForTheme(isDark);
      MapboxWebBridge.setStyle(_viewId, styleUrl);
    }
    _lastIsDark = isDark;
  }

  @override
  void didUpdateWidget(covariant _TrackletWebMapboxView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isLoaded) return;
    _syncMapData();
  }

  void _syncMapData() {
    final buses = <Map<String, dynamic>>[];
    String? selectedBusId;
    Map<String, dynamic>? userLoc;

    for (final marker in widget.markers) {
      if (marker.id == 'user-location-marker') {
        userLoc = {'lat': marker.point.latitude, 'lng': marker.point.longitude};
      } else if (marker.id.startsWith('bus-')) {
        final busId = marker.id.substring(4);
        if (marker.isSelected) selectedBusId = busId;
        final hexColor =
            marker.accentColor != null
                ? '#${(marker.accentColor!.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}'
                : '#6F61EF';
        buses.add({
          'id': busId,
          'name': marker.title ?? 'Bus',
          'lat': marker.point.latitude,
          'lng': marker.point.longitude,
          'routeColor': hexColor,
          'isSelected': marker.isSelected,
          'isStale': marker.subtitle?.toLowerCase().contains('stale') ?? false,
          'isStationary':
              marker.subtitle?.toLowerCase().contains('stationary') ?? false,
        });
      }
    }

    final routes = <Map<String, dynamic>>[];
    for (final poly in widget.polylines) {
      final hexColor =
          '#${(poly.color.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}';
      routes.add({
        'id': poly.id,
        'color': hexColor,
        'points': [
          for (final pt in poly.points)
            {'lat': pt.latitude, 'lng': pt.longitude},
        ],
      });
    }

    final stops = <Map<String, dynamic>>[];
    String? selectedStopId;
    for (final marker in widget.markers) {
      if (!marker.id.startsWith('bus-') &&
          marker.id != 'user-location-marker') {
        if (marker.isSelected) selectedStopId = marker.id;
        final hexColor =
            marker.accentColor != null
                ? '#${(marker.accentColor!.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}'
                : '#6F61EF';
        stops.add({
          'id': marker.id,
          'name': marker.title ?? '',
          'lat': marker.point.latitude,
          'lng': marker.point.longitude,
          'color': hexColor,
          'isMajorHub': marker.isMajorHub,
          'isSelected': marker.isSelected,
        });
      }
    }

    MapboxWebBridge.updateBuses(_viewId, buses, selectedBusId);
    MapboxWebBridge.updateRoutes(_viewId, routes, null);
    MapboxWebBridge.updateStops(_viewId, stops, selectedStopId);
    MapboxWebBridge.updateUserLocation(_viewId, userLoc);
  }

  @override
  void moveTo(GeoPoint point, {double? zoom}) {
    _currentCenter = point;
    if (zoom != null) _currentZoom = zoom;
    MapboxWebBridge.flyTo(
      _viewId,
      point.longitude,
      point.latitude,
      zoom ?? _currentZoom,
    );
  }

  @override
  void animatedMoveTo(GeoPoint point, {double? zoom}) {
    moveTo(point, zoom: zoom);
  }

  @override
  void fitBounds(
    List<GeoPoint> points, {
    EdgeInsets padding = const EdgeInsets.all(TrackletSpacing.mapViewportInset),
  }) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      moveTo(points.first);
      return;
    }
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final pt in points) {
      if (pt.latitude < minLat) minLat = pt.latitude;
      if (pt.latitude > maxLat) maxLat = pt.latitude;
      if (pt.longitude < minLng) minLng = pt.longitude;
      if (pt.longitude > maxLng) maxLng = pt.longitude;
    }
    MapboxWebBridge.fitBounds(
      _viewId,
      [minLng, minLat, maxLng, maxLat],
      {
        'top': padding.top.toInt(),
        'bottom': padding.bottom.toInt(),
        'left': padding.left.toInt(),
        'right': padding.right.toInt(),
      },
    );
  }

  @override
  void animatedFitBounds(
    List<GeoPoint> points, {
    EdgeInsets padding = const EdgeInsets.all(TrackletSpacing.mapViewportInset),
  }) {
    fitBounds(points, padding: padding);
  }

  @override
  void dispose() {
    if (widget.controller._webMapController == this) {
      widget.controller._webMapController = null;
    }
    MapboxWebBridge.destroy(_viewId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(TrackletSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                TrackletIcons.alertTriangle,
                size: 44,
                color: TrackletColors.warning,
              ),
              const SizedBox(height: TrackletSpacing.md),
              Text(
                'Mapbox Initialization Error',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: TrackletTypography.weightBold,
                  color: TrackletColors.adaptiveTextPrimary(context),
                ),
              ),
              const SizedBox(height: TrackletSpacing.xs),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: TrackletColors.adaptiveTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final isDark = TrackletColors.isDark(context);
    final styleUrl = AppConfig.effectiveMapboxStyleUrlForTheme(isDark);

    return MapboxWebBridge.buildMapboxWebView(
      viewId: _viewId,
      accessToken: AppConfig.mapboxPublicToken,
      styleUrl: styleUrl,
      initialCenter: widget.initialCenter,
      initialZoom: widget.initialZoom,
      onMapClick: (point) => widget.onTap?.call(point),
      onBusClick: (busId) {
        final marker =
            widget.markers.where((m) => m.id == 'bus-$busId').firstOrNull;
        marker?.onTap?.call();
      },
      onStopClick: (stopId) {
        final marker = widget.markers.where((m) => m.id == stopId).firstOrNull;
        marker?.onTap?.call();
      },
      onCameraChange: (lat, lng, zoom) {
        _currentCenter = GeoPoint(latitude: lat, longitude: lng);
        _currentZoom = zoom;
        widget.onZoomChanged?.call(zoom);
      },
      onUserGesture: () => widget.onUserGesture?.call(),
      onLoad: () {
        if (!mounted) return;
        setState(() => _isLoaded = true);
        _syncMapData();
      },
      onError: (err) {
        if (!mounted) return;
        setState(() => _errorMessage = err);
      },
    );
  }
}

class _MapboxWebConfigPlaceholder extends StatelessWidget {
  const _MapboxWebConfigPlaceholder({required this.onUseOsmFallback});

  final VoidCallback onUseOsmFallback;

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          margin: const EdgeInsets.all(TrackletSpacing.lg),
          padding: const EdgeInsets.all(TrackletSpacing.xl),
          decoration: BoxDecoration(
            color: TrackletColors.adaptiveSurfaceElevated(context),
            borderRadius: TrackletRadii.roundedXl,
            border: Border.all(
              color: TrackletColors.adaptiveCardBorder(context),
            ),
            boxShadow: [
              BoxShadow(
                color: TrackletColors.adaptiveTextPrimary(
                  context,
                ).withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: TrackletColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  TrackletIcons.radar,
                  color: TrackletColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: TrackletSpacing.md),
              Text(
                'Mapbox Public Token Required',
                style: TrackletTypography.titleMedium.copyWith(
                  fontWeight: TrackletTypography.weightBold,
                  color: TrackletColors.adaptiveTextPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TrackletSpacing.sm),
              Text(
                'Interactive maps on web use Mapbox GL JS with full campus fleet rendering. To connect your public Mapbox token, provide it at build or run time:',
                style: TrackletTypography.bodySmall.copyWith(
                  color: TrackletColors.adaptiveTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TrackletSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TrackletSpacing.md,
                  vertical: TrackletSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.black45
                          : TrackletColors.mapCanvasAlternate,
                  borderRadius: TrackletRadii.roundedSm,
                  border: Border.all(
                    color: TrackletColors.adaptiveBorder(context),
                  ),
                ),
                child: const SelectableText(
                  '--dart-define=MAPBOX_PUBLIC_TOKEN=pk.your_token',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: TrackletTypography.fontSize12_5,
                    fontWeight: TrackletTypography.weightSemiBold,
                  ),
                ),
              ),
              const SizedBox(height: TrackletSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onUseOsmFallback,
                  icon: const Icon(TrackletIcons.compass, size: 18),
                  label: const Text('Explore with OpenStreetMap Raster'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: TrackletSpacing.compactLg,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: TrackletRadii.roundedMd,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
