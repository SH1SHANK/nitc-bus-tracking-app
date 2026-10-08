import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Step 10 & 11: Final animated loading screen with dynamic progress updates and transition.
class OnboardingStepLoading extends StatelessWidget {
  const OnboardingStepLoading({
    super.key,
    required this.progress,
    required this.statusText,
  });

  final double progress;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TrackletSpacing.screenMargin,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Main Title
            Text(
              'Welcome to Tracklet',
              style: TrackletTypography.displayLarge.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TrackletSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Transit, ',
                  style: TrackletTypography.headlineLarge.copyWith(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Reimagined.',
                  style: TrackletTypography.headlineLarge.copyWith(
                    color: TrackletColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TrackletSpacing.xs),
            Text(
              'Built for attendance, timetables, shuttles, and\neverything in between.',
              style: TrackletTypography.bodySmall.copyWith(
                color: const Color(0xFFF97316),
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(flex: 3),

            // Animated Glowing Center Visual (flow.gif)
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    TrackletColors.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/flow.gif',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 140,
                    height: 140,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFFEC4899),
                          Color(0xFF3B82F6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 4),

            // Status message
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⏳ ', style: TextStyle(fontSize: 14)),
                Flexible(
                  child: Text(
                    statusText,
                    style: TrackletTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: TrackletColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TrackletSpacing.md),

            // Smooth Progress Bar
            ClipRRect(
              borderRadius: TrackletRadii.roundedFull,
              child: SizedBox(
                height: 6,
                child: LinearProgressIndicator(
                  value: progress > 0.0 ? progress : null,
                  backgroundColor: TrackletColors.primary.withValues(
                    alpha: 0.15,
                  ),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    TrackletColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: TrackletSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
