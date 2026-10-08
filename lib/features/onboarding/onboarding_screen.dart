import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/icons/tracklet_icon.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import 'providers/onboarding_provider.dart';
import 'widgets/onboarding_progress_bar.dart';
import 'widgets/onboarding_step_batch.dart';
import 'widgets/onboarding_step_branch.dart';
import 'widgets/onboarding_step_loading.dart';
import 'widgets/onboarding_step_location.dart';
import 'widgets/onboarding_step_name.dart';
import 'widgets/onboarding_step_notifications.dart';
import 'widgets/onboarding_step_semester.dart';
import 'widgets/onboarding_step_setup.dart';
import 'widgets/onboarding_step_username.dart';
import 'widgets/onboarding_step_welcome.dart';

/// Full interactive 11-step onboarding experience for Tracklet.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

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

    // If entering the final loading step, kick off initialization
    if (next == 9) {
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

    final showTopNav = state.currentStep > 0 && state.currentStep < 9;

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
                          'Step ${state.currentStep} of 8',
                          style: const TextStyle(
                            fontSize: 12,
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
                        totalSteps: 8,
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
                  // 1. Welcome
                  OnboardingStepWelcome(onGetStarted: _next, onSignIn: _next),

                  // 2. Academic profile — Name
                  OnboardingStepName(
                    initialName: state.name,
                    onContinue: (name) {
                      notifier.setName(name);
                      _next();
                    },
                  ),

                  // 3. Academic profile — Branch
                  OnboardingStepBranch(
                    selectedBranch: state.branch,
                    onBranchChanged: (b) => notifier.setBranch(b),
                    onContinue: _next,
                  ),

                  // 4. Academic profile — Batch
                  OnboardingStepBatch(
                    selectedBatch: state.batch,
                    onBatchChanged: (b) => notifier.setBatch(b),
                    onContinue: _next,
                  ),

                  // 5. Academic profile — Semester
                  OnboardingStepSemester(
                    selectedSemester: state.semester,
                    onSemesterChanged: (s) => notifier.setSemester(s),
                    onContinue: _next,
                  ),

                  // 6. Username
                  OnboardingStepUsername(
                    initialUsername: state.username,
                    isAvailable: state.isUsernameAvailable,
                    onUsernameChanged: (u) => notifier.updateUsername(u),
                    onMagicWandPressed: () => notifier.generateRandomUsername(),
                    onContinue: _next,
                  ),

                  // 7. Location permission
                  OnboardingStepLocation(
                    onEnableLocation: () {
                      notifier.setLocationPermission(true);
                      _next();
                    },
                    onSkip: () {
                      notifier.setLocationPermission(false);
                      _next();
                    },
                  ),

                  // 8. Notification permission
                  OnboardingStepNotifications(
                    onEnableNotifications: () {
                      notifier.setNotificationPermission(true);
                      _next();
                    },
                    onSkip: () {
                      notifier.setNotificationPermission(false);
                      _next();
                    },
                  ),

                  // 9. Optional setup / preferences
                  OnboardingStepSetup(
                    selectedHostel: state.hostel,
                    selectedStop: state.primaryStop,
                    agreedToTerms: state.agreedToTerms,
                    onHostelChanged: (h) => notifier.setHostel(h),
                    onStopChanged: (s) => notifier.setPrimaryStop(s),
                    onToggleTerms: (t) => notifier.toggleTerms(t),
                    onContinue: _next,
                  ),

                  // 10 & 11. Final welcome / loading & Transition into Home
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
