import '../../core/geo/geo_point.dart';

/// Campus-building metadata from `public.campus_buildings`.
///
/// The database currently stores point coordinates, not building polygons.
class CampusBuilding {
  const CampusBuilding({
    required this.id,
    required this.name,
    required this.location,
    this.category,
    this.amenity,
    this.buildingType,
    this.description,
  });

  final String id;
  final String name;
  final GeoPoint location;
  final String? category;
  final String? amenity;
  final String? buildingType;
  final String? description;

  /// Returns null for malformed metadata or coordinates outside WGS84 bounds.
  static CampusBuilding? tryFromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim();
    final name = json['name']?.toString().trim();
    final latitude = _coordinate(json['lat'] ?? json['latitude']);
    final longitude = _coordinate(
      json['lon'] ?? json['lng'] ?? json['longitude'],
    );

    if (id == null ||
        id.isEmpty ||
        name == null ||
        name.isEmpty ||
        latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    return CampusBuilding(
      id: id,
      name: name,
      location: GeoPoint(latitude: latitude, longitude: longitude),
      category: _optionalText(json['category']),
      amenity: _optionalText(json['amenity']),
      buildingType: _optionalText(json['building_type']),
      description: _optionalText(json['description']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lat': location.latitude,
    'lng': location.longitude,
    if (category != null) 'category': category,
    if (amenity != null) 'amenity': amenity,
    if (buildingType != null) 'building_type': buildingType,
    if (description != null) 'description': description,
  };

  static double? _coordinate(Object? value) {
    if (value is! num) return null;
    final coordinate = value.toDouble();
    return coordinate.isFinite ? coordinate : null;
  }

  static String? _optionalText(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
