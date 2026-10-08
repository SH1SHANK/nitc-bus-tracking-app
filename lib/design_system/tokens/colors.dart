import 'package:flutter/widgets.dart';

/// Tracklet core and transit semantic color tokens matching Attendrix styling.
abstract final class TrackletColors {
  // Brand / Core Palette (Attendrix Signature)
  static const Color primary = Color(0xFF6F61EF);
  static const Color primaryPressed = Color(0xFF5A4CD6);
  static const Color secondary = Color(0xFF39D2C0);
  static const Color secondaryPressed = Color(0xFF28B5A4);
  static const Color tertiary = Color(0xFFEE8B60);
  static const Color velvetSky = Color(0xFF7B6FF8);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF1F4F8);
  static const Color primaryBackground = Color(0xFFF1F4F8);
  static const Color secondaryBackground = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color alternate = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color pure = Color(0xFFFFFFFF);

  // Accents
  static const Color accent1 = Color(0x4D9489F5);
  static const Color accent2 = Color(0x4C39D2C0);
  static const Color accent3 = Color(0x4CEE8B60);
  static const Color accent4 = Color(0x9AFFFFFF);

  // Text Tokens
  static const Color textPrimary = Color(0xFF15161E);
  static const Color textSecondary = Color(0xFF606A85);
  static const Color textTertiary = Color(0xFF9098A9);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Semantic Status
  static const Color success = Color(0xFF03C03C);
  static const Color warning = Color(0xFFFFD700);
  static const Color error = Color(0xFFFF5963);

  // Transit Semantic Tokens
  static const Color busLive = Color(0xFF03C03C);
  static const Color busLiveBg = Color(0xFFE6F9ED);

  static const Color busDelayed = Color(0xFFEE8B60);
  static const Color busDelayedBg = Color(0xFFFDF2EB);

  static const Color busDue = Color(0xFF6F61EF);
  static const Color busDueBg = Color(0xFFF2F1FF);

  static const Color busOffline = Color(0xFF606A85);
  static const Color busOfflineBg = Color(0xFFF1F4F8);

  static const Color routeActive = Color(0xFF6F61EF);
  static const Color stopActive = Color(0xFF6F61EF);
}
