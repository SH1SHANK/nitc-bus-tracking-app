import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/profile/profile.dart';
import '../../../data/profile/profile_repository.dart';
import '../../auth/providers/auth_provider.dart';

final profileStateProvider = AsyncNotifierProvider<ProfileNotifier, Profile>(
  () {
    return ProfileNotifier();
  },
);

class ProfileNotifier extends AsyncNotifier<Profile> {
  @override
  Future<Profile> build() async {
    ref.watch(authNotifierProvider);
    final repo = ref.watch(profileRepositoryProvider);
    return repo.getProfile();
  }

  Future<void> updateDisplayName(String name) async {
    final current = state.value ?? await future;
    final updated = current.copyWith(name: name);
    final repo = ref.read(profileRepositoryProvider);
    await repo.saveProfile(updated);
    state = AsyncData(updated);
  }

  Future<void> updateAvatarSeed(String avatarSeed) async {
    final current = state.value ?? await future;
    final updated = current.copyWith(avatarSeed: avatarSeed);
    state = AsyncData(updated);
    final repo = ref.read(profileRepositoryProvider);
    await repo.saveProfile(updated);
  }

  Future<void> updateProfile(Profile profile) async {
    state = AsyncData(profile);
    final repo = ref.read(profileRepositoryProvider);
    await repo.saveProfile(profile);
  }
}
