import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Step 1: Playful Welcome screen with 3D character hero and vibrant introductory branding.
class OnboardingStepWelcome extends StatelessWidget {
  const OnboardingStepWelcome({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.screenMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: TrackletSpacing.sm),

          // 3D Character Hero inside playful curved backdrop
          Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEDE9FE), Color(0xFFF3F4F6)],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft glow circle
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TrackletColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                Image.asset(
                  'assets/images/Young_Man_Laptop_Clean_Login_Design.png',
                  fit: BoxFit.contain,
                  height: 240,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/images/Young_Man_with_Laptop.png',
                    fit: BoxFit.contain,
                    height: 240,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.directions_bus_rounded,
                      size: 100,
                      color: TrackletColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TrackletSpacing.xl),

          // App Title & Tagline
          Text(
            'Welcome to Tracklet',
            style: TrackletTypography.displayLarge.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TrackletSpacing.xs),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
            ).createShader(bounds),
            child: Text(
              'Transit, Reimagined.',
              style: TrackletTypography.headlineLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: TrackletSpacing.md),
          Text(
            'Built for NITC campus transit, live shuttle tracking, timetables, and everything in between.',
            style: TrackletTypography.bodyLarge.copyWith(
              color: TrackletColors.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TrackletSpacing.xxl),

          // Primary Actions
          TrackletButton(
            label: 'Get Started',
            icon: const TrackletIcon(
              TrackletIcons.chevronRight,
              color: TrackletColors.textInverse,
              size: 18,
            ),
            isFullWidth: true,
            size: TrackletButtonSize.large,
            onPressed: onGetStarted,
          ),
          const SizedBox(height: TrackletSpacing.md),

          // Secondary Google / SSO Auth action
          Material(
            color: const Color(0xFF1E293B),
            borderRadius: TrackletRadii.roundedMd,
            child: InkWell(
              onTap: onSignIn,
              borderRadius: TrackletRadii.roundedMd,
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: TrackletSpacing.md),
                    Text(
                      'Continue with NITC Google Account',
                      style: TrackletTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: TrackletSpacing.xl),
        ],
      ),
    );
  }
}
