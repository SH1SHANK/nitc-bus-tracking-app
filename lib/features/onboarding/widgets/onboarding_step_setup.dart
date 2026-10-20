import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/components/tracklet_dropdown.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

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
    this.hostels = const [],
    this.stops = const [],
  });

  final String selectedHostel;
  final String selectedStop;
  final bool agreedToTerms;
  final ValueChanged<String> onHostelChanged;
  final ValueChanged<String> onStopChanged;
  final ValueChanged<bool> onToggleTerms;
  final VoidCallback onContinue;
  final List<String> hostels;
  final List<String> stops;

  @override
  Widget build(BuildContext context) {
    final effectiveHostels = hostels;
    final effectiveStops = stops;

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
            'Campus transit preferences',
            style: TrackletTypography.displayLarge.copyWith(
              fontSize: TrackletTypography.fontSize26,
              fontWeight: TrackletTypography.weightExtraBold,
            ),
          ),
          const SizedBox(height: TrackletSpacing.xs),
          const Text(
            'Select your hostel and primary stop for quick access from the home screen.',
            style: TrackletTypography.bodyMedium,
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // 1. Hostel / Mess
          Text(
            'Select your hostel',
            style: TrackletTypography.titleMedium.copyWith(
              fontWeight: TrackletTypography.weightBold,
            ),
          ),
          const SizedBox(height: TrackletSpacing.xs),
          TrackletDropdown(
            items: effectiveHostels,
            initialItem: selectedHostel.isNotEmpty ? selectedHostel : null,
            hintText: 'Select hostel',
            prefixIcon: const Icon(
              TrackletIcons.building2,
              color: TrackletColors.secondaryText,
              size: 20,
            ),
            isValid: selectedHostel.isNotEmpty,
            onChanged: (val) => onHostelChanged(val ?? ''),
          ),
          const SizedBox(height: TrackletSpacing.lg),

          // 2. Primary Bus Stop
          Text(
            'Select your primary bus stop',
            style: TrackletTypography.titleMedium.copyWith(
              fontWeight: TrackletTypography.weightBold,
            ),
          ),
          const SizedBox(height: TrackletSpacing.xs),
          TrackletDropdown(
            items: effectiveStops,
            initialItem: selectedStop.isNotEmpty ? selectedStop : null,
            hintText: 'Select primary stop',
            prefixIcon: const Icon(
              TrackletIcons.bus,
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
              padding: const EdgeInsets.symmetric(vertical: TrackletSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: agreedToTerms,
                    activeColor: TrackletColors.primary,
                    shape: const RoundedRectangleBorder(
                      borderRadius: TrackletRadii.roundedXs,
                    ),
                    onChanged: (val) => onToggleTerms(val ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: TrackletSpacing.compactMd,
                      ),
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
                                fontWeight: TrackletTypography.weightBold,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: TrackletColors.tertiary,
                                fontWeight: TrackletTypography.weightBold,
                              ),
                            ),
                            TextSpan(text: ' of BusTracker.'),
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
            label: 'Complete setup',
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
