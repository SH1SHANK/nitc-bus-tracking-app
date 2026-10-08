import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Step 0: Authentic Attendrix-styled Welcome & Sign In screen with layered 3D character banner.
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
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top 40% height container with stacked Attendrix background banner & 3D character
          SizedBox(
            height: screenHeight * 0.38,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24.0),
                      bottomRight: Radius.circular(24.0),
                    ),
                    child: Image.asset(
                      'assets/images/Clean_Login_Design_Rectangle_10.png',
                      width: double.infinity,
                      height: 260.0,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 260.0,
                        color: TrackletColors.accent1,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0.0, 0.95),
                  child: Image.asset(
                    'assets/images/Young_Man_Laptop_Clean_Login_Design.png',
                    width: 240.0,
                    height: 240.0,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Image.asset(
                      'assets/images/Young_Man_with_Laptop.png',
                      width: 240.0,
                      height: 240.0,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.directions_bus_rounded,
                        size: 90,
                        color: TrackletColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TrackletSpacing.lg),

          // Bottom card with Attendrix typography & action buttons
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TrackletSpacing.screenMargin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Tracklet',
                  style: TrackletTypography.headlineLarge,
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Transit, Reimagined. Built for NITC campus transit, live shuttle tracking, timetables, and everything in between.',
                  style: TrackletTypography.bodyMedium.copyWith(
                    color: TrackletColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: TrackletSpacing.xxl),

                // Primary "Get Started" button
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

                // Secondary Google / SSO Auth action matching Attendrix
                Material(
                  color: const Color(0xFF15161E),
                  borderRadius: TrackletRadii.roundedMd,
                  child: InkWell(
                    onTap: onGetStarted,
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
                const SizedBox(height: TrackletSpacing.md),

                // Already have an account? Sign In
                Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF57636C),
                          ),
                        ),
                        TextSpan(
                          text: 'Sign In',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6F61EF),
                          ),
                          recognizer: TapGestureRecognizer()..onTap = onSignIn,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TrackletSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
