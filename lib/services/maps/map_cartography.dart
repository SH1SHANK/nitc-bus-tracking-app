import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../../core/geo/geo_point.dart';
import '../../design_system/tokens/colors.dart';

/// Style-independent label data sent through the map adapter.
enum MapLabelKind { building, stop }

class MapLabelFeature {
  const MapLabelFeature({
    required this.id,
    required this.name,
    required this.point,
    required this.kind,
    this.isRouteStop = false,
    this.isSelected = false,
  });

  final String id;
  final String name;
  final GeoPoint point;
  final MapLabelKind kind;
  final bool isRouteStop;
  final bool isSelected;
}

enum MapBaseLayerTreatment {
  preserve,
  hideSymbols,
  hideBuildingExtrusions,
  warmBackground,
  warmLand,
  campusBuildingFootprint,
  subtleRoad,
}

/// Pure cartography configuration shared by the Mapbox adapter and tests.
abstract final class TrackletMapCartography {
  static const String campusBuildingSourceId =
      'tracklet-campus-building-labels';
  static const String stopLabelSourceId = 'tracklet-stop-labels';

  static const String campusBuildingLabelsLayerId =
      'tracklet-campus-building-labels';
  static const String otherStopLabelsLayerId = 'tracklet-other-stop-labels';
  static const String routeStopLabelsLayerId = 'tracklet-route-stop-labels';
  static const String selectedStopLabelLayerId = 'tracklet-selected-stop-label';

  /// Classifies the currently loaded style layer from its runtime metadata.
  /// This deliberately avoids assumptions about version-specific layer IDs.
  static MapBaseLayerTreatment treatmentFor({
    required String type,
    String? sourceLayer,
  }) {
    if (type == 'symbol') return MapBaseLayerTreatment.hideSymbols;
    if (type == 'background') return MapBaseLayerTreatment.warmBackground;

    final normalizedSourceLayer = sourceLayer?.toLowerCase();
    if (type == 'fill' && normalizedSourceLayer == 'building') {
      return MapBaseLayerTreatment.campusBuildingFootprint;
    }
    if (type == 'fill' && normalizedSourceLayer == 'land') {
      return MapBaseLayerTreatment.warmLand;
    }
    if (type == 'fill-extrusion' && normalizedSourceLayer == 'building') {
      return MapBaseLayerTreatment.hideBuildingExtrusions;
    }
    if (type == 'line' &&
        (normalizedSourceLayer == 'road' ||
            normalizedSourceLayer == 'transportation')) {
      return MapBaseLayerTreatment.subtleRoad;
    }
    return MapBaseLayerTreatment.preserve;
  }

  static Map<String, Object> layerOverrides(MapBaseLayerTreatment treatment) {
    return switch (treatment) {
      MapBaseLayerTreatment.warmBackground => {
        'background-color': _hex(TrackletColors.mapCanvas),
      },
      MapBaseLayerTreatment.warmLand => {
        'fill-color': _hex(TrackletColors.mapLand),
      },
      MapBaseLayerTreatment.campusBuildingFootprint => {
        'fill-color': _hex(TrackletColors.mapBuilding),
        'fill-opacity': 0.96,
        'fill-outline-color': _hex(TrackletColors.mapBuildingOutline),
      },
      MapBaseLayerTreatment.subtleRoad => {
        'line-color': _hex(TrackletColors.mapRoad),
        'line-opacity': 0.82,
      },
      MapBaseLayerTreatment.preserve ||
      MapBaseLayerTreatment.hideSymbols ||
      MapBaseLayerTreatment.hideBuildingExtrusions => const {},
    };
  }

  static String toGeoJson(Iterable<MapLabelFeature> labels) {
    final features = <Map<String, Object?>>[];
    for (final label in labels) {
      if (!isValidPoint(label.point)) continue;
      final name = label.name.trim();
      if (name.isEmpty) continue;
      features.add({
        'type': 'Feature',
        'id': label.id,
        'geometry': {
          'type': 'Point',
          // GeoJSON is longitude-first (x, y), unlike GeoPoint's named fields.
          'coordinates': [label.point.longitude, label.point.latitude],
        },
        'properties': {
          'name': name,
          'kind': label.kind.name,
          'routeStop': label.isRouteStop,
          'selected': label.isSelected,
        },
      });
    }
    return jsonEncode({'type': 'FeatureCollection', 'features': features});
  }

  static bool isValidPoint(GeoPoint point) =>
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude >= -90 &&
      point.latitude <= 90 &&
      point.longitude >= -180 &&
      point.longitude <= 180;

  /// Stop layers follow building labels and are split by interaction priority.
  /// Selected labels allow overlap; ordinary labels yield through Mapbox's
  /// symbol collision placement instead of truncating database names.
  static List<Map<String, Object?>> labelLayerDefinitions() => [
    _symbolLayer(
      id: campusBuildingLabelsLayerId,
      source: campusBuildingSourceId,
      minZoom: 15.5,
      filter: const [
        '==',
        ['get', 'kind'],
        'building',
      ],
      textColor: _hex(TrackletColors.mapBuildingLabel),
      textSize: const [
        'interpolate',
        ['linear'],
        ['zoom'],
        15.5,
        10,
        18,
        12,
      ],
    ),
    _symbolLayer(
      id: otherStopLabelsLayerId,
      source: stopLabelSourceId,
      minZoom: 15,
      filter: const [
        'all',
        [
          '==',
          ['get', 'kind'],
          'stop',
        ],
        [
          '==',
          ['get', 'selected'],
          false,
        ],
        [
          '==',
          ['get', 'routeStop'],
          false,
        ],
      ],
      textColor: _hex(TrackletColors.mapStopLabel),
      textSize: const [
        'interpolate',
        ['linear'],
        ['zoom'],
        15,
        10,
        18,
        12,
      ],
    ),
    _symbolLayer(
      id: routeStopLabelsLayerId,
      source: stopLabelSourceId,
      minZoom: 14.5,
      filter: const [
        'all',
        [
          '==',
          ['get', 'kind'],
          'stop',
        ],
        [
          '==',
          ['get', 'selected'],
          false,
        ],
        [
          '==',
          ['get', 'routeStop'],
          true,
        ],
      ],
      textColor: _hex(TrackletColors.mapRouteStopLabel),
      textSize: const [
        'interpolate',
        ['linear'],
        ['zoom'],
        14.5,
        10,
        18,
        12,
      ],
    ),
    _symbolLayer(
      id: selectedStopLabelLayerId,
      source: stopLabelSourceId,
      minZoom: 14,
      filter: const [
        'all',
        [
          '==',
          ['get', 'kind'],
          'stop',
        ],
        [
          '==',
          ['get', 'selected'],
          true,
        ],
      ],
      textColor: _hex(TrackletColors.mapSelectedStopLabel),
      textSize: const [
        'interpolate',
        ['linear'],
        ['zoom'],
        14,
        11,
        18,
        13,
      ],
      allowOverlap: true,
      ignorePlacement: true,
    ),
  ];

  static String _hex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static Map<String, Object?> _symbolLayer({
    required String id,
    required String source,
    required double minZoom,
    required List<Object> filter,
    required String textColor,
    required List<Object> textSize,
    bool allowOverlap = false,
    bool ignorePlacement = false,
  }) => {
    'id': id,
    'type': 'symbol',
    'source': source,
    'minzoom': minZoom,
    'filter': filter,
    'layout': {
      'text-field': ['get', 'name'],
      'text-font': ['DIN Pro Medium', 'Arial Unicode MS Regular'],
      'text-size': textSize,
      'text-max-width': 8,
      'text-padding': 3,
      'text-allow-overlap': allowOverlap,
      'text-ignore-placement': ignorePlacement,
      'text-variable-anchor': ['top', 'bottom', 'left', 'right'],
      'text-radial-offset': 0.7,
      'symbol-sort-key': [
        'case',
        [
          '==',
          ['get', 'selected'],
          true,
        ],
        0,
        [
          '==',
          ['get', 'routeStop'],
          true,
        ],
        1,
        2,
      ],
    },
    'paint': {
      'text-color': textColor,
      'text-halo-color': _hex(TrackletColors.mapCanvas),
      'text-halo-width': 1.5,
      'text-halo-blur': 0.2,
    },
  };
}
