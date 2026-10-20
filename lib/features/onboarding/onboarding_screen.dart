import 'package:tracklet/design_system/tokens/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/icons/tracklet_icon.dart';
import '../../design_system/components/icons/tracklet_icons.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/tracklet_fonts.dart';
import '../../design_system/tokens/spacing.dart';
import 'providers/onboarding_provider.dart';
import 'widgets/onboarding_progress_bar.dart';
import 'widgets/onboarding_step_loading.dart';
import 'widgets/onboarding_step_username.dart';

/// Streamlined Onboarding Experience:
/// 0: Choose Username with Magic Wand Generator
/// 1: Final Welcome & Loading Sequence -> Home
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  bool _isCompleting = false;
  String? _completionError;

  static const int kTotalSteps = 2;

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
    if (current >= kTotalSteps - 1 || _isCompleting) return;

    final next = current + 1;
    _goToStep(next);

    if (next == kTotalSteps - 1) {
      _startCompletion();
    }
  }

  void _startCompletion() {
    setState(() {
      _isCompleting = true;
      _completionError = null;
    });
    ref
        .read(onboardingProvider.notifier)
        .runInitializationSequence(
          onComplete: () {
            if (mounted) {
              context.go('/');
            }
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _isCompleting = false;
              _completionError = error;
            });
          },
        );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope<Object?>(
      canPop: state.currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop &&
            state.currentStep > 0 &&
            state.currentStep < kTotalSteps - 1 &&
            !_isCompleting) {
          _previous();
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? TrackletColors.darkBackground : TrackletColors.background,
        body: DecoratedBox(
          decoration: BoxDecoration(
            color:
                isDark
                    ? TrackletColors.darkBackground
                    : TrackletColors.background,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top navigation & progress bar (visible on username step)
                if (state.currentStep == 0) ...[
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
                              'Step 1 of $kTotalSteps',
                              style: TrackletFonts.outfit(
                                fontSize: TrackletTypography.fontSize13,
                                fontWeight: TrackletTypography.weightSemiBold,
                                color: TrackletColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: TrackletSpacing.sm),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: TrackletSpacing.md,
                          ),
                          child: OnboardingProgressBar(
                            currentStep: 0,
                            totalSteps: kTotalSteps,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Page Sequence: Username -> Welcome
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // 0. Choose Your Username
                      OnboardingStepUsername(
                        initialUsername: state.username,
                        isAvailable: state.isUsernameAvailable,
                        isCheckingUsername: state.isCheckingUsername,
                        validationError: state.usernameValidationError,
                        onUsernameChanged: (u) => notifier.updateUsername(u),
                        onMagicWandPressed:
                            () => notifier.generateRandomUsername(),
                        onContinue: _next,
                      ),

                      // 1. Final Welcome & Animated Loading Sequence (`flow.gif`)
                      OnboardingStepLoading(
                        progress: state.loadingProgress,
                        statusText: state.loadingStatus,
                        errorMessage: _completionError,
                        onRetry:
                            _completionError == null
                                ? null
                                : () {
                                  _startCompletion();
                                },
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
