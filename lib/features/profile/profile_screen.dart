import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/components/tracklet_app_bar.dart';
import '../../design_system/components/tracklet_error_state.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import 'providers/profile_provider.dart';
import 'widgets/app_info_card.dart';
import 'widgets/notification_preferences_tile.dart';
import 'widgets/profile_header.dart';

/// Profile & settings screen for Tracklet.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileStateProvider);

    return Scaffold(
      backgroundColor: TrackletColors.background,
      appBar: const TrackletAppBar(title: 'Profile & Settings'),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: TrackletColors.primary),
          ),
          error: (error, stack) => TrackletErrorState(
            message: 'Unable to load profile data',
            onRetry: () => ref.invalidate(profileStateProvider),
          ),
          data: (profile) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: TrackletSpacing.screenMargin,
                vertical: TrackletSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeader(profile: profile),
                  const SizedBox(height: TrackletSpacing.xl),
                  NotificationPreferencesTile(
                    enabled: profile.notificationsEnabled,
                    onChanged: (val) {
                      ref
                          .read(profileStateProvider.notifier)
                          .toggleNotifications(val);
                    },
                  ),
                  const SizedBox(height: TrackletSpacing.xl),
                  const AppInfoCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
