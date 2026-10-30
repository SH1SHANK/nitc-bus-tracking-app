/// Immutable user profile model for Tracklet containing username and email.
class Profile {
  const Profile({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    this.avatarSeed,
    this.role = 'Student',
    this.notificationsEnabled = false,
    this.locationPermissionGranted = false,
    this.hasCompletedOnboarding = false,
  });

  final String id;
  final String name;
  final String? username;
  final String email;
  final String? avatarSeed;
  final String role;
  final bool notificationsEnabled;
  final bool locationPermissionGranted;
  final bool hasCompletedOnboarding;

  /// Deterministic DiceBear Voxel Art avatar URL generated dynamically from avatarSeed or user email.
  String get avatarUrl {
    final explicit = avatarSeed?.trim();
    final seed =
        (explicit != null && explicit.isNotEmpty)
            ? explicit
            : (username != null && username!.trim().isNotEmpty
                ? username!.trim().toLowerCase()
                : (email.trim().isNotEmpty
                    ? email.trim().toLowerCase()
                    : (name.trim().isNotEmpty
                        ? name.trim().toLowerCase()
                        : 'guest')));
    return 'https://api.dicebear.com/10.x/voxel-art/png?seed=${Uri.encodeComponent(seed)}&size=150&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf';
  }

  Profile copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? avatarSeed,
    String? role,
    bool? notificationsEnabled,
    bool? locationPermissionGranted,
    bool? hasCompletedOnboarding,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      role: role ?? this.role,
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
    'email': email,
    if (avatarSeed != null) 'avatar_seed': avatarSeed,
    'role': role,
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
      email: json['email'] as String? ?? '',
      avatarSeed: json['avatar_seed'] as String?,
      role: json['role'] as String? ?? 'Student',
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
      'Profile(id: $id, name: $name, username: $username, email: $email, avatarSeed: $avatarSeed)';
}
