import 'dart:math' as math;

/// Platform- and map-agnostic geographic coordinate representing latitude and longitude in degrees.
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude})
    : assert(
        latitude >= -90.0 && latitude <= 90.0,
        'Latitude must be between -90 and 90 degrees',
      ),
      assert(
        longitude >= -180.0 && longitude <= 180.0,
        'Longitude must be between -180 and 180 degrees',
      );

  final double latitude;
  final double longitude;

  /// Haversine distance in meters between this point and [other].
  double distanceToMeters(GeoPoint other) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);

    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(other.latitude);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) *
            math.sin(dLon / 2) *
            math.cos(lat1) *
            math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  /// Initial bearing (forward azimuth) from this point to [other] in degrees (0..360).
  double bearingTo(GeoPoint other) {
    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(other.latitude);
    final dLon = _toRadians(other.longitude - longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final radians = math.atan2(y, x);
    return (_toDegrees(radians) + 360) % 360;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
  static double _toDegrees(double radians) => radians * 180.0 / math.pi;

  Map<String, dynamic> toJson() => {'lat': latitude, 'lng': longitude};

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] ?? json['latitude']) as num;
    final lng = (json['lng'] ?? json['longitude'] ?? json['lon']) as num;
    return GeoPoint(latitude: lat.toDouble(), longitude: lng.toDouble());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          runtimeType == other.runtimeType &&
          (latitude - other.latitude).abs() < 1e-7 &&
          (longitude - other.longitude).abs() < 1e-7;

  @override
  int get hashCode =>
      Object.hash((latitude * 1e5).round(), (longitude * 1e5).round());

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}
