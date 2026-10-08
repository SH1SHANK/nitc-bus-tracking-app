import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';

/// Segmented top progress bar inspired by modern onboarding designs.
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
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompletedOrActive = index <= currentStep;
        final isActive = index == currentStep;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4.5,
              decoration: BoxDecoration(
                color: isCompletedOrActive
                    ? TrackletColors.primary
                    : TrackletColors.primary.withValues(alpha: 0.15),
                borderRadius: TrackletRadii.roundedFull,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: TrackletColors.primary.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}
