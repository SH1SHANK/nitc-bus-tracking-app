import 'package:flutter/material.dart';

/// Tracklet core and transit semantic color tokens matching Attendrix styling.
abstract final class TrackletColors {
  // Brand / Core Palette (Attendrix Signature)
  static const Color primary = Color(0xFF6F61EF);
  static const Color primaryPressed = Color(0xFF5A4CD6);
  static const Color secondary = Color(0xFF39D2C0);
  static const Color secondaryPressed = Color(0xFF28B5A4);
  static const Color tertiary = Color(0xFFEE8B60);
  static const Color tertiaryText = Color(0xFF9C4A25);
  static const Color alternate = Color(0xFFE5E7EB);
  static const Color velvetSky = Color(0xFF7B6FF8);
  static const Color mintGreen = Color(0xFF6EE7B7);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF1F4F8);
  static const Color primaryBackground = Color(0xFFF1F4F8);
  static const Color secondaryBackground = Color(0xFFFFFFFF);
  static const Color background2 = Color(0xFFF2F1FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color cardBorder = Color(0xFFE0E3E7);
  static const Color inputBorder = Color(0xFFCAC0C0);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color pure = Color(0xFFFFFFFF);

  // Dark Palette Surfaces & Text Tokens
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF161922);
  static const Color darkSurfaceElevated = Color(0xFF1F2430);
  static const Color darkBorder = Color(0xFF232836);
  static const Color darkDivider = Color(0xFF232836);
  static const Color darkTextPrimary = Color(0xFFF1F4F8);
  static const Color darkTextSecondary = Color(0xFF9098A9);

  // Adaptive Theme Helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color adaptiveBackground(BuildContext context) =>
      isDark(context) ? darkBackground : background;

  static Color adaptiveSurface(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color adaptiveSurfaceElevated(BuildContext context) =>
      isDark(context) ? darkSurfaceElevated : surfaceElevated;

  static Color adaptiveBorder(BuildContext context) =>
      isDark(context) ? darkBorder : border;

  static Color adaptiveCardBorder(BuildContext context) =>
      isDark(context) ? darkBorder : cardBorder;

  static Color adaptiveDivider(BuildContext context) =>
      isDark(context) ? darkDivider : divider;

  static Color adaptiveTextPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color adaptiveTextSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  // Text Tokens
  static const Color textPrimary = Color(0xFF15161E);
  static const Color primaryText = Color(0xFF15161E);
  static const Color altPrimaryText = Color(0xFF14181B);
  static const Color textSecondary = Color(0xFF606A85);
  static const Color secondaryText = Color(0xFF57636C);
  static const Color textTertiary = Color(0xFF9098A9);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color info = Color(0xFFFFFFFF);

  // Status & Feedback
  static const Color success = Color(0xFF03C03C);
  static const Color alternateSuccess = Color(0xFF05FA2F);
  static const Color presentGreen = Color(0xFF37D437);
  static const Color absentRed = Color(0xFFE44D2E);
  static const Color warning = Color(0xFFFFD700);
  static const Color error = Color(0xFFFF5963);
  static const Color warningStrong = Color(0xFFF39C12);
  static const Color disabled = Color(0xFFBDC2C8);
  static const Color dangerSurface = Color(0xFFFFEBEE);
  static const Color dangerInputSurface = Color(0xFFFFF5F5);
  static const Color scrim = Color(0x33000000);
  static const Color errorBorder = Color(0xFFFE3E00);

  // Accents & Alpha Tints
  static const Color accent1 = Color(0x4D9489F5);
  static const Color accent2 = Color(0x4C39D2C0);
  static const Color accent3 = Color(0x4CEE8B60);
  static const Color accent4 = Color(0x9AFFFFFF);

  // Extended UI Accents
  static const Color permissionBlueBg = Color(0xFFEFF6FF);
  static const Color permissionBlueIcon = Color(0xFF3B82F6);
  static const Color permissionPinkBg = Color(0xFFFDF2F8);
  static const Color permissionPinkIcon = Color(0xFFEC4899);
  static const Color permissionGreenBg = Color(0xFFD1FAE5);
  static const Color permissionGreenText = Color(0xFF065F46);
  static const Color permissionHeaderGradientStart = Color(0xFF5AB2F7);
  static const Color permissionHeaderGradientEnd = Color(0xFF6F61EF);
  static const Color notificationYellowBg = Color(0xFFFEF3C7);
  static const Color notificationYellowBgLight = Color(0xFFFFFBEB);
  static const Color notificationAmber = Color(0xFFD97706);
  static const Color locationBlueBg = Color(0xFFE0F2FE);
  static const Color locationGreenBorder = Color(0xFFBBF7D0);
  static const Color locationGreenBg = Color(0xFFF0FDF4);
  static const Color locationGreenText = Color(0xFF16A34A);
  static const Color locationGreenDark = Color(0xFF15803D);

  // Campus map cartography tokens
  static const Color mapCanvas = Color(0xFFF7F5F0);
  static const Color mapLand = Color(0xFFF7F5F0);
  static const Color mapBuilding = Color(0xFFE5E0D6);
  static const Color mapBuildingOutline = Color(0xFFC9C2B7);
  static const Color mapRoad = Color(0xFFD4CFC5);
  static const Color mapBuildingLabel = Color(0xFF514F4A);
  static const Color mapStopLabel = Color(0xFF68645E);
  static const Color mapRouteStopLabel = Color(0xFF574BC6);
  static const Color mapSelectedStopLabel = Color(0xFF4338A8);

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
