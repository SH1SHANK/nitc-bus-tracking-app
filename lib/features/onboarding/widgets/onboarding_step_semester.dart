import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/onboarding_provider.dart';
import 'onboarding_selection_sheet.dart';

/// Step 5: Academic profile — Semester selection with Attendrix aesthetic.
class OnboardingStepSemester extends StatelessWidget {
  const OnboardingStepSemester({
    super.key,
    required this.selectedSemester,
    required this.onSemesterChanged,
    required this.onContinue,
  });

  final String selectedSemester;
  final ValueChanged<String> onSemesterChanged;
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
                  text: 'Select your current semester to match your class timetable and campus bus departures accurately. ',
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
                            'Your semester dictates lecture slots and transit suggestions between main and east campus.',
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
            'Which semester are you in?',
            style: TrackletTypography.titleSmall.copyWith(
              color: TrackletColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Dropdown Container
          InkWell(
            onTap: () {
              OnboardingSelectionSheet.show(
                context: context,
                title: 'Select Semester',
                subtitle: 'Choose your active semester at NIT Calicut',
                items: kNitcSemesters,
                selectedItem: selectedSemester,
                onSelected: onSemesterChanged,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: TrackletColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedSemester.isNotEmpty
                      ? TrackletColors.primary
                      : TrackletColors.border,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedSemester.isNotEmpty
                          ? selectedSemester
                          : 'Semester',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: selectedSemester.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selectedSemester.isNotEmpty
                            ? TrackletColors.textPrimary
                            : TrackletColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: TrackletColors.textSecondary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Quick Selection Chips S1 - S8
          Text(
            'Undergraduate Semesters',
            style: TrackletTypography.labelSmall.copyWith(
              color: TrackletColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: TrackletSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'].map((
              sem,
            ) {
              final isSelected = selectedSemester.startsWith(sem);

              return ChoiceChip(
                label: Text(sem),
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
                    final fullSem = kNitcSemesters.firstWhere(
                      (s) => s.startsWith(sem),
                      orElse: () => sem,
                    );
                    onSemesterChanged(fullSem);
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
            onPressed: selectedSemester.isNotEmpty ? onContinue : null,
          ),
          const SizedBox(height: TrackletSpacing.lg),
        ],
      ),
    );
  }
}
