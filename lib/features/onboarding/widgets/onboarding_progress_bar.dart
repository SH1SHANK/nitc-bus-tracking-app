import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';

/// Segmented progress for the three onboarding steps and final setup state.
class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 260);

    return Semantics(
      label: 'Onboarding progress',
      value: 'Step ${currentStep + 1} of $totalSteps',
      child: ExcludeSemantics(
        child: Row(
          children: List.generate(totalSteps, (index) {
            final isCompletedOrActive = index <= currentStep;
            final isActive = index == currentStep;

            return Expanded(
              flex: isActive ? 3 : 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeInOutCubic,
                  height: isActive ? 5 : 4,
                  decoration: BoxDecoration(
                    color: isCompletedOrActive
                        ? TrackletColors.primary
                        : TrackletColors.primary.withValues(alpha: 0.16),
                    borderRadius: TrackletRadii.roundedFull,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
