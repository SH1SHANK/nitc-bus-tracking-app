import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth/auth_state.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../auth/auth_validators.dart';
import '../auth/providers/auth_provider.dart';
import '../profile/providers/profile_provider.dart';

/// Minimalist, high-performance BusTracker splash screen.
///
/// Features ONLY the centered Bus Logo and Wordmark animating in and animating out.
class BusTrackerSplashScreen extends ConsumerStatefulWidget {
  const BusTrackerSplashScreen({super.key});

  @override
  ConsumerState<BusTrackerSplashScreen> createState() =>
      _BusTrackerSplashScreenState();
}

class _BusTrackerSplashScreenState extends ConsumerState<BusTrackerSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _hasNavigated = false;
  Timer? _safetyFallbackTimer;

  @override
  void initState() {
    super.initState();

    // Dismiss native splash as soon as the first Flutter frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        FlutterNativeSplash.remove();
      } catch (_) {
        // Silently ignore in test harnesses or unsupported platforms
      }
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Three-phase sequence: Animate in (35%), hold steady (35%), Animate out (30%)
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35.0,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 35.0),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 30.0,
      ),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.88,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35.0,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 35.0),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 30.0,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tryDispatchNavigation();
      }
    });

    // Safety fallback timer so splash never hangs indefinitely
    _safetyFallbackTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!_hasNavigated && mounted) {
        _tryDispatchNavigation(force: true);
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _safetyFallbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _tryDispatchNavigation({bool force = false}) {
    if (_hasNavigated || !mounted) return;

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (!force && !_controller.isCompleted && !disableAnimations) {
      return;
    }

    final authState = ref.read(authNotifierProvider);
    final profileAsync = ref.read(profileStateProvider);

    // Hold splash if initial cold-start auth state is still resolving and not forced
    if (!force && authState.status == AuthStatus.uninitialized) {
      return;
    }

    if (authState.status == AuthStatus.passwordRecoveryInProgress) {
      _hasNavigated = true;
      _safetyFallbackTimer?.cancel();
      context.go('/reset-password');
      return;
    }

    final bool isGuest = authState.isGuest;
    if (!authState.isAuthenticated ||
        (!isGuest && !isNitcEmail(authState.email))) {
      _hasNavigated = true;
      _safetyFallbackTimer?.cancel();
      context.go('/login');
      return;
    }

    // For authenticated students, wait until profile finishes loading unless forced
    if (!force && !isGuest && profileAsync.isLoading) {
      return;
    }

    _hasNavigated = true;
    _safetyFallbackTimer?.cancel();
    final profile = profileAsync.value;
    final bool onboardingComplete =
        isGuest || (profile?.hasCompletedOnboarding ?? false);

    if (!onboardingComplete) {
      context.go('/onboarding');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);

    // Listen to auth and profile changes to trigger navigation as soon as ready
    ref.listen(
      authNotifierProvider,
      (previous, next) => _tryDispatchNavigation(),
    );
    ref.listen(
      profileStateProvider,
      (previous, next) => _tryDispatchNavigation(),
    );

    // Handle accessibility reduced motion
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations && !_hasNavigated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryDispatchNavigation();
      });
    }

    final backgroundColor =
        isDark
            ? TrackletColors.darkBackground
            : TrackletColors.onboardingBackdropLight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Bus Emblem with natural transparency
                  Image.asset(
                    'assets/branding/bustracker_bus_icon.png',
                    width: 76,
                    height: 76,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),

                  const SizedBox(height: TrackletSpacing.lg),

                  // BusTracker Wordmark
                  SizedBox(
                    height: 26,
                    child: Image.asset(
                      'assets/branding/bustracker_wordmark.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      color: isDark ? TrackletColors.textInverse : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
