import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Step 8: Notification permission primer.
class OnboardingStepNotifications extends StatelessWidget {
  const OnboardingStepNotifications({
    super.key,
    required this.onEnableNotifications,
    required this.onSkip,
  });

  final VoidCallback onEnableNotifications;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.screenMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: TrackletSpacing.md),

          // Notification Hero Illustration
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
                const TrackletIcon(
                  TrackletIcons.notifications,
                  size: 64,
                  color: Color(0xFFD97706),
                ),
              ],
            ),
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Title
          Text(
            'Never Miss A Shuttle',
            style: TrackletTypography.displayLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TrackletSpacing.sm),
          Text(
            'Get real-time departure reminders when buses depart East Campus and approach your hostel stop, plus monsoon schedule updates.',
            style: TrackletTypography.bodyLarge.copyWith(
              color: TrackletColors.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Preview Notification Card
          Container(
            padding: const EdgeInsets.all(TrackletSpacing.md),
            decoration: BoxDecoration(
              color: TrackletColors.surfaceElevated,
              borderRadius: TrackletRadii.roundedMd,
              border: Border.all(color: TrackletColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: TrackletColors.busLiveBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const TrackletIcon(
                    TrackletIcons.bus,
                    color: TrackletColors.busLive,
                    size: 18,
                  ),
                ),
                const SizedBox(width: TrackletSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shuttle Arriving • MBH II',
                        style: TrackletTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Bus 2 will reach in 3 mins. Start walking now!',
                        style: TrackletTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TrackletSpacing.xxl),

          // Action Buttons
          TrackletButton(
            label: 'Enable Live Alerts',
            icon: const TrackletIcon(
              TrackletIcons.notifications,
              color: TrackletColors.textInverse,
              size: 18,
            ),
            isFullWidth: true,
            size: TrackletButtonSize.large,
            onPressed: onEnableNotifications,
          ),
          const SizedBox(height: TrackletSpacing.md),
          TrackletButton(
            label: 'Maybe later',
            variant: TrackletButtonVariant.ghost,
            isFullWidth: true,
            onPressed: onSkip,
          ),
          const SizedBox(height: TrackletSpacing.lg),
        ],
      ),
    );
  }
}
