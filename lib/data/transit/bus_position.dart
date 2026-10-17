import '../../core/geo/geo_point.dart';
import 'bus_telemetry.dart';

/// Immutable representation of a bus's geographic telemetry.
class BusPosition {
  const BusPosition({
    required this.point,
    this.heading = 0.0,
    this.hasHeading = true,
    this.speedKmH = 0.0,
    this.hasSpeed = true,
    this.accuracyMeters = 0.0,
    this.hasAccuracy = true,
    this.epoch,
    this.sequenceNumber,
    required this.timestamp,
  });

  final GeoPoint point;
  final double heading;
  final bool hasHeading;
  final double speedKmH;
  final bool hasSpeed;
  final double accuracyMeters;
  final bool hasAccuracy;
  final int? epoch;
  final int? sequenceNumber;
  double get speedMetersPerSecond => speedKmH / 3.6;
  final DateTime timestamp;

  /// True if coordinates represent a genuine, finite, calibrated GPS position.
  bool get isValid => BusTelemetry.isValidPoint(point);

  BusPosition copyWith({
    GeoPoint? point,
    double? heading,
    bool? hasHeading,
    double? speedKmH,
    bool? hasSpeed,
    double? accuracyMeters,
    bool? hasAccuracy,
    int? sequenceNumber,
    int? epoch,
    DateTime? timestamp,
  }) {
    return BusPosition(
      point: point ?? this.point,
      heading: heading ?? this.heading,
      hasHeading: hasHeading ?? this.hasHeading,
      speedKmH: speedKmH ?? this.speedKmH,
      hasSpeed: hasSpeed ?? this.hasSpeed,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      hasAccuracy: hasAccuracy ?? this.hasAccuracy,
      epoch: epoch ?? this.epoch,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': point.latitude,
    'longitude': point.longitude,
    'heading': hasHeading ? heading : null,
    'speed_kmh': hasSpeed ? speedKmH : null,
    'accuracy': hasAccuracy ? accuracyMeters : null,
    'epoch': epoch,
    'seq': sequenceNumber,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BusPosition.fromJson(
    Map<String, dynamic> json, {
    DateTime Function()? clock,
  }) {
    final latRaw = json['latitude'] ?? json['lat'];
    final lngRaw = json['longitude'] ?? json['lng'] ?? json['lon'];
    double? parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int? parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    final latNum = parseDouble(latRaw);
    final lngNum = parseDouble(lngRaw);

    final hasCoordinates =
        latNum != null &&
        lngNum != null &&
        GeoPoint.isValidCoordinates(latNum, lngNum);

    final GeoPoint point =
        hasCoordinates
            ? GeoPoint(latitude: latNum, longitude: lngNum)
            : const GeoPoint(latitude: 0.0, longitude: 0.0);

    final headingNum = parseDouble(json['heading']);
    final hasHeading = headingNum != null && headingNum.isFinite;
    final heading = hasHeading ? (headingNum % 360 + 360) % 360 : 0.0;

    final rawSpeed = parseDouble(json['speed_kmh'] ?? json['speed']);
    final hasSpeed = rawSpeed != null && rawSpeed.isFinite && rawSpeed >= 0;
    final speedKmH = hasSpeed ? rawSpeed : 0.0;

    final rawAccuracy = parseDouble(
      json['accuracy'] ?? json['accuracy_meters'],
    );
    final hasAccuracy =
        rawAccuracy != null && rawAccuracy.isFinite && rawAccuracy >= 0;
    final accuracyMeters = hasAccuracy ? rawAccuracy : 0.0;

    DateTime timestamp;
    try {
      final rawTime =
          json['timestamp'] ?? json['recorded_at'] ?? json['last_seen'];
      if (rawTime is String) {
        timestamp = DateTime.parse(rawTime);
      } else {
        timestamp = (clock ?? DateTime.now)();
      }
    } catch (_) {
      timestamp = (clock ?? DateTime.now)();
    }

    return BusPosition(
      point: point,
      heading: heading,
      hasHeading: hasHeading,
      speedKmH: speedKmH,
      hasSpeed: hasSpeed,
      accuracyMeters: accuracyMeters,
      hasAccuracy: hasAccuracy,
      epoch: parseInt(json['epoch']),
      sequenceNumber:
          parseInt(json['seq']) ??
          parseInt(json['sequence']) ??
          parseInt(json['sequence_number']),
      timestamp: timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusPosition &&
          runtimeType == other.runtimeType &&
          point == other.point &&
          heading == other.heading &&
          hasHeading == other.hasHeading &&
          speedKmH == other.speedKmH &&
          hasSpeed == other.hasSpeed &&
          accuracyMeters == other.accuracyMeters &&
          hasAccuracy == other.hasAccuracy &&
          epoch == other.epoch &&
          sequenceNumber == other.sequenceNumber &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
    point,
    heading,
    hasHeading,
    speedKmH,
    hasSpeed,
    accuracyMeters,
    hasAccuracy,
    epoch,
    sequenceNumber,
    timestamp,
  );

  @override
  String toString() =>
      'BusPosition(point: $point, heading: $heading, speedKmH: $speedKmH)';
}
