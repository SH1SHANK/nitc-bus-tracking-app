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

/// Step 3: Academic profile — Branch selection inspired by the screenshot design.
class OnboardingStepBranch extends StatelessWidget {
  const OnboardingStepBranch({
    super.key,
    required this.selectedBranch,
    required this.onBranchChanged,
    required this.onContinue,
  });

  final String selectedBranch;
  final ValueChanged<String> onBranchChanged;
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
            "Let's Set Up Your Academic Profile",
            style: TrackletTypography.displayLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: TrackletSpacing.xs),
          const Text(
            'Tell us a few details about your academic profile so we can personalize your timetable, lecture halls, and shuttle routes.',
            style: TrackletTypography.bodyMedium,
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Label
          Text(
            'Which branch do you belong to?',
            style: TrackletTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: TrackletColors.textPrimary,
            ),
          ),
          const SizedBox(height: TrackletSpacing.xs),

          // Dropdown Card
          InkWell(
            onTap: () {
              OnboardingSelectionSheet.show(
                context: context,
                title: 'Select Branch',
                subtitle: 'Choose your academic department at NIT Calicut',
                items: kNitcBranches,
                selectedItem: selectedBranch,
                onSelected: onBranchChanged,
                showSearch: true,
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
                    TrackletIcons.route,
                    color: TrackletColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: TrackletSpacing.md),
                  Expanded(
                    child: Text(
                      selectedBranch.isNotEmpty ? selectedBranch : 'Branch',
                      style: TrackletTypography.titleMedium.copyWith(
                        fontWeight: selectedBranch.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selectedBranch.isNotEmpty
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

          // Quick Selection Chips
          Text(
            'Quick Select',
            style: TrackletTypography.labelSmall.copyWith(
              color: TrackletColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TrackletSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                  'Computer Science & Engineering',
                  'Electronics & Communication Engineering',
                  'Electrical & Electronics Engineering',
                  'Mechanical Engineering',
                  'Architecture & Planning',
                ].map((branch) {
                  final isSelected = selectedBranch == branch;
                  final shortName = switch (branch) {
                    'Computer Science & Engineering' => 'CSE',
                    'Electronics & Communication Engineering' => 'ECE',
                    'Electrical & Electronics Engineering' => 'EEE',
                    'Mechanical Engineering' => 'MECH',
                    'Architecture & Planning' => 'ARCH',
                    _ => branch,
                  };

                  return ChoiceChip(
                    label: Text(shortName),
                    selected: isSelected,
                    selectedColor: TrackletColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : TrackletColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    backgroundColor: TrackletColors.surface,
                    side: BorderSide(
                      color: isSelected
                          ? TrackletColors.primary
                          : TrackletColors.border,
                    ),
                    onSelected: (selected) {
                      if (selected) onBranchChanged(branch);
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
            onPressed: selectedBranch.isNotEmpty ? onContinue : null,
          ),
          const SizedBox(height: TrackletSpacing.lg),
        ],
      ),
    );
  }
}
