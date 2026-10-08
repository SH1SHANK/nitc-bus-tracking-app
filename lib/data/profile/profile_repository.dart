import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../supabase/supabase_client_provider.dart';
import 'profile.dart';

abstract class ProfileRepository {
  Future<Profile> getProfile();
  Future<void> saveProfile(Profile profile);
  Future<void> updateNotificationPreference(bool enabled);
  Future<void> setOnboardingCompleted(bool completed);
}

class LocalOrSupabaseProfileRepository implements ProfileRepository {
  LocalOrSupabaseProfileRepository();

  Profile _cachedProfile = const Profile(
    id: 'user-nitc-student',
    name: 'Shashank Mergu',
    username: 'shashank',
    rollNumber: 'B210000CS',
    email: 'shashank@nitc.ac.in',
    role: 'Student',
    department: 'Computer Science & Engineering',
    branch: 'Computer Science & Engineering',
    batch: '2026',
    semester: 'Semester 6',
    hostel: 'MBH II',
    notificationsEnabled: true,
    locationPermissionGranted: false,
    hasCompletedOnboarding: false,
  );

  @override
  Future<Profile> getProfile() async {
    return _cachedProfile;
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    _cachedProfile = profile;
    AppLogger.info('Profile saved: $profile');
  }

  @override
  Future<void> updateNotificationPreference(bool enabled) async {
    _cachedProfile = _cachedProfile.copyWith(notificationsEnabled: enabled);
    AppLogger.info('Notification preference updated: $enabled');
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    _cachedProfile = _cachedProfile.copyWith(hasCompletedOnboarding: completed);
    AppLogger.info('Onboarding completion set to: $completed');
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  ref.watch(supabaseClientProvider);
  return LocalOrSupabaseProfileRepository();
});
