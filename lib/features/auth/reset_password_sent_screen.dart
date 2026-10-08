import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/icons/tracklet_icon.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/components/tracklet_button.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/typography.dart';

/// Authentic Attendrix Reset Password Sent confirmation screen.
class ResetPasswordSentScreen extends StatelessWidget {
  const ResetPasswordSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrackletColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Check / Success Icon Container
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: TrackletColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: TrackletIcon(
                    TrackletIcons.check,
                    color: TrackletColors.success,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Check Your Inbox!',
                textAlign: TextAlign.center,
                style: TrackletTypography.displayMedium.copyWith(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w800,
                  color: TrackletColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              const Text(
                'We have dispatched a magic password reset link to your campus email address. Tap the link to set up your new credentials.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.0,
                  color: TrackletColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 36),

              // Return to Login Button
              TrackletButton(
                label: 'Back to Sign In',
                isFullWidth: true,
                size: TrackletButtonSize.large,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
