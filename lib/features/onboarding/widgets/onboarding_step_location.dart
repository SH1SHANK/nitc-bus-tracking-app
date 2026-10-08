import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Step 7: Location permission primer with playful pin animation.
class OnboardingStepLocation extends StatelessWidget {
  const OnboardingStepLocation({
    super.key,
    required this.onEnableLocation,
    required this.onSkip,
  });

  final VoidCallback onEnableLocation;
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

          // Animated Map Pin Graphic
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  TrackletColors.locationBlueBg,
                  TrackletColors.permissionBlueBg,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/Research_New_Pin_Crop.gif',
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.location_on_rounded,
                    size: 80,
                    color: TrackletColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Title
          Text(
            'Enable Campus Location',
            style: TrackletTypography.displayLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TrackletSpacing.sm),
          Text(
            'Tracklet calculates live walking times to your nearest bus stop (MBH, Main Gate, ELHC) and shows live shuttles around you.',
            style: TrackletTypography.bodyLarge.copyWith(
              color: TrackletColors.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Privacy feature box
          Container(
            padding: const EdgeInsets.all(TrackletSpacing.md),
            decoration: BoxDecoration(
              color: TrackletColors.locationGreenBg,
              borderRadius: TrackletRadii.roundedMd,
              border: Border.all(color: TrackletColors.locationGreenBorder),
            ),
            child: Row(
              children: [
                const TrackletIcon(
                  TrackletIcons.check,
                  color: TrackletColors.locationGreenText,
                  size: 20,
                ),
                const SizedBox(width: TrackletSpacing.sm),
                Expanded(
                  child: Text(
                    'Campus only: Location is used exclusively to find nearest stops.',
                    style: TrackletTypography.bodySmall.copyWith(
                      color: TrackletColors.locationGreenDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TrackletSpacing.xxl),

          // Action Buttons
          TrackletButton(
            label: 'Enable Location',
            icon: const TrackletIcon(
              TrackletIcons.location,
              color: TrackletColors.textInverse,
              size: 18,
            ),
            isFullWidth: true,
            size: TrackletButtonSize.large,
            onPressed: onEnableLocation,
          ),
          const SizedBox(height: TrackletSpacing.md),
          TrackletButton(
            label: 'Skip for now',
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
