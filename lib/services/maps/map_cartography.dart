import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../../core/geo/geo_point.dart';
import '../../data/transit/bus_telemetry.dart';
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
    this.isPriorityLandmark = false,
  });

  final String id;
  final String name;
  final GeoPoint point;
  final MapLabelKind kind;
  final bool isRouteStop;
  final bool isSelected;
  final bool isPriorityLandmark;
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

/// Pure cartography configuration shared by map components and tests.
abstract final class TrackletMapCartography {
  static const String campusBuildingSourceId =
      'tracklet-campus-building-labels';
  static const String stopLabelSourceId = 'tracklet-stop-labels';

  static const String campusBuildingLabelsLayerId =
      priorityBuildingLabelsLayerId;
  static const String otherStopLabelsLayerId = 'tracklet-other-stop-labels';
  static const String routeStopLabelsLayerId = 'tracklet-route-stop-labels';
  static const String selectedStopLabelLayerId = 'tracklet-selected-stop-label';
  static const String selectedBuildingHaloLayerId =
      'tracklet-selected-building-halo';
  static const String selectedBuildingLabelLayerId =
      'tracklet-selected-building-label';
  static const String priorityBuildingLabelsLayerId =
      'tracklet-priority-building-labels';
  static const String secondaryBuildingLabelsLayerId =
      'tracklet-secondary-building-labels';

  static const _priorityLandmarkNames = {
    'main building',
    'main gate',
    'central library',
    'administrative block',
    'guest house',
    'auditorium',
    'gymkhana',
    'mega hostel',
    'rajpath',
    'nlhc',
    'elhc',
    'bhaskara',
  };

  static bool isPriorityLandmark(String name) {
    final normalized = name.toLowerCase();
    return _priorityLandmarkNames.any(normalized.contains);
  }

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

  static Map<String, Object> layerOverrides(
    MapBaseLayerTreatment treatment, {
    bool isDark = false,
  }) {
    return switch (treatment) {
      MapBaseLayerTreatment.warmBackground => {
        'background-color': _hex(
          isDark ? TrackletColors.mapCanvasDark : TrackletColors.mapCanvas,
        ),
      },
      MapBaseLayerTreatment.warmLand => {
        'fill-color': _hex(
          isDark ? TrackletColors.mapLandDark : TrackletColors.mapLand,
        ),
      },
      MapBaseLayerTreatment.campusBuildingFootprint => {
        'fill-color': _hex(
          isDark ? TrackletColors.mapBuildingDark : TrackletColors.mapBuilding,
        ),
        'fill-opacity': isDark ? 0.28 : 0.42,
        'fill-outline-color': _hex(
          isDark
              ? TrackletColors.mapBuildingOutlineDark
              : TrackletColors.mapBuildingOutline,
        ),
      },
      MapBaseLayerTreatment.subtleRoad => {
        'line-color': _hex(
          isDark ? TrackletColors.mapRoadDark : TrackletColors.mapRoad,
        ),
        'line-opacity': 0.82,
      },
      MapBaseLayerTreatment.hideSymbols => {'visibility': 'none'},
      MapBaseLayerTreatment.hideBuildingExtrusions => {'visibility': 'none'},
      MapBaseLayerTreatment.preserve => const {},
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
          'priority': label.isPriorityLandmark,
        },
      });
    }
    return jsonEncode({'type': 'FeatureCollection', 'features': features});
  }

  static bool isValidPoint(GeoPoint point) => BusTelemetry.isValidPoint(point);

  /// Stop layers follow building labels and are split by interaction priority.
  /// Selected labels allow overlap; ordinary labels yield through standard
  /// symbol collision placement instead of truncating database names.
  static List<Map<String, Object?>> labelLayerDefinitions({
    bool isDark = false,
  }) => [
    {
      'id': selectedBuildingHaloLayerId,
      'type': 'circle',
      'source': campusBuildingSourceId,
      'minzoom': 14,
      'filter': [
        'all',
        [
          '==',
          ['get', 'kind'],
          'building',
        ],
        [
          '==',
          ['get', 'selected'],
          true,
        ],
      ],
      'paint': {
        'circle-radius': [
          'interpolate',
          ['linear'],
          ['zoom'],
          14,
          8,
          18,
          11,
        ],
        'circle-color': _hex(
          isDark ? TrackletColors.primaryDark : TrackletColors.primary,
        ),
        'circle-opacity': 0.22,
        'circle-stroke-color': _hex(
          isDark ? TrackletColors.primaryDark : TrackletColors.primary,
        ),
        'circle-stroke-width': 2,
      },
    },
    _symbolLayer(
      id: selectedBuildingLabelLayerId,
      source: campusBuildingSourceId,
      minZoom: 14,
      filter: const [
        'all',
        [
          '==',
          ['get', 'kind'],
          'building',
        ],
        [
          '==',
          ['get', 'selected'],
          true,
        ],
      ],
      textColor: _hex(
        isDark ? TrackletColors.primaryDark : TrackletColors.primary,
      ),
      textSize: const [
        'interpolate',
        ['linear'],
        ['zoom'],
        14,
        11,
        18,
        13,
      ],
      isDark: isDark,
    ),
    _symbolLayer(
      id: priorityBuildingLabelsLayerId,
      source: campusBuildingSourceId,
      minZoom: 16.25,
      filter: const [
        'all',
        [
          '==',
          ['get', 'kind'],
          'building',
        ],
        [
          '==',
          ['get', 'selected'],
          false,
        ],
        [
          '==',
          ['get', 'priority'],
          true,
        ],
      ],
      textColor: _hex(
        isDark
            ? TrackletColors.mapBuildingLabelDark
            : TrackletColors.mapBuildingLabel,
      ),
      textSize: const [
        'interpolate',
        ['linear'],
        ['zoom'],
        16.25,
        10,
        18,
        12,
      ],
      isDark: isDark,
    ),
    _symbolLayer(
      id: secondaryBuildingLabelsLayerId,
      source: campusBuildingSourceId,
      minZoom: 18.25,
      filter: const [
        'all',
        [
          '==',
          ['get', 'kind'],
          'building',
        ],
        [
          '==',
          ['get', 'selected'],
          false,
        ],
        [
          '==',
          ['get', 'priority'],
          false,
        ],
      ],
      textColor: _hex(
        isDark
            ? TrackletColors.mapBuildingLabelDark
            : TrackletColors.mapBuildingLabel,
      ),
      textSize: const [
        'interpolate',
        ['linear'],
        ['zoom'],
        18.25,
        10,
        20,
        12,
      ],
      isDark: isDark,
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
      textColor: _hex(
        isDark ? TrackletColors.mapStopLabelDark : TrackletColors.mapStopLabel,
      ),
      textSize: const [
        'interpolate',
        ['linear'],
        ['zoom'],
        15,
        10,
        18,
        12,
      ],
      isDark: isDark,
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
      textColor: _hex(
        isDark ? TrackletColors.primaryDark : TrackletColors.mapRouteStopLabel,
      ),
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
      textColor: _hex(
        isDark
            ? TrackletColors.primaryDark
            : TrackletColors.mapSelectedStopLabel,
      ),
      isDark: isDark,
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
    bool isDark = false,
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
      'text-max-width': 10,
      'text-padding': 4,
      'text-allow-overlap': allowOverlap,
      'text-ignore-placement': ignorePlacement,
      'text-variable-anchor': ['top', 'bottom', 'left', 'right'],
      'text-radial-offset': 0.75,
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
          ['get', 'priority'],
          true,
        ],
        1,
        [
          '==',
          ['get', 'routeStop'],
          true,
        ],
        2,
        3,
      ],
    },
    'paint': {
      'text-color': textColor,
      'text-halo-color': _hex(
        isDark ? TrackletColors.mapCanvasDark : TrackletColors.mapCanvas,
      ),
      'text-halo-width': 2.0,
      'text-halo-blur': 0.3,
    },
  };
}
