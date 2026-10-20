import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/motion.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import 'onboarding_entrance.dart';

/// Final welcome moment while Tracklet saves the new campus profile.
class OnboardingStepLoading extends StatelessWidget {
  const OnboardingStepLoading({
    super.key,
    required this.progress,
    required this.statusText,
    this.errorMessage,
    this.onRetry,
  });

  final double progress;
  final String statusText;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final normalizedProgress = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 620;
        final isDark = TrackletColors.isDark(context);
        final textPrimary = TrackletColors.adaptiveTextPrimary(context);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color:
                isDark
                    ? TrackletColors.darkBackground
                    : TrackletColors.background,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TrackletSpacing.screenMargin,
            ),
            child: Column(
              children: [
                SizedBox(height: isCompact ? 16 : 28),
                Text(
                  'Welcome to BusTracker',
                  textAlign: TextAlign.center,
                  style: TrackletTypography.adaptive(
                    context,
                    TrackletTypography.displaySmall,
                  ).copyWith(
                    fontSize: isCompact ? 28 : 32,
                    fontWeight: TrackletTypography.weightExtraBold,
                    letterSpacing: TrackletTypography.letterSpacingDisplayLarge,
                    height: TrackletTypography.lineHeightLoading,
                  ),
                ).enterOnboarding(context, delay: 40.ms),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TrackletTypography.adaptive(
                      context,
                      TrackletTypography.headlineLarge,
                    ).copyWith(
                      fontSize: isCompact ? 21 : 24,
                      fontWeight: TrackletTypography.weightExtraBold,
                      height: TrackletTypography.lineHeightTight,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Campus transit, ',
                        style: TextStyle(color: TrackletColors.success),
                      ),
                      TextSpan(
                        text: 'made simple.',
                        style: TextStyle(color: TrackletColors.primary),
                      ),
                    ],
                  ),
                ).enterOnboarding(context, delay: 100.ms),
                const SizedBox(height: 8),
                Text(
                  'View live campus buses and track arrival times.',
                  textAlign: TextAlign.center,
                  style: TrackletTypography.adaptiveSecondary(
                    context,
                    TrackletTypography.bodyMedium,
                  ).copyWith(
                    fontSize: TrackletTypography.fontSize14,
                    height: TrackletTypography.lineHeightBodyRelaxed,
                  ),
                ).enterOnboarding(context, delay: 150.ms),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: TrackletSpacing.sm,
                      ),
                      child: Image.asset(
                        'assets/images/flow.gif',
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: TrackletColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                      ),
                    ),
                  ).enterOnboarding(context, delay: 180.ms),
                ),
                AnimatedSwitcher(
                  duration: TrackletMotion.adaptiveDuration(
                    context,
                    TrackletMotion.fast,
                  ),
                  switchInCurve: TrackletMotion.easeOut,
                  switchOutCurve: TrackletMotion.easeIn,
                  child: Row(
                    key: ValueKey(statusText),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        TrackletIcons.bus,
                        color: TrackletColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          statusText,
                          textAlign: TextAlign.center,
                          style: TrackletTypography.titleSmall.copyWith(
                            fontWeight: TrackletTypography.weightSemiBold,
                            color: textPrimary,
                            fontSize: TrackletTypography.fontSize14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (errorMessage != null) ...[
                  Text(
                    'Could not save setup. Check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: TrackletTypography.bodySmall.copyWith(
                      color: TrackletColors.errorBorder,
                      fontWeight: TrackletTypography.weightSemiBold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(TrackletIcons.refreshCw),
                    label: const Text('Try again'),
                  ),
                  const SizedBox(height: 10),
                ],
                Semantics(
                  label: 'BusTracker setup progress',
                  value: '${(normalizedProgress * 100).round()} percent',
                  child: ClipRRect(
                    borderRadius: TrackletRadii.roundedFull,
                    child: SizedBox(
                      height: 8,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: normalizedProgress),
                        duration: reduceMotion ? Duration.zero : 300.ms,
                        curve: Curves.easeOutCubic,
                        builder:
                            (context, value, child) => LinearProgressIndicator(
                              value: value,
                              backgroundColor: TrackletColors.alternate,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                TrackletColors.primary,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 18 : 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
