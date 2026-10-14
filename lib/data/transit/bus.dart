import 'bus_position.dart';

enum BusStatus {
  live,
  delayed,
  due,
  offline;

  static BusStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'live' || 'active' || 'moving' => BusStatus.live,
      'delayed' => BusStatus.delayed,
      'due' || 'stationary' => BusStatus.due,
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
    this.tripId,
    required this.status,
    required this.position,
    this.occupancy = 'seats_available',
    required this.lastUpdated,
    this.isStale = false,
  });

  final String id;
  final String numberPlate;
  final String name;
  final String? routeId;
  final String? tripId;
  final BusStatus status;
  final BusPosition position;
  final String occupancy;
  final DateTime lastUpdated;
  final bool isStale;

  bool get isLive => status == BusStatus.live;

  Bus copyWith({
    String? id,
    String? numberPlate,
    String? name,
    String? routeId,
    String? tripId,
    BusStatus? status,
    BusPosition? position,
    String? occupancy,
    DateTime? lastUpdated,
    bool? isStale,
  }) {
    return Bus(
      id: id ?? this.id,
      numberPlate: numberPlate ?? this.numberPlate,
      name: name ?? this.name,
      routeId: routeId ?? this.routeId,
      tripId: tripId ?? this.tripId,
      status: status ?? this.status,
      position: position ?? this.position,
      occupancy: occupancy ?? this.occupancy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isStale: isStale ?? this.isStale,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    ...position.toJson(),
    'number_plate': numberPlate,
    'name': name,
    'route_id': routeId,
    'trip_id': tripId,
    'status': status.name,
    'occupancy': occupancy,
    'last_updated': lastUpdated.toIso8601String(),
    'is_stale': isStale,
  };

  factory Bus.fromJson(
    Map<String, dynamic> json, {
    DateTime Function()? clock,
  }) {
    final fallbackTime = (clock ?? DateTime.now)();
    return Bus(
      id: (json['id'] ?? json['bus_id']) as String,
      numberPlate:
          (json['number_plate'] ?? json['bus_number']) as String? ?? '',
      name: (json['name'] ?? json['display_name']) as String? ?? 'Campus Bus',
      routeId: json['route_id'] as String?,
      tripId: (json['active_trip_id'] ?? json['trip_id']) as String?,
      status: BusStatus.fromString(json['status'] as String?),
      position: BusPosition.fromJson(json, clock: () => fallbackTime),
      occupancy: json['occupancy'] as String? ?? 'seats_available',
      isStale: (json['is_stale'] as bool?) ?? false,
      lastUpdated: DateTime.parse(
        (json['last_updated'] ??
                json['last_seen'] ??
                json['recorded_at'] ??
                json['timestamp'] ??
                fallbackTime.toIso8601String())
            as String,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bus &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          numberPlate == other.numberPlate &&
          tripId == other.tripId &&
          status == other.status &&
          isStale == other.isStale &&
          position == other.position;

  @override
  int get hashCode =>
      Object.hash(id, numberPlate, tripId, status, isStale, position);

  @override
  String toString() =>
      'Bus(id: $id, name: $name, status: ${status.name}, isStale: $isStale, pos: $position)';
}
