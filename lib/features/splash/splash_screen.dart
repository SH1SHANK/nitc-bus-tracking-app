import 'dart:math' as math;

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

/// Dedicated animated BusTracker splash screen with fluid, immersive motion design.
///
/// Animation Architecture:
/// 1. Native Handoff: Seamless transition from native splash via `FlutterNativeSplash.remove()`.
/// 2. Fluid Ambient Aura: Continuous breathing radial glow and expanding radar pulse waves.
/// 3. Aerodynamic Bus Entrance: Scale, pitch, and deceleration with pneumatic suspension bounce.
/// 4. Coordinated Lockup Reveal: Horizontal realignment, wordmark masked slide & shimmer.
/// 5. Route Line Genesis: Animated glowing vector path tracing the campus transit line.
/// 6. Typographic Hierarchy: "NITC CAMPUS TRANSIT" tracking expansion with status capsule.
/// 7. Handoff Exit: Smooth zoom-and-fade exit dispatching to destination route.
class BusTrackerSplashScreen extends ConsumerStatefulWidget {
  const BusTrackerSplashScreen({super.key});

  @override
  ConsumerState<BusTrackerSplashScreen> createState() =>
      _BusTrackerSplashScreenState();
}

class _BusTrackerSplashScreenState extends ConsumerState<BusTrackerSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _timelineController;
  late final AnimationController _ambientController;

  // Staged timeline animations
  late final Animation<double> _busEntranceX;
  late final Animation<double> _busScale;
  late final Animation<double> _busFade;
  late final Animation<double> _busTilt;
  late final Animation<double> _busBounceY;
  late final Animation<double> _busSlide;

  late final Animation<double> _wordmarkFade;
  late final Animation<Offset> _wordmarkSlide;
  late final Animation<double> _wordmarkScale;

  late final Animation<double> _routeLineProgress;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  late final Animation<double> _statusFade;
  late final Animation<Offset> _statusSlide;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Dismiss native splash as soon as first Flutter frame paints
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        FlutterNativeSplash.remove();
      } catch (_) {
        // Silently ignore in test harnesses or unsupported environments
      }
    });

    // 1. Continuous ambient controller for breathing aura & live beacon pulse
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    // 2. Main staged choreography timeline
    _timelineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Stage A: Aerodynamic Entrance (0% -> 32%)
    _busEntranceX = Tween<double>(begin: -80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.00, 0.32, curve: Curves.easeOutCubic),
      ),
    );
    _busScale = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.00, 0.32, curve: Curves.easeOutBack),
      ),
    );
    _busFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.00, 0.22, curve: Curves.easeIn),
      ),
    );
    _busTilt = Tween<double>(begin: -0.06, end: 0.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.00, 0.32, curve: Curves.easeOutQuad),
      ),
    );

    // Stage B: Suspension settling with damped pneumatic rebound (32% -> 48%)
    _busBounceY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: -5.0,
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 38,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -5.0,
          end: 2.5,
        ).chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 34,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 2.5,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 28,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.32, 0.48),
      ),
    );

    // Stage C: Bus slides slightly left to balance the horizontal lockup (40% -> 66%)
    _busSlide = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.40, 0.66, curve: Curves.easeInOutCubic),
      ),
    );

    // Stage D: Wordmark reveal (46% -> 76%)
    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.46, 0.74, curve: Curves.easeOut),
      ),
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0.14, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.46, 0.76, curve: Curves.easeOutCubic),
      ),
    );
    _wordmarkScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.46, 0.76, curve: Curves.easeOutCubic),
      ),
    );

    // Stage E: Glowing Route Line Drawing & Subtitle Reveal (58% -> 84%)
    _routeLineProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.56, 0.82, curve: Curves.easeInOutCubic),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.60, 0.84, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.60, 0.84, curve: Curves.easeOutCubic),
      ),
    );

    // Stage F: Bottom Status capsule reveal (66% -> 88%)
    _statusFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.66, 0.88, curve: Curves.easeOut),
      ),
    );
    _statusSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.66, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    // Stage G: Timeline completion dispatches target navigation
    _timelineController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tryDispatchNavigation();
      }
    });

    _timelineController.forward();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  void _tryDispatchNavigation() {
    if (_hasNavigated || !mounted) return;

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (!_timelineController.isCompleted && !disableAnimations) {
      return;
    }

    final authState = ref.read(authNotifierProvider);
    final profileAsync = ref.read(profileStateProvider);

    // Hold splash if initial cold-start auth state is resolving
    if (authState.status == AuthStatus.uninitialized) {
      return;
    }

    if (authState.status == AuthStatus.passwordRecoveryInProgress) {
      _hasNavigated = true;
      context.go('/reset-password');
      return;
    }

    final bool isGuest = authState.isGuest;
    if (!authState.isAuthenticated ||
        (!isGuest && !isNitcEmail(authState.email))) {
      _hasNavigated = true;
      context.go('/login');
      return;
    }

    // For authenticated students, wait until profile finishes loading
    if (!isGuest && profileAsync.isLoading) {
      return;
    }

    _hasNavigated = true;
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

    final brandPrimary =
        isDark ? TrackletColors.primaryDark : TrackletColors.primary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Fluid Ambient Background Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        isDark
                            ? TrackletColors.onboardingGradientDark
                            : TrackletColors.onboardingGradientLight,
                  ),
                ),
              ),
            ),

            // 2. Animated Ambient Radar/Aura Glow behind the Center Lockup
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _AmbientAuraPainter(
                      progress: _ambientController.value,
                      isDark: isDark,
                      primaryColor: brandPrimary,
                    ),
                  );
                },
              ),
            ),

            // 3. Central Brand Lockup & Coordinated Presentation
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TrackletSpacing.screenMargin,
                ),
                child: AnimatedBuilder(
                  animation: _timelineController,
                  builder: (context, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Primary Lockup: Bus Icon + BusTracker Wordmark
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Bus Icon with Entrance, Aerodynamic Tilt & Rebound Bounce
                            Transform.translate(
                              offset: Offset(
                                _busEntranceX.value + _busSlide.value,
                                _busBounceY.value,
                              ),
                              child: Transform.rotate(
                                angle: _busTilt.value,
                                child: Transform.scale(
                                  scale: _busScale.value,
                                  child: Opacity(
                                    opacity: _busFade.value,
                                    child: Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: brandPrimary.withValues(
                                              alpha: isDark ? 0.35 : 0.22,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Image.asset(
                                        'assets/branding/bustracker_bus_icon.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: TrackletSpacing.md),

                            // BusTracker Wordmark with Masked Slide & Fade Reveal
                            SlideTransition(
                              position: _wordmarkSlide,
                              child: Transform.scale(
                                scale: _wordmarkScale.value,
                                child: FadeTransition(
                                  opacity: _wordmarkFade,
                                  child: SizedBox(
                                    height: 44,
                                    child: Image.asset(
                                      'assets/branding/bustracker_wordmark.png',
                                      fit: BoxFit.contain,
                                      color: isDark ? Colors.white : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: TrackletSpacing.lg),

                        // Glowing Transit Route Line Vector
                        SizedBox(
                          width: 180,
                          height: 12,
                          child: CustomPaint(
                            painter: _TransitRouteTracePainter(
                              progress: _routeLineProgress.value,
                              color: brandPrimary,
                              isDark: isDark,
                            ),
                          ),
                        ),

                        const SizedBox(height: TrackletSpacing.sm),

                        // Typographic Subtitle: "NITC CAMPUS TRANSIT"
                        SlideTransition(
                          position: _taglineSlide,
                          child: FadeTransition(
                            opacity: _taglineFade,
                            child: Text(
                              'NITC CAMPUS TRANSIT',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3.2,
                                color:
                                    isDark
                                        ? TrackletColors.darkTextSecondary
                                        : TrackletColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // 4. Sleek Status Capsule Pinned at Bottom Safe Area
            Positioned(
              left: 0,
              right: 0,
              bottom: 38,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _timelineController,
                  _ambientController,
                ]),
                builder: (context, _) {
                  return SlideTransition(
                    position: _statusSlide,
                    child: FadeTransition(
                      opacity: _statusFade,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? TrackletColors.darkSurfaceContainer
                                          .withValues(alpha: 0.75)
                                      : Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: brandPrimary.withValues(
                                  alpha: isDark ? 0.30 : 0.18,
                                ),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.25 : 0.05,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Pulsing Emerald Live Indicator
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: TrackletColors.success.withValues(
                                      alpha:
                                          0.5 +
                                          0.5 *
                                              math
                                                  .sin(
                                                    _ambientController.value *
                                                        2 *
                                                        math.pi,
                                                  )
                                                  .abs(),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: TrackletColors.success
                                            .withValues(alpha: 0.6),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Live Campus Fleet System',
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark
                                            ? TrackletColors.darkTextPrimary
                                            : TrackletColors.textPrimary,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'National Institute of Technology Calicut',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark
                                      ? TrackletColors.darkTextMuted
                                      : TrackletColors.textTertiary,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter rendering a soft ambient breathing halo and concentric transit pulses.
class _AmbientAuraPainter extends CustomPainter {
  const _AmbientAuraPainter({
    required this.progress,
    required this.isDark,
    required this.primaryColor,
  });

  final double progress;
  final bool isDark;
  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 20);

    // 1. Breathing central radial aura
    final auraRadius = 140.0 + 20.0 * math.sin(progress * 2 * math.pi);
    final auraPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              primaryColor.withValues(alpha: isDark ? 0.22 : 0.14),
              primaryColor.withValues(alpha: isDark ? 0.08 : 0.05),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: auraRadius));
    canvas.drawCircle(center, auraRadius, auraPaint);

    // 2. Outward expanding radar ripple 1
    final ring1Progress = progress;
    final ring1Radius = 50.0 + ring1Progress * 110.0;
    final ring1Alpha =
        (1.0 - ring1Progress).clamp(0.0, 1.0) * (isDark ? 0.18 : 0.12);
    final ring1Paint =
        Paint()
          ..color = primaryColor.withValues(alpha: ring1Alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    canvas.drawCircle(center, ring1Radius, ring1Paint);

    // 3. Outward expanding radar ripple 2 (delayed phase)
    final ring2Progress = (progress + 0.5) % 1.0;
    final ring2Radius = 50.0 + ring2Progress * 110.0;
    final ring2Alpha =
        (1.0 - ring2Progress).clamp(0.0, 1.0) * (isDark ? 0.15 : 0.10);
    final ring2Paint =
        Paint()
          ..color = primaryColor.withValues(alpha: ring2Alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
    canvas.drawCircle(center, ring2Radius, ring2Paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientAuraPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.primaryColor != primaryColor;
  }
}

/// Custom painter animating a glowing route trace path with terminal stop beacons.
class _TransitRouteTracePainter extends CustomPainter {
  const _TransitRouteTracePainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  final double progress;
  final Color color;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final centerY = size.height / 2;
    const startX = 10.0;
    final endX = size.width - 10.0;
    final totalWidth = endX - startX;
    final currentX = startX + totalWidth * progress;

    // Background track line (faint)
    final trackPaint =
        Paint()
          ..color = color.withValues(alpha: isDark ? 0.15 : 0.10)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(startX, centerY), Offset(endX, centerY), trackPaint);

    // Active progressive trace line
    final activePaint =
        Paint()
          ..shader = LinearGradient(
            colors: [color.withValues(alpha: 0.3), color],
          ).createShader(Rect.fromLTRB(startX, 0, currentX, size.height))
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(startX, centerY),
      Offset(currentX, centerY),
      activePaint,
    );

    // Origin Stop Beacon (Stationary)
    final originPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(startX, centerY), 3.0, originPaint);

    // Moving Bus / Route Head Beacon
    final headGlowPaint =
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(currentX, centerY), 5.5, headGlowPaint);
    canvas.drawCircle(Offset(currentX, centerY), 3.2, originPaint);

    // Terminal Stop Beacon (lights up as progress nears end)
    if (progress > 0.85) {
      final terminalAlpha = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);
      final terminalPaint =
          Paint()
            ..color = color.withValues(alpha: terminalAlpha)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(endX, centerY), 3.0, terminalPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TransitRouteTracePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}
