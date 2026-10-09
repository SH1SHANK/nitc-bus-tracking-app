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

/// Streamlined Onboarding Experience matching Attendrix Layout.
/// 0: Academic Profile (Name, Branch, Batch, Hostel)
/// 1: Username with Magic Wand Generator
/// 2: Combined Permissions (Location & Notifications)
/// 3: Final Welcome & Loading Sequence -> Home
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  static const int kTotalSteps = 4;

  @override
  void initState() {
    super.initState();
    final currentStep = ref.read(onboardingProvider).currentStep;
    final initialPage =
        currentStep >= 0 && currentStep < kTotalSteps ? currentStep : 0;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    ref.read(onboardingProvider.notifier).setStep(step);
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(step);
      return;
    }

    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  void _next() {
    final current = ref.read(onboardingProvider).currentStep;
    if (current >= kTotalSteps - 1) return;

    final next = current + 1;
    _goToStep(next);

    if (next == kTotalSteps - 1) {
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
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    final showBackButton = state.currentStep < kTotalSteps - 1;

    return PopScope<Object?>(
      canPop: state.currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop &&
            state.currentStep > 0 &&
            state.currentStep < kTotalSteps - 1) {
          _previous();
        }
      },
      child: Scaffold(
        backgroundColor: TrackletColors.background,
        body: DecoratedBox(
          decoration:
              state.currentStep == 1
                  ? const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFAFBFF),
                        Color(0xFFEAE8F9),
                        Color(0xFFB5B1E7),
                      ],
                      stops: [0, 0.43, 1],
                    ),
                  )
                  : const BoxDecoration(color: TrackletColors.background),
          child: SafeArea(
            child: Column(
              children: [
                // The username step uses the reference's clean segmented header.
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        state.currentStep == 1
                            ? TrackletSpacing.lg
                            : TrackletSpacing.md,
                    vertical: TrackletSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      if (state.currentStep != 1) ...[
                        Row(
                          children: [
                            if (showBackButton)
                              IconButton(
                                icon: const TrackletIcon(
                                  TrackletIcons.chevronLeft,
                                  size: 22,
                                  color: TrackletColors.textPrimary,
                                ),
                                onPressed: _previous,
                                tooltip: 'Back',
                              )
                            else
                              const SizedBox(width: 48, height: 48),
                            const Spacer(),
                            Text(
                              showBackButton
                                  ? 'Step ${state.currentStep + 1} of $kTotalSteps'
                                  : 'Setting up Tracklet',
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
                      ],
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: state.currentStep == 1 ? 0 : 12,
                        ),
                        child: OnboardingProgressBar(
                          currentStep: state.currentStep,
                          totalSteps: kTotalSteps,
                        ),
                      ),
                    ],
                  ),
                ),

                // Page Sequence
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // 0. Academic Profile (Name, Branch, Batch, Hostel)
                      OnboardingAcademicProfilePage(
                        name: state.name,
                        branch: state.branch,
                        batch: state.batch,
                        hostel: state.hostel,
                        agreedToTerms: state.agreedToTerms,
                        onNameChanged: (n) => notifier.setName(n),
                        onBranchChanged: (b) => notifier.setBranch(b),
                        onBatchChanged: (b) => notifier.setBatch(b),
                        onHostelChanged: (h) => notifier.setHostel(h),
                        onAgreementChanged: notifier.toggleTerms,
                        onContinue: _next,
                      ),

                      // 1. Username with Attendrix Gradient & Magic Generator
                      OnboardingStepUsername(
                        initialUsername: state.username,
                        isAvailable: state.isUsernameAvailable,
                        isCheckingUsername: state.isCheckingUsername,
                        onUsernameChanged: (u) => notifier.updateUsername(u),
                        onMagicWandPressed:
                            () => notifier.generateRandomUsername(),
                        onContinue: _next,
                      ),

                      // 2. Combined Permissions (Location & Notifications)
                      OnboardingStepPermissions(
                        locationGranted: state.locationPermissionGranted,
                        notificationsGranted:
                            state.notificationPermissionGranted,
                        onEnablePermissions: ({
                          required bool enableLocation,
                          required bool enableNotifications,
                        }) async {
                          notifier.setLocationPermission(enableLocation);
                          notifier.setNotificationPermission(
                            enableNotifications,
                          );
                          _next();
                        },
                        onSkip: () {
                          notifier.setLocationPermission(false);
                          notifier.setNotificationPermission(false);
                          _next();
                        },
                      ),

                      // 3. Final Welcome & Animated Loading Sequence (`flow.gif`)
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
        ),
      ),
    );
  }
}
