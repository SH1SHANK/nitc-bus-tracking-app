import '../../core/geo/geo_point.dart';

/// Immutable representation of a transit bus stop on campus.
class Stop {
  const Stop({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    this.walkingTimeMinutes = 5,
    this.isMajorHub = false,
    this.orderIndex = 0,
  });

  final String id;
  final String name;
  final String code;
  final GeoPoint location;
  final int walkingTimeMinutes;
  final bool isMajorHub;
  final int orderIndex;

  Stop copyWith({
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
  };

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String? ?? 'STP',
      location: GeoPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      walkingTimeMinutes: (json['walking_time_minutes'] as num?)?.toInt() ?? 5,
      isMajorHub: (json['is_major_hub'] as bool?) ?? false,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
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
