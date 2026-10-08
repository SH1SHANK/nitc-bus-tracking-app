import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/icons/tracklet_icon.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import 'providers/onboarding_provider.dart';
import 'widgets/onboarding_academic_profile_page.dart';
import 'widgets/onboarding_progress_bar.dart';
import 'widgets/onboarding_step_loading.dart';
import 'widgets/onboarding_step_permissions.dart';
import 'widgets/onboarding_step_username.dart';
import 'widgets/onboarding_step_welcome.dart';

/// Streamlined Onboarding Experience matching Attendrix Layout.
/// 0: Welcome / Sign In
/// 1: Academic Profile (All-in-One)
/// 2: Username with Magic Wand Generator
/// 3: Combined Permissions (Location & Notifications)
/// 4: Final Welcome & Loading Sequence -> Home
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  static const int kTotalSteps = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    ref.read(onboardingProvider.notifier).setStep(step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  void _next() {
    final current = ref.read(onboardingProvider).currentStep;
    final next = current + 1;
    _goToStep(next);

    // If entering the final loading step (step 4), kick off initialization sequence
    if (next == 4) {
      ref
          .read(onboardingProvider.notifier)
          .runInitializationSequence(
            onComplete: () {
              if (mounted) {
                context.go('/');
              }
            },
          );
    }
  }

  void _previous() {
    final current = ref.read(onboardingProvider).currentStep;
    if (current > 0) {
      _goToStep(current - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    final showTopNav = state.currentStep > 0 && state.currentStep < 4;

    return Scaffold(
      backgroundColor: TrackletColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Progress Bar
            if (showTopNav) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TrackletSpacing.md,
                  vertical: TrackletSpacing.xs,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const TrackletIcon(
                            TrackletIcons.chevronLeft,
                            size: 22,
                            color: TrackletColors.textPrimary,
                          ),
                          onPressed: _previous,
                          tooltip: 'Back',
                        ),
                        const Spacer(),
                        Text(
                          'Step ${state.currentStep} of $kTotalSteps',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TrackletColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: TrackletSpacing.sm),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: OnboardingProgressBar(
                        currentStep: state.currentStep - 1,
                        totalSteps: kTotalSteps,
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: TrackletSpacing.sm),

            // Page Sequence
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // 0. Welcome / Sign In Entry
                  OnboardingStepWelcome(
                    onGetStarted: _next,
                    onSignIn: () => context.push('/login'),
                  ),

                  // 1. All-in-One Academic Profile (Name, Branch, Batch, Hostel)
                  OnboardingAcademicProfilePage(
                    name: state.name,
                    branch: state.branch,
                    batch: state.batch,
                    hostel: state.hostel,
                    onNameChanged: (n) => notifier.setName(n),
                    onBranchChanged: (b) => notifier.setBranch(b),
                    onBatchChanged: (b) => notifier.setBatch(b),
                    onHostelChanged: (h) => notifier.setHostel(h),
                    onContinue: _next,
                  ),

                  // 2. Username with Attendrix Gradient & Magic Generator
                  OnboardingStepUsername(
                    initialUsername: state.username,
                    isAvailable: state.isUsernameAvailable,
                    onUsernameChanged: (u) => notifier.updateUsername(u),
                    onMagicWandPressed: () => notifier.generateRandomUsername(),
                    onContinue: _next,
                  ),

                  // 3. Combined Permissions (Location & Notifications)
                  OnboardingStepPermissions(
                    locationGranted: state.locationPermissionGranted,
                    notificationsGranted: state.notificationPermissionGranted,
                    onEnablePermissions: ({
                      required bool enableLocation,
                      required bool enableNotifications,
                    }) async {
                      notifier.setLocationPermission(enableLocation);
                      notifier.setNotificationPermission(enableNotifications);
                      _next();
                    },
                    onSkip: () {
                      notifier.setLocationPermission(false);
                      notifier.setNotificationPermission(false);
                      _next();
                    },
                  ),

                  // 4. Final Welcome & Animated Loading Sequence (`flow.gif`)
                  OnboardingStepLoading(
                    progress: state.loadingProgress,
                    statusText: state.loadingStatus,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
