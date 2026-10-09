import '../../core/geo/geo_point.dart';

/// Immutable representation of a bus's geographic telemetry.
class BusPosition {
  const BusPosition({
    required this.point,
    this.heading = 0.0,
    this.speedKmH = 0.0,
    this.accuracyMeters = 0.0,
    this.sequenceNumber = 0,
    required this.timestamp,
  });

  final GeoPoint point;
  final double heading;
  final double speedKmH;
  final double accuracyMeters;
  final int sequenceNumber;
  final DateTime timestamp;

  BusPosition copyWith({
    GeoPoint? point,
    double? heading,
    double? speedKmH,
    double? accuracyMeters,
    int? sequenceNumber,
    DateTime? timestamp,
  }) {
    return BusPosition(
      point: point ?? this.point,
      heading: heading ?? this.heading,
      speedKmH: speedKmH ?? this.speedKmH,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': point.latitude,
    'longitude': point.longitude,
    'heading': heading,
    'speed_kmh': speedKmH,
    'accuracy': accuracyMeters,
    'seq': sequenceNumber,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BusPosition.fromJson(Map<String, dynamic> json) {
    return BusPosition(
      point: GeoPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      speedKmH: (json['speed_kmh'] as num?)?.toDouble() ?? 0.0,
      accuracyMeters:
          (json['accuracy'] as num?)?.toDouble() ??
          (json['accuracy_meters'] as num?)?.toDouble() ??
          0.0,
      sequenceNumber:
          (json['seq'] as num?)?.toInt() ??
          (json['sequence_number'] as num?)?.toInt() ??
          0,
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'] as String)
              : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusPosition &&
          runtimeType == other.runtimeType &&
          point == other.point &&
          heading == other.heading &&
          speedKmH == other.speedKmH &&
          accuracyMeters == other.accuracyMeters &&
          sequenceNumber == other.sequenceNumber &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
    point,
    heading,
    speedKmH,
    accuracyMeters,
    sequenceNumber,
    timestamp,
  );

  @override
  String toString() =>
      'BusPosition(point: $point, heading: $heading, speedKmH: $speedKmH)';
}
