import 'dart:async';
import 'package:flutter/gestures.dart';
import '../../design_system/tokens/shadows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/components/tracklet_brand_lockup.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'providers/auth_provider.dart';

/// Authentic Attendrix Reset Password Sent confirmation screen with resend cooldown.
class ResetPasswordSentScreen extends ConsumerStatefulWidget {
  const ResetPasswordSentScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<ResetPasswordSentScreen> createState() =>
      _ResetPasswordSentScreenState();
}

class _ResetPasswordSentScreenState
    extends ConsumerState<ResetPasswordSentScreen> {
  int _cooldownSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _handleResend() async {
    if (_cooldownSeconds > 0) return;

    final targetEmail = widget.email ?? '';
    if (targetEmail.isNotEmpty) {
      await ref
          .read(authNotifierProvider.notifier)
          .sendPasswordRecovery(targetEmail);
    }

    _startCooldown();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Password reset link sent to your email.',
          style: TextStyle(
            color: TrackletColors.info,
            fontWeight: TrackletTypography.weightMedium,
          ),
        ),
        duration: Duration(milliseconds: 4000),
        backgroundColor: TrackletColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    final textPrimary = TrackletColors.adaptiveTextPrimary(context);
    final textSecondary = TrackletColors.adaptiveTextSecondary(context);

    return Scaffold(
      backgroundColor: TrackletColors.adaptiveBackground(context),
      body: SafeArea(
        top: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TrackletSpacing.screenMargin,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 48.0),

              // Brand Lockup
              TrackletBrandLockup(
                    logoSize: 42.0,
                    wordmarkHeight: 24.0,
                    isDark: isDark,
                  )
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                  ),

              const SizedBox(height: 32.0),

              // Mail Icon / Illustration Container
              Align(
                    alignment: AlignmentDirectional.center,
                    child: Container(
                      width: 140.0,
                      height: 140.0,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? TrackletColors.darkSurfaceElevated
                                : TrackletColors.background2,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: TrackletColors.primary.withValues(alpha: 0.2),
                          width: 3.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          TrackletIcons.mailCheck,
                          color: TrackletColors.primary,
                          size: 64.0,
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: TrackletSpacing.xl),

              // Main Notice RichText
              RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TrackletTypography.bodyMedium.copyWith(
                        color: textPrimary,
                        fontWeight: TrackletTypography.weightMedium,
                        height: TrackletTypography.lineHeightRelaxed,
                      ),
                      children: [
                        TextSpan(
                          text: 'Password reset link sent\n',
                          style: TrackletTypography.titleMedium.copyWith(
                            color: textPrimary,
                            fontWeight: TrackletTypography.weightBold,
                          ),
                        ),
                        TextSpan(
                          text:
                              'Check your inbox and spam folder for the password reset email.\n',
                          style: TextStyle(color: textSecondary),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: TrackletSpacing.md),

              // Resend CTA RichText
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TrackletTypography.bodyMedium.copyWith(
                    fontWeight: TrackletTypography.weightMedium,
                  ),
                  children: [
                    TextSpan(
                      text: 'Didn’t receive the email? ',
                      style: TrackletTypography.bodyMedium.copyWith(
                        color: textSecondary,
                        fontWeight: TrackletTypography.weightMedium,
                      ),
                    ),
                    TextSpan(
                      text:
                          _cooldownSeconds > 0
                              ? 'Resend in ${_cooldownSeconds}s'
                              : 'Resend',
                      style: TrackletTypography.bodyMedium.copyWith(
                        color:
                            _cooldownSeconds > 0
                                ? textSecondary
                                : TrackletColors.primary,
                        fontWeight: TrackletTypography.weightExtraBold,
                      ),
                      mouseCursor:
                          _cooldownSeconds > 0
                              ? SystemMouseCursors.basic
                              : SystemMouseCursors.click,
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap =
                                _cooldownSeconds > 0 ? null : _handleResend,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              const SizedBox(height: TrackletSpacing.xxl),

              // Return to Login Button
              SizedBox(
                    width: 257.0,
                    height: 44.0,
                    child: ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark
                                ? TrackletColors.primary
                                : TrackletColors.primaryText,
                        foregroundColor:
                            isDark
                                ? TrackletColors.textInverse
                                : TrackletColors.primaryBackground,
                        elevation: TrackletShadows.elevationLevel3,
                        shape: const RoundedRectangleBorder(
                          borderRadius: TrackletRadii.roundedButton,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Back to login',
                        style: TrackletTypography.titleSmall.copyWith(
                          color:
                              isDark
                                  ? TrackletColors.textInverse
                                  : TrackletColors.primaryBackground,
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 250.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }
}
