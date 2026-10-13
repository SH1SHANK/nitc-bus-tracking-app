import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  LocalOrSupabaseProfileRepository(this._supabase);

  final SupabaseClient? _supabase;
  Profile? _cachedProfile;
  String? _cachedUserId;

  @override
  Future<Profile> getProfile() async {
    final client = _supabase;
    final currentUser = client?.auth.currentUser;
    if (_cachedUserId != currentUser?.id) {
      _cachedProfile = null;
      _cachedUserId = currentUser?.id;
    }

    if (client != null && currentUser != null) {
      try {
        final data = await client.rpc<dynamic>('ensure_my_profile');
        if (data is List && data.isNotEmpty) {
          final row = Map<String, dynamic>.from(data.first as Map);
          _cachedProfile = _mapRowToProfile(row, currentUser);
          return _cachedProfile!;
        }
        throw StateError('Authenticated profile record was not returned.');
      } catch (e) {
        AppLogger.error('Error fetching profile from Supabase RPC: $e');
        rethrow;
      }
    }
    return _cachedProfile ??
        const Profile(
          id: 'guest',
          name: 'Student',
          email: 'student@nitc.ac.in',
          role: 'Student',
          hasCompletedOnboarding: false,
        );
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    final client = _supabase;
    if (client != null && client.auth.currentUser != null) {
      try {
        await client.rpc<dynamic>(
          'update_my_profile',
          params: {
            'p_full_name': profile.name,
            'p_department_id': _departmentNameToId(profile.department),
            'p_batch': profile.batch,
            'p_hostel': profile.hostel,
            'p_notification_prefs': {
              'notifications_enabled': profile.notificationsEnabled,
              'location_permission_granted': profile.locationPermissionGranted,
            },
          },
        );
        _cachedProfile = profile;
        AppLogger.info('Profile saved to Supabase');
      } catch (e) {
        AppLogger.error('Error updating profile in Supabase: $e');
        rethrow;
      }
    } else {
      _cachedProfile = profile;
    }
  }

  Future<void> updateDisplayName(String name) async {
    final current = _cachedProfile ?? await getProfile();
    final updated = current.copyWith(name: name);
    await saveProfile(updated);
  }

  @override
  Future<void> updateNotificationPreference(bool enabled) async {
    final current = _cachedProfile ?? await getProfile();
    final updated = current.copyWith(notificationsEnabled: enabled);
    await saveProfile(updated);
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    final client = _supabase;
    if (client != null && client.auth.currentUser != null && completed) {
      try {
        final current = _cachedProfile ?? await getProfile();
        await client.rpc<dynamic>(
          'complete_onboarding',
          params: {
            'p_full_name': current.name,
            'p_department_id': _departmentNameToId(current.department),
            'p_batch': current.batch,
            'p_hostel': current.hostel,
            'p_notification_prefs': {
              'notifications_enabled': current.notificationsEnabled,
              'location_permission_granted': current.locationPermissionGranted,
            },
          },
        );
        _cachedProfile = current.copyWith(hasCompletedOnboarding: completed);
        AppLogger.info('Onboarding completed synced to Supabase');
      } catch (e) {
        AppLogger.error('Error completing onboarding in Supabase: $e');
        rethrow;
      }
    } else {
      _cachedProfile = (_cachedProfile ??
              const Profile(
                id: 'guest',
                name: 'Student',
                email: 'student@nitc.ac.in',
              ))
          .copyWith(hasCompletedOnboarding: completed);
    }
  }

  Profile _mapRowToProfile(Map<String, dynamic> row, User authUser) {
    return Profile(
      id: row['user_id']?.toString() ?? authUser.id,
      name: row['full_name'] as String? ?? 'Student',
      username: authUser.email?.split('@').first ?? 'student',
      email: authUser.email ?? 'student@nitc.ac.in',
      role: 'Student',
      department:
          row['department_name'] as String? ??
          row['department_id'] as String? ??
          '',
      branch:
          row['department_name'] as String? ??
          row['department_id'] as String? ??
          '',
      batch: row['batch'] as String? ?? '',
      semester: row['semester'] as String? ?? '',
      hostel: row['hostel'] as String? ?? '',
      notificationsEnabled:
          (row['notification_prefs'] as Map?)?['notifications_enabled']
              as bool? ??
          true,
      locationPermissionGranted:
          (row['notification_prefs'] as Map?)?['location_permission_granted']
              as bool? ??
          false,
      hasCompletedOnboarding: row['onboarding_completed'] as bool? ?? false,
    );
  }

  String _departmentNameToId(String name) {
    final clean = name.trim();
    const idSet = {
      'AR',
      'BT',
      'CA',
      'CE',
      'CH',
      'CS',
      'CY',
      'EC',
      'EE',
      'EN',
      'EP',
      'GS',
      'HS',
      'IE',
      'IK',
      'MA',
      'ME',
      'MS',
      'MT',
      'PE',
      'PH',
    };
    if (idSet.contains(clean.toUpperCase())) {
      return clean.toUpperCase();
    }

    switch (clean) {
      case 'Architecture & Planning':
      case 'Architecture':
        return 'AR';
      case 'Biotechnology':
        return 'BT';
      case 'Fine Arts & Cultural Activities':
        return 'CA';
      case 'Civil Engineering':
        return 'CE';
      case 'Chemical Engineering':
        return 'CH';
      case 'Computer Science & Engineering':
      case 'Computer Science':
        return 'CS';
      case 'Chemistry':
        return 'CY';
      case 'Electronics & Communication Engineering':
      case 'Electronics & Communication':
        return 'EC';
      case 'Electrical Engineering':
      case 'Electrical & Electronics Engineering':
        return 'EE';
      case 'Energy Engineering':
        return 'EN';
      case 'Engineering Physics':
        return 'EP';
      case 'Global Studies':
        return 'GS';
      case 'Humanities & Social Sciences':
        return 'HS';
      case 'Industrial Engineering':
        return 'IE';
      case 'Indian Knowledge Systems':
        return 'IK';
      case 'Mathematics':
        return 'MA';
      case 'Mechanical Engineering':
        return 'ME';
      case 'Materials Science & Engineering':
        return 'MS';
      case 'Metallurgical & Materials Engineering':
        return 'MT';
      case 'Production Engineering':
        return 'PE';
      case 'Physics':
        return 'PH';
      default:
        return clean.isNotEmpty ? clean : 'CS';
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return LocalOrSupabaseProfileRepository(supabase);
});
