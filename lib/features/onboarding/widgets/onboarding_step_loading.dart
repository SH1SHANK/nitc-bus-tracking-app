import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../design_system/tokens/colors.dart';
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

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFFAF9FF), Color(0xFFF3F7FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TrackletSpacing.screenMargin,
            ),
            child: Column(
              children: [
                SizedBox(height: isCompact ? 16 : 28),
                Text(
                  'Welcome to Tracklet',
                  textAlign: TextAlign.center,
                  style: TrackletTypography.displaySmall.copyWith(
                    fontSize: isCompact ? 28 : 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    height: 1.12,
                  ),
                ).enterOnboarding(context, delay: 40.ms),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TrackletTypography.headlineLarge.copyWith(
                      fontSize: isCompact ? 21 : 24,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
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
                  'Find campus buses and keep your next ride in reach.',
                  textAlign: TextAlign.center,
                  style: TrackletTypography.bodyMedium.copyWith(
                    color: TrackletColors.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ).enterOnboarding(context, delay: 150.ms),
                Expanded(
                  child: ClipRect(
                    child: Transform.scale(
                      scale: 1.28,
                      child: Image.asset(
                        'assets/images/Abstract_Gradient_Background_4K.jpg',
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    TrackletColors.permissionPinkIcon
                                        .withValues(alpha: 0.5),
                                    TrackletColors.velvetSky.withValues(
                                      alpha: 0.3,
                                    ),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                      ),
                    ).enterOnboarding(context, delay: 180.ms),
                  ),
                ),
                AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : 180.ms,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Row(
                    key: ValueKey(statusText),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.directions_bus_rounded,
                        color: TrackletColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          statusText,
                          textAlign: TextAlign.center,
                          style: TrackletTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: TrackletColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (errorMessage != null) ...[
                  Text(
                    'We could not save your setup. Check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: TrackletTypography.bodySmall.copyWith(
                      color: TrackletColors.errorBorder,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                  const SizedBox(height: 10),
                ],
                Semantics(
                  label: 'Tracklet setup progress',
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
