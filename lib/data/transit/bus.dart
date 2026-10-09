import 'bus_position.dart';

enum BusStatus {
  live,
  delayed,
  due,
  offline;

  static BusStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'live' => BusStatus.live,
      'delayed' => BusStatus.delayed,
      'due' => BusStatus.due,
      _ => BusStatus.offline,
    };
  }

  String get displayName => switch (this) {
    BusStatus.live => 'Live',
    BusStatus.delayed => 'Delayed',
    BusStatus.due => 'Due',
    BusStatus.offline => 'Offline',
  };
}

/// Immutable representation of a campus transit bus.
class Bus {
  const Bus({
    required this.id,
    required this.numberPlate,
    required this.name,
    this.routeId,
    required this.status,
    required this.position,
    this.occupancy = 'seats_available',
    required this.lastUpdated,
  });

  final String id;
  final String numberPlate;
  final String name;
  final String? routeId;
  final BusStatus status;
  final BusPosition position;
  final String occupancy;
  final DateTime lastUpdated;

  bool get isLive => status == BusStatus.live;

  Bus copyWith({
    String? id,
    String? numberPlate,
    String? name,
    String? routeId,
    BusStatus? status,
    BusPosition? position,
    String? occupancy,
    DateTime? lastUpdated,
  }) {
    return Bus(
      id: id ?? this.id,
      numberPlate: numberPlate ?? this.numberPlate,
      name: name ?? this.name,
      routeId: routeId ?? this.routeId,
      status: status ?? this.status,
      position: position ?? this.position,
      occupancy: occupancy ?? this.occupancy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    ...position.toJson(),
    'number_plate': numberPlate,
    'name': name,
    'route_id': routeId,
    'status': status.name,
    'occupancy': occupancy,
    'last_updated': lastUpdated.toIso8601String(),
  };

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] as String,
      numberPlate: json['number_plate'] as String? ?? 'KL-11-NITC',
      name: json['name'] as String? ?? 'Campus Bus',
      routeId: json['route_id'] as String?,
      status: BusStatus.fromString(json['status'] as String?),
      position: BusPosition.fromJson(json),
      occupancy: json['occupancy'] as String? ?? 'seats_available',
      lastUpdated:
          json['last_updated'] != null
              ? DateTime.parse(json['last_updated'] as String)
              : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bus &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          numberPlate == other.numberPlate &&
          status == other.status &&
          position == other.position;

  @override
  int get hashCode => Object.hash(id, numberPlate, status, position);

  @override
  String toString() =>
      'Bus(id: $id, name: $name, status: ${status.name}, pos: $position)';
}
