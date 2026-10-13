/// Campus hostel / residential hall model for Tracklet.
class Hostel {
  const Hostel({
    required this.id,
    required this.name,
    this.shortCode,
    this.gender,
  });

  final String id;
  final String name;
  final String? shortCode;
  final String? gender;

  Map<String, dynamic> toJson() => {
    'hostel_id': id,
    'hostel_name': name,
    'short_code': shortCode,
    'gender': gender,
  };

  factory Hostel.fromJson(Map<String, dynamic> json) {
    return Hostel(
      id: (json['hostel_id'] ?? json['id'] ?? '').toString(),
      name: (json['hostel_name'] ?? json['name'] ?? '').toString(),
      shortCode: json['short_code'] as String?,
      gender: json['gender'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hostel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          shortCode == other.shortCode &&
          gender == other.gender;

  @override
  int get hashCode => Object.hash(id, name, shortCode, gender);

  @override
  String toString() => 'Hostel(id: $id, name: $name, shortCode: $shortCode)';
}
