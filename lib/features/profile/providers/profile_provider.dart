import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/profile/profile.dart';
import '../../../data/profile/profile_repository.dart';

final profileStateProvider = AsyncNotifierProvider<ProfileNotifier, Profile>(
  () {
    return ProfileNotifier();
  },
);

class ProfileNotifier extends AsyncNotifier<Profile> {
  @override
  Future<Profile> build() async {
    final repo = ref.watch(profileRepositoryProvider);
    return repo.getProfile();
  }

  Future<void> updateDisplayName(String name) async {
    final current = state.value;
    if (current != null) {
      final updated = current.copyWith(name: name);
      final repo = ref.read(profileRepositoryProvider);
      await repo.saveProfile(updated);
      state = AsyncData(updated);
    }
  }

  Future<void> updateProfile(Profile profile) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.saveProfile(profile);
    state = AsyncData(profile);
  }

  Future<void> toggleNotifications(bool enabled) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.updateNotificationPreference(enabled);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(notificationsEnabled: enabled));
    }
  }
}
