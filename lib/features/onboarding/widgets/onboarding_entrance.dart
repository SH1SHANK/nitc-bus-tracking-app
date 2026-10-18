import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../design_system/tokens/motion.dart';

/// A restrained, reduced-motion-aware entrance for onboarding content.
extension OnboardingEntrance on Widget {
  Widget enterOnboarding(
    BuildContext context, {
    Duration delay = Duration.zero,
  }) {
    if (MediaQuery.disableAnimationsOf(context)) return this;

    const duration = TrackletMotion.standard;
    return animate()
        .fadeIn(duration: duration, delay: delay)
        .slideY(
          begin: 0.035,
          end: 0,
          duration: duration,
          delay: delay,
          curve: TrackletMotion.easeOut,
        );
  }
}
