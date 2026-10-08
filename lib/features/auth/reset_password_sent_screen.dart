import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/icons/tracklet_icon.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

/// Authentic Attendrix Reset Password Sent confirmation screen.
class ResetPasswordSentScreen extends StatelessWidget {
  const ResetPasswordSentScreen({super.key, this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrackletColors.primaryBackground,
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
              const SizedBox(height: 80.0),

              // Mail Icon / Illustration Container
              Align(
                    alignment: AlignmentDirectional.center,
                    child: Container(
                      width: 140.0,
                      height: 140.0,
                      decoration: BoxDecoration(
                        color: TrackletColors.background2,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: TrackletColors.primary.withValues(alpha: 0.2),
                          width: 3.0,
                        ),
                      ),
                      child: const Center(
                        child: TrackletIcon(
                          TrackletIcons.notifications,
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
                        color: TrackletColors.primaryText,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Your reset request is on its way!\n',
                          style: TrackletTypography.titleMedium.copyWith(
                            color: TrackletColors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(
                          text: 'It might be hiding in Promotions or Spam,\nso don’t forget to check there. \n',
                          style: TextStyle(color: TrackletColors.secondaryText),
                        ),
                        const TextSpan(
                          text: 'Still missing? No worries \n Just hit ',
                          style: TextStyle(color: TrackletColors.secondaryText),
                        ),
                        TextSpan(
                          text: '‘Resend’ ',
                          style: TrackletTypography.bodyMedium.copyWith(
                            color: TrackletColors.tertiary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(
                          text: 'and we’ve got you covered.',
                          style: TextStyle(color: TrackletColors.secondaryText),
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
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: 'Didn’t show up? ',
                      style: TrackletTypography.bodyMedium.copyWith(
                        color: TrackletColors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: 'Resend Mail',
                      style: TrackletTypography.bodyMedium.copyWith(
                        color: TrackletColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                      mouseCursor: SystemMouseCursors.click,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'A New Mail has Been Sent Successfully!',
                                style: TextStyle(
                                  color: TrackletColors.info,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              duration: Duration(milliseconds: 4000),
                              backgroundColor: TrackletColors.success,
                            ),
                          );
                        },
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
                        backgroundColor: TrackletColors.primaryText,
                        foregroundColor: TrackletColors.primaryBackground,
                        elevation: 3.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            TrackletRadii.button,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Back to Login',
                        style: TrackletTypography.titleSmall.copyWith(
                          color: TrackletColors.primaryBackground,
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
