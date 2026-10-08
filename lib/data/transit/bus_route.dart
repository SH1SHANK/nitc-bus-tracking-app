import '../../core/geo/geo_point.dart';

/// Immutable representation of a transit route connecting campus bus stops.
class BusRoute {
  const BusRoute({
    required this.id,
    required this.name,
    required this.code,
    this.colorHex = '#0B6BCB',
    this.description,
    this.path = const [],
    this.stopIds = const [],
    this.isActive = true,
  });

  final String id;
  final String name;
  final String code;
  final String colorHex;
  final String? description;
  final List<GeoPoint> path;
  final List<String> stopIds;
  final bool isActive;

  BusRoute copyWith({
    String? id,
    String? name,
    String? code,
    String? colorHex,
    String? description,
    List<GeoPoint>? path,
    List<String>? stopIds,
    bool? isActive,
  }) {
    return BusRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      colorHex: colorHex ?? this.colorHex,
      description: description ?? this.description,
      path: path ?? this.path,
      stopIds: stopIds ?? this.stopIds,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'color_hex': colorHex,
    'description': description,
    'path': path.map((p) => p.toJson()).toList(),
    'stop_ids': stopIds,
    'is_active': isActive,
  };

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    final rawPath = json['path'] as List<dynamic>? ?? [];
    final parsedPath = rawPath
        .map((item) {
          if (item is Map<String, dynamic>) {
            return GeoPoint.fromJson(item);
          } else if (item is List && item.length >= 2) {
            return GeoPoint(
              latitude: (item[0] as num).toDouble(),
              longitude: (item[1] as num).toDouble(),
            );
          }
          return const GeoPoint(latitude: 0, longitude: 0);
        })
        .where((p) => p.latitude != 0 || p.longitude != 0)
        .toList();

    final rawStops = json['stop_ids'] as List<dynamic>? ?? [];
    final parsedStops = rawStops.map((s) => s.toString()).toList();

    return BusRoute(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String? ?? 'RTE',
      colorHex: json['color_hex'] as String? ?? '#0B6BCB',
      description: json['description'] as String?,
      path: parsedPath,
      stopIds: parsedStops,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

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
  String toString() => 'BusRoute(id: $id, name: $name, code: $code)';
}
