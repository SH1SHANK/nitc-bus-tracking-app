/// Immutable user profile model for Tracklet with academic profile metadata.
class Profile {
  const Profile({
    required this.id,
    required this.name,
    this.username,
    this.rollNumber,
    required this.email,
    this.avatarSeed,
    this.role = 'Student',
    this.department = '',
    this.branch = '',
    this.batch = '',
    this.semester = '',
    this.hostel = '',
    this.notificationsEnabled = false,
    this.locationPermissionGranted = false,
    this.hasCompletedOnboarding = false,
  });

  final String id;
  final String name;
  final String? username;
  final String? rollNumber;
  final String email;
  final String? avatarSeed;
  final String role;
  final String department;
  final String branch;
  final String batch;
  final String semester;
  final String hostel;
  final bool notificationsEnabled;
  final bool locationPermissionGranted;
  final bool hasCompletedOnboarding;

  /// Deterministic DiceBear Voxel Art avatar URL generated dynamically from avatarSeed or user email.
  String get avatarUrl {
    final explicit = avatarSeed?.trim();
    final seed =
        (explicit != null && explicit.isNotEmpty)
            ? explicit
            : (email.trim().isNotEmpty
                ? email.trim().toLowerCase()
                : (name.trim().isNotEmpty
                    ? name.trim().toLowerCase()
                    : 'guest'));
    return 'https://api.dicebear.com/10.x/voxel-art/png?seed=${Uri.encodeComponent(seed)}&size=150&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf';
  }

  Profile copyWith({
    String? id,
    String? name,
    String? username,
    String? rollNumber,
    String? email,
    String? avatarSeed,
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
      avatarSeed: avatarSeed ?? this.avatarSeed,
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
    'avatar_seed': avatarSeed,
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
      id: json['id'] as String? ?? json['user_id'] as String? ?? '',
      name:
          json['name'] as String? ?? json['full_name'] as String? ?? 'Student',
      username: json['username'] as String?,
      rollNumber: json['roll_number'] as String?,
      email: json['email'] as String? ?? '',
      avatarSeed: json['avatar_seed'] as String?,
      role: json['role'] as String? ?? 'Student',
      department:
          json['department'] as String? ??
          json['department_name'] as String? ??
          json['department_id'] as String? ??
          '',
      branch:
          json['branch'] as String? ??
          json['department_name'] as String? ??
          json['department_id'] as String? ??
          '',
      batch: json['batch'] as String? ?? '',
      semester: json['semester'] as String? ?? '',
      hostel: json['hostel'] as String? ?? '',
      notificationsEnabled:
          json['notifications_enabled'] as bool? ??
          (json['notification_prefs'] as Map?)?['notifications_enabled']
              as bool? ??
          true,
      locationPermissionGranted:
          json['location_permission_granted'] as bool? ??
          (json['notification_prefs'] as Map?)?['location_permission_granted']
              as bool? ??
          false,
      hasCompletedOnboarding:
          json['has_completed_onboarding'] as bool? ??
          json['onboarding_completed'] as bool? ??
          false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          avatarSeed == other.avatarSeed &&
          username == other.username &&
          hasCompletedOnboarding == other.hasCompletedOnboarding &&
          notificationsEnabled == other.notificationsEnabled;

  @override
  int get hashCode => Object.hash(
    id,
    email,
    avatarSeed,
    username,
    notificationsEnabled,
    hasCompletedOnboarding,
  );

  @override
  String toString() =>
      'Profile(id: $id, name: $name, username: $username, avatarSeed: $avatarSeed, branch: $branch, batch: $batch, semester: $semester)';
}
