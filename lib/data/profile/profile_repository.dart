import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../supabase/supabase_client_provider.dart';
import 'profile.dart';

abstract class ProfileRepository {
  Future<Profile> getProfile();
  Future<void> updateNotificationPreference(bool enabled);
}

class LocalOrSupabaseProfileRepository implements ProfileRepository {
  LocalOrSupabaseProfileRepository();

  Profile _cachedProfile = const Profile(
    id: 'user-nitc-shashank',
    name: 'Shashank',
    rollNumber: 'B210000CS',
    email: 'shashank@nitc.ac.in',
    role: 'Student',
    department: 'Computer Science & Engineering',
    notificationsEnabled: true,
  );

  @override
  Future<Profile> getProfile() async {
    return _cachedProfile;
  }

  @override
  Future<void> updateNotificationPreference(bool enabled) async {
    _cachedProfile = _cachedProfile.copyWith(notificationsEnabled: enabled);
    AppLogger.info('Notification preference updated: $enabled');
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  ref.watch(supabaseClientProvider);
  return LocalOrSupabaseProfileRepository();
});
