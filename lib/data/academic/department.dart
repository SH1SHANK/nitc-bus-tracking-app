/// Academic department model for Tracklet.
class Department {
  const Department({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {
    'department_id': id,
    'department_name': name,
  };

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: (json['department_id'] ?? json['id'] ?? '').toString(),
      name: (json['department_name'] ?? json['name'] ?? '').toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Department &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'Department(id: $id, name: $name)';
}
