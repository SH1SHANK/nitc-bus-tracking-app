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

/// Step 5: Academic profile — Semester selection.
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
          const SizedBox(height: TrackletSpacing.lg),

          // Header
          Text(
            "What's Your Current Semester?",
            style: TrackletTypography.displayLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: TrackletSpacing.xs),
          const Text(
            'Personalizes your academic timetable, ELHC/NLHC lecture hall schedules, and morning bus alerts.',
            style: TrackletTypography.bodyMedium,
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // Dropdown Card
          InkWell(
            onTap: () {
              OnboardingSelectionSheet.show(
                context: context,
                title: 'Select Semester',
                subtitle: 'Choose your ongoing semester session',
                items: kNitcSemesters,
                selectedItem: selectedSemester,
                onSelected: onSemesterChanged,
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
                    TrackletIcons.time,
                    color: TrackletColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: TrackletSpacing.md),
                  Expanded(
                    child: Text(
                      selectedSemester.isNotEmpty
                          ? selectedSemester
                          : 'Semester',
                      style: TrackletTypography.titleMedium.copyWith(
                        fontWeight: selectedSemester.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selectedSemester.isNotEmpty
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

          // Grid of Semesters (1 through 8)
          Text(
            'Quick Select Semester',
            style: TrackletTypography.labelSmall.copyWith(
              color: TrackletColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TrackletSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
            ),
            itemBuilder: (context, index) {
              final semNum = index + 1;
              final session = semNum % 2 == 1 ? 'Monsoon' : 'Winter';
              final semName = 'Semester $semNum ($session)';
              final isSelected = selectedSemester.startsWith(
                'Semester $semNum',
              );

              return InkWell(
                onTap: () => onSemesterChanged(semName),
                borderRadius: TrackletRadii.roundedMd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
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
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? TrackletColors.primary
                              : TrackletColors.surfaceElevated,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$semNum',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : TrackletColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sem $semNum',
                              style: TrackletTypography.titleMedium.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? TrackletColors.primary
                                    : TrackletColors.textPrimary,
                              ),
                            ),
                            Text(
                              session,
                              style: TrackletTypography.labelSmall.copyWith(
                                fontSize: 10,
                                color: TrackletColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
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
            onPressed: selectedSemester.isNotEmpty ? onContinue : null,
          ),
          const SizedBox(height: TrackletSpacing.lg),
        ],
      ),
    );
  }
}
