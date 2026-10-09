import '../../core/geo/geo_point.dart';

/// Immutable representation of a transit bus stop on campus.
class Stop {
  const Stop({
    required this.id,
    required this.name,
    this.code = '',
    required this.location,
    this.walkingTimeMinutes = 5,
    this.isMajorHub = false,
    this.orderIndex = 0,
    this.sourceStopId,
    this.nearestNodeId,
    this.description,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String code;
  final GeoPoint location;
  final int walkingTimeMinutes;
  final bool isMajorHub;
  final int orderIndex;
  final String? sourceStopId;
  final String? nearestNodeId;
  final String? description;
  final bool isActive;

  Stop copyWith({
    String? sourceStopId,
    String? nearestNodeId,
    String? description,
    bool? isActive,
    String? id,
    String? name,
    String? code,
    GeoPoint? location,
    int? walkingTimeMinutes,
    bool? isMajorHub,
    int? orderIndex,
  }) {
    return Stop(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      location: location ?? this.location,
      walkingTimeMinutes: walkingTimeMinutes ?? this.walkingTimeMinutes,
      isMajorHub: isMajorHub ?? this.isMajorHub,
      orderIndex: orderIndex ?? this.orderIndex,
      sourceStopId: sourceStopId ?? this.sourceStopId,
      nearestNodeId: nearestNodeId ?? this.nearestNodeId,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'latitude': location.latitude,
    'longitude': location.longitude,
    'walking_time_minutes': walkingTimeMinutes,
    'is_major_hub': isMajorHub,
    'order_index': orderIndex,
    'stop_id': sourceStopId,
    'nearest_node_id': nearestNodeId,
    'description': description,
    'is_active': isActive,
  };

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: (json['id'] ?? json['stop_id']) as String,
      name: json['name'] as String,
      code: json['code'] as String? ?? '',
      location: GeoPoint(
        latitude: ((json['latitude'] ?? json['lat']) as num).toDouble(),
        longitude:
            ((json['longitude'] ?? json['lng'] ?? json['lon']) as num)
                .toDouble(),
      ),
      walkingTimeMinutes: (json['walking_time_minutes'] as num?)?.toInt() ?? 5,
      isMajorHub: (json['is_major_hub'] as bool?) ?? false,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      sourceStopId: json['stop_id'] as String?,
      nearestNodeId: json['nearest_node_id']?.toString(),
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stop &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          location == other.location;

  @override
  int get hashCode => Object.hash(id, code, location);

  @override
  String toString() => 'Stop(id: $id, name: $name, code: $code)';
}
