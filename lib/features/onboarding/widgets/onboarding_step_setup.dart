import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_dropdown.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/onboarding_provider.dart';

/// Step 9: Optional Transit & Hostel preferences with terms agreement.
class OnboardingStepSetup extends StatelessWidget {
  const OnboardingStepSetup({
    super.key,
    required this.selectedHostel,
    required this.selectedStop,
    required this.agreedToTerms,
    required this.onHostelChanged,
    required this.onStopChanged,
    required this.onToggleTerms,
    required this.onContinue,
  });

  final String selectedHostel;
  final String selectedStop;
  final bool agreedToTerms;
  final ValueChanged<String> onHostelChanged;
  final ValueChanged<String> onStopChanged;
  final ValueChanged<bool> onToggleTerms;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.screenMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TrackletSpacing.lg),

          // Header
          Text(
            'Campus Transit Preferences',
            style: TrackletTypography.displayLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: TrackletSpacing.xs),
          const Text(
            'Choose your hostel and favorite stop for instant one-tap tracking from your home screen.',
            style: TrackletTypography.bodyMedium,
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // 1. Hostel / Mess
          Text(
            'Choose your hostel',
            style: TrackletTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TrackletSpacing.xs),
          TrackletDropdown(
            items: kNitcHostels,
            initialItem: selectedHostel.isNotEmpty ? selectedHostel : null,
            hintText: 'Select Hostel',
            prefixIcon: const Icon(
              Icons.home_work_outlined,
              color: TrackletColors.secondaryText,
              size: 20,
            ),
            isValid: selectedHostel.isNotEmpty,
            onChanged: (val) => onHostelChanged(val ?? ''),
          ),
          const SizedBox(height: TrackletSpacing.lg),

          // 2. Primary Bus Stop
          Text(
            'Choose your primary bus stop',
            style: TrackletTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TrackletSpacing.xs),
          TrackletDropdown(
            items: kNitcPrimaryStops,
            initialItem: selectedStop.isNotEmpty ? selectedStop : null,
            hintText: 'Select Primary Stop',
            prefixIcon: const Icon(
              Icons.directions_bus_outlined,
              color: TrackletColors.secondaryText,
              size: 20,
            ),
            isValid: selectedStop.isNotEmpty,
            onChanged: (val) => onStopChanged(val ?? ''),
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Terms Checkbox (as seen in screenshot 1)
          InkWell(
            onTap: () => onToggleTerms(!agreedToTerms),
            borderRadius: TrackletRadii.roundedSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: agreedToTerms,
                    activeColor: TrackletColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) => onToggleTerms(val ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: RichText(
                        text: TextSpan(
                          style: TrackletTypography.bodySmall.copyWith(
                            color: TrackletColors.textPrimary,
                          ),
                          children: const [
                            TextSpan(
                              text:
                                  'I confirm that I have read and agree to the ',
                            ),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: TrackletColors.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: TrackletColors.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: ' of Tracklet.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Continue Button
          TrackletButton(
            label: 'Complete Setup',
            icon: const TrackletIcon(
              TrackletIcons.check,
              color: TrackletColors.textInverse,
              size: 18,
            ),
            isFullWidth: true,
            size: TrackletButtonSize.large,
            onPressed: agreedToTerms ? onContinue : null,
          ),
          const SizedBox(height: TrackletSpacing.lg),
        ],
      ),
    );
  }
}
