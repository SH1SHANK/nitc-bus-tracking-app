/// Immutable user profile model for Tracklet.
class Profile {
  const Profile({
    required this.id,
    required this.name,
    this.rollNumber,
    required this.email,
    this.role = 'student',
    this.department = 'Computer Science & Engineering',
    this.notificationsEnabled = true,
  });

  final String id;
  final String name;
  final String? rollNumber;
  final String email;
  final String role;
  final String department;
  final bool notificationsEnabled;

  Profile copyWith({
    String? id,
    String? name,
    String? rollNumber,
    String? email,
    String? role,
    String? department,
    bool? notificationsEnabled,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'roll_number': rollNumber,
    'email': email,
    'role': role,
    'department': department,
    'notifications_enabled': notificationsEnabled,
  };

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Shashank Mergu',
      rollNumber: json['roll_number'] as String?,
      email: json['email'] as String? ?? 'shashank@nitc.ac.in',
      role: json['role'] as String? ?? 'student',
      department:
          json['department'] as String? ?? 'Computer Science & Engineering',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          notificationsEnabled == other.notificationsEnabled;

  @override
  int get hashCode => Object.hash(id, email, notificationsEnabled);

  @override
  String toString() => 'Profile(id: $id, name: $name, email: $email)';
}
