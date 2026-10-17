import 'dart:convert';

import '../../core/geo/geo_point.dart';

/// Explicit status classification for road-following route geometries.
enum RouteGeometryStatus {
  /// Road-following geometry is validated and ready for rendering.
  available,

  /// Geometry is NULL or absent in the backend.
  missing,

  /// Geometry exists but cannot be parsed or fails coordinate validation.
  invalid,
}

/// Typed geometry abstraction encapsulating path points, source, and verification state.
class RouteGeometry {
  const RouteGeometry({
    required this.status,
    this.path = const [],
    this.source = 'manual',
    this.isVerified = false,
    this.errorMessage,
  });

  const RouteGeometry.missing({this.source = 'manual', this.isVerified = false})
    : status = RouteGeometryStatus.missing,
      path = const [],
      errorMessage = null;

  const RouteGeometry.available({
    required this.path,
    this.source = 'manual',
    this.isVerified = false,
  }) : status = RouteGeometryStatus.available,
       errorMessage = null;

  const RouteGeometry.invalid({
    required this.errorMessage,
    this.source = 'manual',
    this.isVerified = false,
  }) : status = RouteGeometryStatus.invalid,
       path = const [];

  final RouteGeometryStatus status;
  final List<GeoPoint> path;
  final String source;
  final bool isVerified;
  final String? errorMessage;

  bool get isAvailable =>
      status == RouteGeometryStatus.available && path.length >= 2;
  bool get isMissing => status == RouteGeometryStatus.missing;
  bool get isInvalid => status == RouteGeometryStatus.invalid;

  /// Defensive parser for PostGIS / GeoJSON / List path representations.
  factory RouteGeometry.fromBackend(
    dynamic rawPath, {
    String source = 'manual',
    bool isVerified = false,
  }) {
    if (rawPath == null) {
      return RouteGeometry.missing(source: source, isVerified: isVerified);
    }

    if (rawPath is String) {
      final trimmed = rawPath.trim();
      if (trimmed.isEmpty || trimmed == 'null') {
        return RouteGeometry.missing(source: source, isVerified: isVerified);
      }
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          final decoded = jsonDecode(trimmed);
          return RouteGeometry.fromBackend(
            decoded,
            source: source,
            isVerified: isVerified,
          );
        } catch (e) {
          return RouteGeometry.invalid(
            errorMessage: 'Malformed JSON geometry string: $e',
            source: source,
            isVerified: isVerified,
          );
        }
      }
    }

    // GeoJSON LineString format: {"type": "LineString", "coordinates": [[lon, lat], ...]}
    if (rawPath is Map<String, dynamic>) {
      final type = rawPath['type'] as String?;
      final coordinates = rawPath['coordinates'];
      if (type != 'LineString' || coordinates is! List) {
        return RouteGeometry.invalid(
          errorMessage: 'Unsupported GeoJSON geometry type: $type',
          source: source,
          isVerified: isVerified,
        );
      }

      final parsedPoints = <GeoPoint>[];
      for (final coord in coordinates) {
        if (coord is List && coord.length >= 2) {
          final lon = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          if (_isValidCoordinate(lat, lon)) {
            parsedPoints.add(GeoPoint(latitude: lat, longitude: lon));
          } else {
            return RouteGeometry.invalid(
              errorMessage: 'Coordinates out of bounds: [$lon, $lat]',
              source: source,
              isVerified: isVerified,
            );
          }
        }
      }

      if (parsedPoints.length < 2) {
        return RouteGeometry.invalid(
          errorMessage: 'GeoJSON LineString must have at least 2 points',
          source: source,
          isVerified: isVerified,
        );
      }

      return RouteGeometry.available(
        path: parsedPoints,
        source: source,
        isVerified: isVerified,
      );
    }

    // List of objects or coordinate pairs format
    if (rawPath is List) {
      if (rawPath.isEmpty) {
        return RouteGeometry.missing(source: source, isVerified: isVerified);
      }

      final parsedPoints = <GeoPoint>[];
      for (final item in rawPath) {
        if (item is Map<String, dynamic>) {
          final pt = GeoPoint.tryParse(item);
          if (pt != null) {
            parsedPoints.add(pt);
          }
        } else if (item is List && item.length >= 2) {
          // Standard GeoJSON / PostGIS coordinates ordering: [longitude, latitude]
          final lon = (item[0] as num).toDouble();
          final lat = (item[1] as num).toDouble();
          if (_isValidCoordinate(lat, lon)) {
            parsedPoints.add(GeoPoint(latitude: lat, longitude: lon));
          } else {
            return RouteGeometry.invalid(
              errorMessage: 'Coordinates out of bounds: [$lon, $lat]',
              source: source,
              isVerified: isVerified,
            );
          }
        }
      }

      final validPoints =
          parsedPoints
              .where((p) => _isValidCoordinate(p.latitude, p.longitude))
              .toList();

      if (validPoints.length < 2) {
        return RouteGeometry.missing(source: source, isVerified: isVerified);
      }

      return RouteGeometry.available(
        path: validPoints,
        source: source,
        isVerified: isVerified,
      );
    }

    return RouteGeometry.invalid(
      errorMessage: 'Unrecognized geometry payload: $rawPath',
      source: source,
      isVerified: isVerified,
    );
  }

  static bool _isValidCoordinate(double lat, double lon) =>
      GeoPoint.isValidCoordinates(lat, lon);

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'source': source,
    'is_verified': isVerified,
    'error_message': errorMessage,
    'path': path.map((p) => p.toJson()).toList(),
  };
}
