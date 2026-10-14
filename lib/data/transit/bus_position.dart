import '../../core/geo/geo_point.dart';

/// Immutable representation of a bus's geographic telemetry.
class BusPosition {
  const BusPosition({
    required this.point,
    this.heading = 0.0,
    this.speedKmH = 0.0,
    this.hasSpeed = true,
    this.accuracyMeters = 0.0,
    this.epoch,
    this.sequenceNumber,
    required this.timestamp,
  });

  final GeoPoint point;
  final double heading;
  final double speedKmH;
  final bool hasSpeed;
  final double accuracyMeters;
  final int? epoch;
  final int? sequenceNumber;
  double get speedMetersPerSecond => speedKmH / 3.6;
  final DateTime timestamp;

  BusPosition copyWith({
    GeoPoint? point,
    double? heading,
    double? speedKmH,
    bool? hasSpeed,
    double? accuracyMeters,
    int? sequenceNumber,
    int? epoch,
    DateTime? timestamp,
  }) {
    return BusPosition(
      point: point ?? this.point,
      heading: heading ?? this.heading,
      speedKmH: speedKmH ?? this.speedKmH,
      hasSpeed: hasSpeed ?? this.hasSpeed,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      epoch: epoch ?? this.epoch,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': point.latitude,
    'longitude': point.longitude,
    'heading': heading,
    'speed_kmh': hasSpeed ? speedKmH : null,
    'accuracy': accuracyMeters,
    'epoch': epoch,
    'seq': sequenceNumber,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BusPosition.fromJson(
    Map<String, dynamic> json, {
    DateTime Function()? clock,
  }) {
    return BusPosition(
      point: GeoPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      // The telemetry simulator and RPC use km/h (speedKmh), then ETA converts
      // this value to m/s through speedMetersPerSecond.
      speedKmH:
          ((json['speed_kmh'] ?? json['speed']) as num?)?.toDouble() ?? 0.0,
      hasSpeed: json['speed_kmh'] is num || json['speed'] is num,
      accuracyMeters:
          (json['accuracy'] as num?)?.toDouble() ??
          (json['accuracy_meters'] as num?)?.toDouble() ??
          0.0,
      epoch: (json['epoch'] as num?)?.toInt(),
      sequenceNumber:
          (json['seq'] as num?)?.toInt() ??
          (json['sequence'] as num?)?.toInt() ??
          (json['sequence_number'] as num?)?.toInt(),
      timestamp: DateTime.parse(
        (json['timestamp'] ??
                json['recorded_at'] ??
                json['last_seen'] ??
                (clock ?? DateTime.now)().toIso8601String())
            as String,
      ),
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
          hasSpeed == other.hasSpeed &&
          accuracyMeters == other.accuracyMeters &&
          epoch == other.epoch &&
          sequenceNumber == other.sequenceNumber &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
    point,
    heading,
    speedKmH,
    hasSpeed,
    accuracyMeters,
    epoch,
    sequenceNumber,
    timestamp,
  );

  @override
  String toString() =>
      'BusPosition(point: $point, heading: $heading, speedKmH: $speedKmH)';
}
