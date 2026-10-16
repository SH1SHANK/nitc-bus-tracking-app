import 'package:flutter/material.dart';

import '../../core/geo/geo_point.dart';
import 'route_geometry.dart';
import 'route_stop_occurrence.dart';
import 'stop.dart';

/// Immutable representation of a transit route connecting campus bus stops.
class BusRoute {
  const BusRoute({
    required this.id,
    required this.name,
    required this.code,
    this.colorHex = '#64748B',
    this.description,
    this.direction = 'forward',
    this.geometry = const RouteGeometry.missing(),
    this.path = const [],
    this.stopIds = const [],
    this.stopOccurrences = const [],
    this.pathSource = 'manual',
    this.pathVerified = false,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String code;
  final String colorHex;
  final String? description;
  final String direction;
  final RouteGeometry geometry;
  final List<GeoPoint> path;
  final List<String> stopIds;
  final List<RouteStopOccurrence> stopOccurrences;
  final String pathSource;
  final bool pathVerified;
  final bool isActive;

  bool get isGeometryAvailable => geometry.isAvailable;
  bool get isGeometryMissing => geometry.isMissing;
  bool get isGeometryInvalid => geometry.isInvalid;

  Color get color {
    final cleanHex = colorHex.replaceAll('#', '');
    final value = int.tryParse(cleanHex, radix: 16);
    if (value == null) return const Color(0xFF64748B);
    if (cleanHex.length == 6) return Color(0xFF000000 | value);
    if (cleanHex.length == 8) return Color(value);
    return const Color(0xFF64748B);
  }

  BusRoute copyWith({
    String? id,
    String? name,
    String? code,
    String? colorHex,
    String? description,
    String? direction,
    RouteGeometry? geometry,
    List<GeoPoint>? path,
    List<String>? stopIds,
    List<RouteStopOccurrence>? stopOccurrences,
    String? pathSource,
    bool? pathVerified,
    bool? isActive,
  }) {
    final newGeometry = geometry ?? this.geometry;
    return BusRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      colorHex: colorHex ?? this.colorHex,
      description: description ?? this.description,
      direction: direction ?? this.direction,
      geometry: newGeometry,
      path: path ?? (newGeometry.isAvailable ? newGeometry.path : this.path),
      stopIds: stopIds ?? this.stopIds,
      stopOccurrences: stopOccurrences ?? this.stopOccurrences,
      pathSource: pathSource ?? this.pathSource,
      pathVerified: pathVerified ?? this.pathVerified,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'route_code': code,
    'color_hex': colorHex,
    'description': description,
    'direction': direction,
    'path_source': pathSource,
    'path_verified': pathVerified,
    'geometry': geometry.toJson(),
    'path': path.map((p) => p.toJson()).toList(),
    'stop_ids': stopIds,
    'stop_occurrences': stopOccurrences.map((o) => o.toJson()).toList(),
    'is_active': isActive,
  };

  factory BusRoute.fromJson(
    Map<String, dynamic> json, {
    List<Stop> stops = const [],
    List<RouteStopOccurrence> stopOccurrences = const [],
  }) {
    final rawPath = json['path'] ?? json['geometry'];
    final pathSource = json['path_source'] as String? ?? 'manual';
    final pathVerified = json['path_verified'] as bool? ?? false;
    final direction = json['direction'] as String? ?? 'forward';

    final parsedGeometry = RouteGeometry.fromBackend(
      rawPath,
      source: pathSource,
      isVerified: pathVerified,
    );

    final rawStops = json['stop_ids'] as List<dynamic>? ?? [];
    final summary = json['stops_summary'] as String?;
    final normalizedOccurrences = RouteStopOccurrence.normalizeOutAndBack(
      stopOccurrences,
    );
    final parsedStops =
        normalizedOccurrences.isNotEmpty
            ? normalizedOccurrences.map((o) => o.stopId).toList()
            : rawStops.isNotEmpty
            ? rawStops.map((stopId) => stopId.toString()).toList()
            : summary == null
            ? <String>[]
            : _stopIdsFromSummary(summary, stops);
    final name =
        (json['name'] ?? json['route_name'] ?? 'Campus route') as String;
    final code =
        (json['route_code'] ?? json['code']) as String? ??
        _routeCodeFromName(name);

    final rawColor = (json['route_color'] ?? json['color_hex']) as String?;
    final colorHex =
        (rawColor != null && rawColor.trim().isNotEmpty)
            ? rawColor.trim()
            : '#64748B';

    return BusRoute(
      id: (json['id'] ?? json['bus_id']) as String,
      name: name,
      code: code,
      colorHex: colorHex,
      description: json['description'] as String? ?? summary,
      direction: direction,
      geometry: parsedGeometry,
      path: parsedGeometry.isAvailable ? parsedGeometry.path : const [],
      stopIds: parsedStops,
      stopOccurrences: normalizedOccurrences,
      pathSource: pathSource,
      pathVerified: pathVerified,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static String _routeCodeFromName(String name) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(name);
    return match?.group(1) ?? 'ROUTE';
  }

  static List<String> _stopIdsFromSummary(String summary, List<Stop> stops) {
    final stopIds = <String>[];
    for (final rawName in summary.split('→')) {
      final name = _normalizeStopName(rawName);
      final alias = switch (name) {
        'lh' => 'ladieshostel',
        'mbh' || 'megaboyshostel' => 'megahostelboys',
        'centrecircle' => 'centercircle',
        _ => name,
      };
      final matchedStop =
          stops.where((stop) {
            return _normalizeStopName(stop.name) == alias ||
                _normalizeStopName(stop.sourceStopId ?? '') == alias;
          }).firstOrNull;
      if (matchedStop != null) stopIds.add(matchedStop.id);
    }
    return stopIds;
  }

  static String _normalizeStopName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusRoute &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code;

  @override
  int get hashCode => Object.hash(id, code);

  @override
  String toString() =>
      'BusRoute(id: $id, code: $code, name: $name, geometry: ${geometry.status.name})';
}
