import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/components/tracklet_card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../onboarding/providers/onboarding_provider.dart';

/// App information, campus build version, and system credentials summary.
class AppInfoCard extends ConsumerWidget {
  const AppInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TrackletCard(
      padding: const EdgeInsets.all(TrackletSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About Tracklet', style: TrackletTypography.titleMedium),
          const SizedBox(height: TrackletSpacing.sm),
          const Text(
            AppConfig.campusName,
            style: TrackletTypography.bodyMedium,
          ),
          const SizedBox(height: TrackletSpacing.md),
          const Divider(),
          const SizedBox(height: TrackletSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Version', style: TrackletTypography.bodySmall),
              Text(
                '${AppConfig.appVersion} (${AppConfig.environment})',
                style: TrackletTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: TrackletColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Data Provider', style: TrackletTypography.bodySmall),
              Text(
                AppConfig.hasSupabaseCredentials
                    ? 'Supabase Realtime'
                    : 'Local Seed Network',
                style: TrackletTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: TrackletColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.lg),
          TrackletButton(
            label: 'Replay Onboarding Tour',
            variant: TrackletButtonVariant.secondary,
            isFullWidth: true,
            icon: const TrackletIcon(TrackletIcons.refresh, size: 18),
            onPressed: () {
              ref.read(onboardingProvider.notifier).reset();
              context.go('/onboarding');
            },
          ),
        ],
      ),
    );
  }
}
