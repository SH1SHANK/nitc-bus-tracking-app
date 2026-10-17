import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../design_system/components/tracklet_brand_lockup.dart';
import '../../../design_system/components/tracklet_card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// App information, campus build version, and system credentials summary.
class AppInfoCard extends StatelessWidget {
  const AppInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return TrackletCard(
      padding: const EdgeInsets.all(TrackletSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TrackletBrandLockup(
                logoSize: 32.0,
                wordmarkHeight: 18.0,
              ),
              const Spacer(),
              Text(
                'About BusTracker',
                style: TrackletTypography.adaptive(
                  context,
                  TrackletTypography.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.sm),
          Text(
            AppConfig.campusName,
            style: TrackletTypography.adaptive(
              context,
              TrackletTypography.bodyMedium,
            ),
          ),
          const SizedBox(height: TrackletSpacing.md),
          Divider(color: TrackletColors.adaptiveDivider(context)),
          const SizedBox(height: TrackletSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Version',
                style: TrackletTypography.adaptiveSecondary(
                  context,
                  TrackletTypography.bodySmall,
                ),
              ),
              Text(
                '${AppConfig.appVersion} (${AppConfig.environment})',
                style: TrackletTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: TrackletColors.adaptiveTextPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Data Provider',
                style: TrackletTypography.adaptiveSecondary(
                  context,
                  TrackletTypography.bodySmall,
                ),
              ),
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
        ],
      ),
    );
  }
}
