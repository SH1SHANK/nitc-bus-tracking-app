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

/// Step 3: Academic profile — Branch selection with Attendrix aesthetic.
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

          // Attendrix Subtitle with RichText link
          RichText(
            text: TextSpan(
              style: TrackletTypography.bodySmall.copyWith(
                color: TrackletColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
              children: [
                const TextSpan(
                  text:
                      'Tell us a few details about your academic profile so we can personalize your timetable, courses, and campus shuttle experience. Why do we ask for this information? ',
                ),
                TextSpan(
                  text: 'Tap to Learn More.',
                  style: const TextStyle(
                    color: TrackletColors.tertiary,
                    fontWeight: FontWeight.w800,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Branch information helps prioritize bus stops near your department buildings.',
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
            'Which branch do you belong to?',
            style: TrackletTypography.titleSmall.copyWith(
              color: TrackletColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          TrackletDropdown(
            items: kNitcBranches,
            initialItem: selectedBranch.isNotEmpty ? selectedBranch : null,
            hintText: 'Select Branch',
            prefixIcon: const Icon(
              Icons.account_tree_outlined,
              color: TrackletColors.secondaryText,
              size: 20,
            ),
            isValid: selectedBranch.isNotEmpty,
            onChanged: (val) => onBranchChanged(val ?? ''),
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Quick Selection Chips
          Text(
            'Quick Select',
            style: TrackletTypography.labelSmall.copyWith(
              color: TrackletColors.textSecondary,
              fontWeight: FontWeight.w700,
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
                      color:
                          isSelected
                              ? Colors.white
                              : TrackletColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    backgroundColor: TrackletColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(
                      color:
                          isSelected
                              ? TrackletColors.primary
                              : TrackletColors.border,
                      width: 1.5,
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
