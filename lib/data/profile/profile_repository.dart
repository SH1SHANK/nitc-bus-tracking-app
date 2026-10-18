import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logging/app_logger.dart';
import '../supabase/supabase_client_provider.dart';
import '../transit/transit_cache_metrics.dart';
import 'profile.dart';

abstract class ProfileRepository {
  Future<Profile> getProfile();
  Future<void> saveProfile(Profile profile);
  Future<void> setOnboardingCompleted(bool completed);
  Future<bool> isUsernameAvailable(String username);
  Future<Profile> changeUsername(String newUsername);
}

class LocalOrSupabaseProfileRepository implements ProfileRepository {
  LocalOrSupabaseProfileRepository(this._supabase);

  final SupabaseClient? _supabase;
  Profile? _cachedProfile;
  String? _cachedUserId;
  Future<Profile>? _inFlightProfile;
  final Set<String> _localTakenUsernames = {
    'admin',
    'root',
    'support',
    'nitc',
    'bustracker',
    'tracklet',
  };

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final client = _supabase;
    final clean = username.trim().toLowerCase();
    if (clean.isEmpty) return false;

    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client.rpc<bool>(
          'check_username_available',
          params: {'p_username': clean},
        );
        return res == true;
      } catch (e) {
        AppLogger.error('Error checking username availability: $e');
        rethrow;
      }
    }

    return !_localTakenUsernames.contains(clean);
  }

  @override
  Future<Profile> changeUsername(String newUsername) async {
    final clean = newUsername.trim();
    final client = _supabase;
    final currentUser = client?.auth.currentUser;

    if (client != null && currentUser != null && !currentUser.isAnonymous) {
      try {
        final data = await client.rpc<dynamic>(
          'change_my_username',
          params: {'p_username': clean},
        );
        if (data is List && data.isNotEmpty) {
          final row = Map<String, dynamic>.from(data.first as Map);
          _cachedProfile = _mapRowToProfile(row, currentUser);
          return _cachedProfile!;
        }
        throw StateError('Updated profile record was not returned.');
      } catch (e) {
        AppLogger.error('Error changing username in Supabase: $e');
        rethrow;
      }
    } else {
      if (_localTakenUsernames.contains(clean.toLowerCase())) {
        throw StateError('Username is already taken');
      }
      _localTakenUsernames.add(clean.toLowerCase());
      final current = _cachedProfile ?? await getProfile();
      _cachedProfile = current.copyWith(username: clean);
      return _cachedProfile!;
    }
  }

  @override
  Future<Profile> getProfile() async {
    final client = _supabase;
    final currentUser = client?.auth.currentUser;
    if (_cachedUserId != currentUser?.id) {
      _cachedProfile = null;
      _cachedUserId = currentUser?.id;
    }

    if (client != null && currentUser != null) {
      if (currentUser.isAnonymous) {
        _cachedProfile = Profile(
          id: currentUser.id,
          name: 'Guest Rider',
          email: '',
          role: 'Guest',
          hasCompletedOnboarding: true,
        );
        return _cachedProfile!;
      }

      if (_cachedProfile != null) {
        TransitCacheMetrics.instance.recordHit('profile');
        return _cachedProfile!;
      }

      final inFlight = _inFlightProfile;
      if (inFlight != null) {
        TransitCacheMetrics.instance.recordDeduplicated('profile');
        return inFlight;
      }

      final future = _fetchProfile(client, currentUser);
      _inFlightProfile = future;
      return future.whenComplete(() {
        if (identical(_inFlightProfile, future)) {
          _inFlightProfile = null;
        }
      });
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

  Future<Profile> _fetchProfile(SupabaseClient client, User currentUser) async {
    TransitCacheMetrics.instance.recordMiss('profile');
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

  void invalidateCache() {
    _cachedProfile = null;
    _inFlightProfile = null;
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    final client = _supabase;
    final currentUser = client?.auth.currentUser;
    if (client != null && currentUser != null && !currentUser.isAnonymous) {
      try {
        if (profile.avatarSeed != null) {
          try {
            await client.auth.updateUser(
              UserAttributes(data: {'avatar_seed': profile.avatarSeed}),
            );
          } catch (_) {}
        }
        await client.rpc<dynamic>(
          'update_my_profile',
          params: {
            'p_full_name': profile.name,
            'p_department_id': _departmentNameToId(profile.department),
            'p_batch': profile.batch,
            'p_hostel': profile.hostel,
            'p_notification_prefs': {
              'location_permission_granted': profile.locationPermissionGranted,
            },
            if (profile.username != null && profile.username!.trim().isNotEmpty)
              'p_username': profile.username!.trim(),
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
  Future<void> setOnboardingCompleted(bool completed) async {
    final client = _supabase;
    final currentUser = client?.auth.currentUser;
    if (client != null &&
        currentUser != null &&
        !currentUser.isAnonymous &&
        completed) {
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
              'location_permission_granted': current.locationPermissionGranted,
            },
            if (current.username != null && current.username!.trim().isNotEmpty)
              'p_username': current.username!.trim(),
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
      username:
          row['username'] as String? ??
          authUser.userMetadata?['username'] as String? ??
          authUser.email?.split('@').first ??
          'student',
      email: authUser.email ?? 'student@nitc.ac.in',
      avatarSeed:
          authUser.userMetadata?['avatar_seed'] as String? ??
          row['avatar_seed'] as String? ??
          _cachedProfile?.avatarSeed,
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
      notificationsEnabled: false,
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
