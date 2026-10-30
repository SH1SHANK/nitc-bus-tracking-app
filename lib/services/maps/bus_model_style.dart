import 'dart:math' as math;

import '../../core/geo/geo_point.dart';

/// Mapbox model properties for the shared live-bus GLB.
abstract final class BusModelStyle {
  static const bodyMaterialName = 'material_4';
  static const assetPath = 'assets/models/bus_low_poly.glb';

  /// The supplied GLB is authored in centimetres; 0.06 keeps the map marker
  /// legible at campus zoom while preserving its proportions.
  static const mapScale = 0.06;

  /// Zoom-aware scale expression for Mapbox ModelLayer.
  /// Smoothly scales the bus model between zoom 15 and zoom 20 to maintain
  /// natural relative proportion against campus roads and buildings.
  static const modelScaleExpression = [
    'interpolate',
    ['linear'],
    ['zoom'],
    15.0,
    [0.045, 0.045, 0.045],
    16.5,
    [0.06, 0.06, 0.06],
    18.5,
    [0.08, 0.08, 0.08],
    20.0,
    [0.10, 0.10, 0.10],
  ];

  static const bodyColorExpression = [
    'match',
    ['get', 'part'],
    bodyMaterialName,
    [
      'coalesce',
      ['feature-state', 'bodyColor'],
      '#ffffff',
    ],
    '#ffffff',
  ];

  static const bodyColorMixIntensityExpression = [
    'match',
    ['get', 'part'],
    bodyMaterialName,
    [
      'case',
      [
        'boolean',
        ['feature-state', 'bodyColorEnabled'],
        false,
      ],
      1.0,
      0.0,
    ],
    0.0,
  ];

  /// Mapbox model rotation uses degrees clockwise from north for z rotation.
  static List<double> rotation(double? headingDegrees) => [
    0,
    0,
    headingDegrees == null ? 0 : (headingDegrees % 360 + 360) % 360,
  ];

  /// Returns east/north offsets in metres from a model's stable source anchor.
  static List<double> translation(GeoPoint anchor, GeoPoint point) {
    const earthCircumferenceMeters = 40075016.686;
    final latitudeRadians = point.latitude * math.pi / 180;
    final east =
        (point.longitude - anchor.longitude) *
        earthCircumferenceMeters *
        math.cos(latitudeRadians) /
        360;
    final north =
        (point.latitude - anchor.latitude) * earthCircumferenceMeters / 360;
    return [east, north, 0];
  }
}
