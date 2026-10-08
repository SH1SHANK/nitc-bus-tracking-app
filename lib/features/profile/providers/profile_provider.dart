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

  Future<void> toggleNotifications(bool enabled) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.updateNotificationPreference(enabled);
    state = AsyncData(
      state.value?.copyWith(notificationsEnabled: enabled) ??
          Profile(
            id: 'default',
            name: 'Shashank',
            email: 'shashank@nitc.ac.in',
            notificationsEnabled: enabled,
          ),
    );
  }
}
