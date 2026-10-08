/// Immutable user profile model for Tracklet with academic profile metadata.
class Profile {
  const Profile({
    required this.id,
    required this.name,
    this.username,
    this.rollNumber,
    required this.email,
    this.role = 'student',
    this.department = 'Computer Science & Engineering',
    this.branch = 'Computer Science & Engineering',
    this.batch = '2026',
    this.semester = 'Semester 6',
    this.hostel = 'MBH II',
    this.notificationsEnabled = true,
    this.locationPermissionGranted = false,
    this.hasCompletedOnboarding = false,
  });

  final String id;
  final String name;
  final String? username;
  final String? rollNumber;
  final String email;
  final String role;
  final String department;
  final String branch;
  final String batch;
  final String semester;
  final String hostel;
  final bool notificationsEnabled;
  final bool locationPermissionGranted;
  final bool hasCompletedOnboarding;

  Profile copyWith({
    String? id,
    String? name,
    String? username,
    String? rollNumber,
    String? email,
    String? role,
    String? department,
    String? branch,
    String? batch,
    String? semester,
    String? hostel,
    bool? notificationsEnabled,
    bool? locationPermissionGranted,
    bool? hasCompletedOnboarding,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      rollNumber: rollNumber ?? this.rollNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      branch: branch ?? this.branch,
      batch: batch ?? this.batch,
      semester: semester ?? this.semester,
      hostel: hostel ?? this.hostel,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationPermissionGranted:
          locationPermissionGranted ?? this.locationPermissionGranted,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'roll_number': rollNumber,
    'email': email,
    'role': role,
    'department': department,
    'branch': branch,
    'batch': batch,
    'semester': semester,
    'hostel': hostel,
    'notifications_enabled': notificationsEnabled,
    'location_permission_granted': locationPermissionGranted,
    'has_completed_onboarding': hasCompletedOnboarding,
  };

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String? ?? 'user-nitc-shashank',
      name: json['name'] as String? ?? 'Shashank Mergu',
      username: json['username'] as String? ?? 'shashank',
      rollNumber: json['roll_number'] as String? ?? 'B210000CS',
      email: json['email'] as String? ?? 'shashank@nitc.ac.in',
      role: json['role'] as String? ?? 'student',
      department:
          json['department'] as String? ??
          json['branch'] as String? ??
          'Computer Science & Engineering',
      branch:
          json['branch'] as String? ??
          json['department'] as String? ??
          'Computer Science & Engineering',
      batch: json['batch'] as String? ?? '2026',
      semester: json['semester'] as String? ?? 'Semester 6',
      hostel: json['hostel'] as String? ?? 'MBH II',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      locationPermissionGranted:
          json['location_permission_granted'] as bool? ?? false,
      hasCompletedOnboarding:
          json['has_completed_onboarding'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          username == other.username &&
          hasCompletedOnboarding == other.hasCompletedOnboarding &&
          notificationsEnabled == other.notificationsEnabled;

  @override
  int get hashCode => Object.hash(
    id,
    email,
    username,
    notificationsEnabled,
    hasCompletedOnboarding,
  );

  @override
  String toString() =>
      'Profile(id: $id, name: $name, username: $username, branch: $branch, batch: $batch, semester: $semester)';
}
