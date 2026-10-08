import 'package:flutter/widgets.dart';

/// Tracklet core and transit semantic color tokens.
abstract final class TrackletColors {
  // Brand / Core Palette
  static const Color primary = Color(0xFF0B6BCB);
  static const Color primaryPressed = Color(0xFF0955A6);
  static const Color secondary = Color(0xFF5B47C8);
  static const Color secondaryPressed = Color(0xFF4C3AA8);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Text Tokens
  static const Color textPrimary = Color(0xFF141414);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Transit Semantic Tokens
  static const Color busLive = Color(0xFF2E7D32);
  static const Color busLiveBg = Color(0xFFE8F5E9);

  static const Color busDelayed = Color(0xFFB45309);
  static const Color busDelayedBg = Color(0xFFFEF3C7);

  static const Color busDue = Color(0xFF6D28D9);
  static const Color busDueBg = Color(0xFFEDE9FE);

  static const Color busOffline = Color(0xFF6B7280);
  static const Color busOfflineBg = Color(0xFFF3F4F6);

  static const Color routeActive = Color(0xFF0B6BCB);
  static const Color stopActive = Color(0xFF0B6BCB);
}
