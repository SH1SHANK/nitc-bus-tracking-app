import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_dropdown.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/onboarding_provider.dart';

/// Step 4: Academic profile — Batch selection with Attendrix aesthetic.
class OnboardingStepBatch extends StatelessWidget {
  const OnboardingStepBatch({
    super.key,
    required this.selectedBatch,
    required this.onBatchChanged,
    required this.onContinue,
  });

  final String selectedBatch;
  final ValueChanged<String> onBatchChanged;
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
          const SizedBox(height: TrackletSpacing.md),

          // Header
          Text(
            "Let's Set Up Your Academic Profile",
            style: TrackletTypography.displayLarge.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: TrackletColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle with Attendrix link
          RichText(
            text: TextSpan(
              style: TrackletTypography.bodySmall.copyWith(
                color: TrackletColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
              children: [
                const TextSpan(
                  text: 'Select your batch year so we can sync your timetable and bus schedules with your academic calendar. ',
                ),
                TextSpan(
                  text: 'Tap to Learn More.',
                  style: const TextStyle(
                    color: TrackletColors.tertiary,
                    fontWeight: FontWeight.w800,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Batch settings configure exam schedules and rush hour bus alerts.',
                          ),
                          backgroundColor: TrackletColors.primary,
                        ),
                      );
                    },
                ),
              ],
            ),
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Form Label
          Text(
            'Which batch do you belong to?',
            style: TrackletTypography.titleSmall.copyWith(
              color: TrackletColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          TrackletDropdown(
            items: kNitcBatches,
            initialItem: selectedBatch.isNotEmpty ? selectedBatch : null,
            hintText: 'Select Batch',
            isValid: selectedBatch.isNotEmpty,
            onChanged: (val) => onBatchChanged(val ?? ''),
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Quick Selection Grid
          Text(
            'Undergraduate Batches',
            style: TrackletTypography.labelSmall.copyWith(
              color: TrackletColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TrackletSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['B21', 'B22', 'B23', 'B24', 'B25'].map((batch) {
              final isSelected = selectedBatch.startsWith(batch);

              return ChoiceChip(
                label: Text(batch),
                selected: isSelected,
                selectedColor: TrackletColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : TrackletColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                backgroundColor: TrackletColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(
                  color: isSelected
                      ? TrackletColors.primary
                      : TrackletColors.border,
                  width: 1.5,
                ),
                onSelected: (selected) {
                  if (selected) {
                    final fullBatch = kNitcBatches.firstWhere(
                      (b) => b.startsWith(batch),
                      orElse: () => batch,
                    );
                    onBatchChanged(fullBatch);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: TrackletSpacing.xxl * 1.5),

          // Continue Button
          TrackletButton(
            label: 'Continue',
            icon: const TrackletIcon(
              TrackletIcons.chevronRight,
              color: TrackletColors.textInverse,
              size: 18,
            ),
            isFullWidth: true,
            size: TrackletButtonSize.large,
            onPressed: selectedBatch.isNotEmpty ? onContinue : null,
          ),
          const SizedBox(height: TrackletSpacing.lg),
        ],
      ),
    );
  }
}
