import 'package:flutter/widgets.dart';

/// Centralized motion tokens defining standardized durations, curves, and transitions
/// for the Tracklet application according to flutter-animating-apps guidelines.
abstract final class TrackletMotion {
  // Standard Durations
  /// 150ms: Quick micro-interactions (choice chips, button states, icon toggles).
  static const Duration fast = Duration(milliseconds: 150);

  /// 180ms: Tactile micro-interactions (tab switch scale bounce, button compression).
  static const Duration micro = Duration(milliseconds: 180);

  /// 220ms: Shell tab branch transitions.
  static const Duration tabSwitch = Duration(milliseconds: 220);

  /// 240ms: Standard component transitions (sheets, banners, switchers).
  static const Duration standard = Duration(milliseconds: 240);

  /// 320ms: Medium transitions (page route transitions, marker heading updates).
  static const Duration medium = Duration(milliseconds: 320);

  /// 480ms: Slow coordinated transitions (complex layout reorganizations).
  static const Duration slow = Duration(milliseconds: 480);

  /// 650ms: Splash brand reveal animation.
  static const Duration splash = Duration(milliseconds: 650);

  /// 1200ms: Skeleton breathing pulse.
  static const Duration pulse = Duration(milliseconds: 1200);

  /// 1600ms: Ambient shimmer gradient cycle.
  static const Duration shimmer = Duration(milliseconds: 1600);

  // Standard Easing Curves
  /// Fast out, slow in. Natural deceleration for entering elements.
  static const Curve easeOut = Curves.easeOutCubic;

  /// Slow out, fast in. Natural acceleration for exiting elements.
  static const Curve easeIn = Curves.easeInCubic;

  /// Symmetrical easing for elements moving between states.
  static const Curve standardCurve = Curves.easeInOutCubic;

  /// Smooth gentle curve for continuous loops.
  static const Curve smooth = Curves.easeInOut;

  /// Tactile spring curve with natural overshoot for taps and toggles.
  static const Curve spring = Curves.easeOutBack;

  /// Resolves a duration respecting the system or user's reduced-motion preference.
  static Duration adaptiveDuration(
    BuildContext context,
    Duration targetDuration,
  ) {
    return MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : targetDuration;
  }
}
