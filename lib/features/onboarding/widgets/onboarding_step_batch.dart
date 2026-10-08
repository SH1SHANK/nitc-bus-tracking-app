import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/onboarding_provider.dart';
import 'onboarding_selection_sheet.dart';

/// Step 4: Academic profile — Batch selection.
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
          const SizedBox(height: TrackletSpacing.lg),

          // Header
          Text(
            'Which Batch Do You Belong To?',
            style: TrackletTypography.displayLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: TrackletSpacing.xs),
          const Text(
            'Helps us coordinate year-specific campus transit timings and hostel dispersal shuttles.',
            style: TrackletTypography.bodyMedium,
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Dropdown Card
          InkWell(
            onTap: () {
              OnboardingSelectionSheet.show(
                context: context,
                title: 'Select Batch',
                subtitle: 'Choose your graduation year or degree program',
                items: kNitcBatches,
                selectedItem: selectedBatch,
                onSelected: onBatchChanged,
              );
            },
            borderRadius: TrackletRadii.roundedMd,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TrackletSpacing.md,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: TrackletColors.surface,
                borderRadius: TrackletRadii.roundedMd,
                border: Border.all(color: TrackletColors.border),
              ),
              child: Row(
                children: [
                  const TrackletIcon(
                    TrackletIcons.calendar,
                    color: TrackletColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: TrackletSpacing.md),
                  Expanded(
                    child: Text(
                      selectedBatch.isNotEmpty ? selectedBatch : 'Batch',
                      style: TrackletTypography.titleMedium.copyWith(
                        fontWeight: selectedBatch.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selectedBatch.isNotEmpty
                            ? TrackletColors.textPrimary
                            : TrackletColors.textTertiary,
                      ),
                    ),
                  ),
                  const TrackletIcon(
                    TrackletIcons.chevronDown,
                    color: TrackletColors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Visual Cards for Batches
          Text(
            'Select Program Year',
            style: TrackletTypography.labelSmall.copyWith(
              color: TrackletColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TrackletSpacing.sm),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kNitcBatches.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: TrackletSpacing.sm),
            itemBuilder: (context, index) {
              final batch = kNitcBatches[index];
              final isSelected = selectedBatch == batch;

              return InkWell(
                onTap: () => onBatchChanged(batch),
                borderRadius: TrackletRadii.roundedMd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TrackletSpacing.md,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? TrackletColors.primary.withValues(alpha: 0.08)
                        : TrackletColors.surface,
                    borderRadius: TrackletRadii.roundedMd,
                    border: Border.all(
                      color: isSelected
                          ? TrackletColors.primary
                          : TrackletColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? TrackletColors.primary
                              : TrackletColors.surfaceElevated,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : TrackletColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: TrackletSpacing.md),
                      Expanded(
                        child: Text(
                          batch,
                          style: TrackletTypography.titleMedium.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? TrackletColors.primary
                                : TrackletColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const TrackletIcon(
                          TrackletIcons.check,
                          color: TrackletColors.primary,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: TrackletSpacing.xxl),

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
