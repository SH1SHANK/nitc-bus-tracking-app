import 'package:flutter/material.dart';

/// Tracklet core and transit semantic color tokens matching Attendrix styling.
abstract final class TrackletColors {
  // Brand / Core Palette (Attendrix Signature)
  static const Color primary = Color(0xFF6F61EF);
  static const Color primaryPressed = Color(0xFF5A4CD6);
  static const Color primaryContainer = Color(0xFFEFEFFD);
  static const Color primaryContainerDark = Color(0xFF262445);
  static const Color onPrimaryContainer = Color(0xFF4536C6);
  static const Color onPrimaryContainerDark = Color(0xFFD4CEFB);
  static const Color primaryDark = Color(0xFF8B7EF8);

  static const Color secondary = Color(0xFF39D2C0);
  static const Color secondaryPressed = Color(0xFF28B5A4);
  static const Color secondaryContainer = Color(0xFFE2F9F5);
  static const Color secondaryContainerDark = Color(0xFF143834);
  static const Color onSecondaryContainer = Color(0xFF0F6E63);
  static const Color onSecondaryContainerDark = Color(0xFF8CEBE0);

  static const Color tertiary = Color(0xFFEE8B60);
  static const Color tertiaryText = Color(0xFF9C4A25);
  static const Color tertiaryContainer = Color(0xFFFDF0EA);
  static const Color tertiaryContainerDark = Color(0xFF3E2317);
  static const Color onTertiaryContainer = Color(0xFF9C4A25);
  static const Color onTertiaryContainerDark = Color(0xFFF7C2AA);

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
  static const Color surfaceContainer = Color(0xFFF7F8FA);
  static const Color surfaceContainerHigh = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color cardBorder = Color(0xFFE0E3E7);
  static const Color inputBorder = Color(0xFFCAC0C0);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color pure = Color(0xFFFFFFFF);

  // Dark Palette Surfaces & Text Tokens
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF161922);
  static const Color darkSurfaceElevated = Color(0xFF1F2430);
  static const Color darkSurfaceContainer = Color(0xFF1B1F2A);
  static const Color darkSurfaceContainerHigh = Color(0xFF232836);
  static const Color darkSurfaceContainerHighest = Color(0xFF2B3242);
  static const Color darkSurfaceContainerLowest = Color(0xFF0B0D12);
  static const Color darkBorder = Color(0xFF232836);
  static const Color darkCardBorder = Color(0xFF2A3040);
  static const Color darkInputBorder = Color(0xFF3B4254);
  static const Color darkDivider = Color(0xFF232836);
  static const Color darkTextPrimary = Color(0xFFF1F4F8);
  static const Color darkTextSecondary = Color(0xFF9098A9);
  static const Color darkTextMuted = Color(0xFF687082);

  // Adaptive Theme Helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color adaptiveBackground(BuildContext context) =>
      isDark(context) ? darkBackground : background;

  static Color adaptiveSurface(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color adaptiveSurfaceElevated(BuildContext context) =>
      isDark(context) ? darkSurfaceElevated : surfaceElevated;

  static Color adaptiveSurfaceContainer(BuildContext context) =>
      isDark(context) ? darkSurfaceContainer : surfaceContainer;

  static Color adaptiveBorder(BuildContext context) =>
      isDark(context) ? darkBorder : border;

  static Color adaptiveCardBorder(BuildContext context) =>
      isDark(context) ? darkCardBorder : cardBorder;

  static Color adaptiveInputBorder(BuildContext context) =>
      isDark(context) ? darkInputBorder : inputBorder;

  static Color adaptiveDivider(BuildContext context) =>
      isDark(context) ? darkDivider : divider;

  static Color adaptiveTextPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color adaptiveTextSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color adaptiveTextMuted(BuildContext context) =>
      isDark(context) ? darkTextMuted : textTertiary;

  // Text Tokens
  static const Color textPrimary = Color(0xFF15161E);
  static const Color primaryText = Color(0xFF15161E);
  static const Color altPrimaryText = Color(0xFF14181B);
  static const Color textSecondary = Color(0xFF606A85);
  static const Color secondaryText = Color(0xFF57636C);
  static const Color textTertiary = Color(0xFF9098A9);
  static const Color textDisabled = Color(0xFFB5BAC4);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color info = Color(0xFF3B82F6);

  // Status & Feedback
  static const Color success = Color(0xFF03C03C);
  static const Color successContainer = Color(0xFFE6F9ED);
  static const Color successContainerDark = Color(0xFF0D2E18);
  static const Color onSuccessContainer = Color(0xFF027A26);
  static const Color onSuccessContainerDark = Color(0xFF6EE7B7);

  static const Color alternateSuccess = Color(0xFF05FA2F);
  static const Color presentGreen = Color(0xFF37D437);
  static const Color absentRed = Color(0xFFE44D2E);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningGold = Color(0xFFFFD700);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color warningContainerDark = Color(0xFF382405);
  static const Color onWarningContainer = Color(0xFF92400E);
  static const Color onWarningContainerDark = Color(0xFFFDE68A);
  static const Color warningStrong = Color(0xFFF39C12);

  static const Color error = Color(0xFFFF5963);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color errorContainerDark = Color(0xFF381417);
  static const Color onErrorContainer = Color(0xFFC5222E);
  static const Color onErrorContainerDark = Color(0xFFFFB4AB);
  static const Color errorBorder = Color(0xFFFE3E00);
  static const Color dangerSurface = Color(0xFFFFEBEE);
  static const Color dangerInputSurface = Color(0xFFFFF5F5);

  static const Color infoContainer = Color(0xFFEFF6FF);
  static const Color infoContainerDark = Color(0xFF112642);
  static const Color onInfoContainer = Color(0xFF1E40AF);
  static const Color onInfoContainerDark = Color(0xFF93C5FD);

  static const Color disabled = Color(0xFFBDC2C8);
  static const Color scrim = Color(0x33000000);

  // Accents & Alpha Tints
  static const Color accent1 = Color(0x4D9489F5);
  static const Color accent2 = Color(0x4C39D2C0);
  static const Color accent3 = Color(0x4CEE8B60);
  static const Color accent4 = Color(0x9AFFFFFF);

  // Extended UI Accents
  static const Color permissionBlueBg = Color(0xFFEFF6FF);
  static const Color permissionBlueBgDark = Color(0xFF1E293B);
  static const Color permissionBlueIcon = Color(0xFF3B82F6);
  static const Color permissionPinkBg = Color(0xFFFDF2F8);
  static const Color permissionPinkBgDark = Color(0xFF2E1A29);
  static const Color permissionPinkIcon = Color(0xFFEC4899);
  static const Color permissionGreenBg = Color(0xFFD1FAE5);
  static const Color permissionGreenBgDark = Color(0xFF132D24);
  static const Color permissionGreenText = Color(0xFF065F46);
  static const Color permissionGreenTextDark = Color(0xFF6EE7B7);
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
  static const Color mapCanvasDark = Color(0xFF12141C);
  static const Color mapLand = Color(0xFFF7F5F0);
  static const Color mapLandDark = Color(0xFF161922);
  static const Color mapBuilding = Color(0xFFE5E0D6);
  static const Color mapBuildingDark = Color(0xFF252B3A);
  static const Color mapBuildingOutline = Color(0xFFC9C2B7);
  static const Color mapBuildingOutlineDark = Color(0xFF333B4F);
  static const Color mapRoad = Color(0xFFD4CFC5);
  static const Color mapRoadDark = Color(0xFF1E2330);
  static const Color mapBuildingLabel = Color(0xFF514F4A);
  static const Color mapBuildingLabelDark = Color(0xFF9098A9);
  static const Color mapStopLabel = Color(0xFF68645E);
  static const Color mapStopLabelDark = Color(0xFFA6AFBF);
  static const Color mapRouteStopLabel = Color(0xFF574BC6);
  static const Color mapSelectedStopLabel = Color(0xFF4338A8);

  // Transit Semantic Tokens
  static const Color busLive = Color(0xFF03C03C);
  static const Color busLiveBg = Color(0xFFE6F9ED);
  static const Color busLiveBgDark = Color(0xFF0D2E18);
  static const Color busLiveTextDark = Color(0xFF4ADE80);

  static const Color busDelayed = Color(0xFFEE8B60);
  static const Color busDelayedBg = Color(0xFFFDF2EB);
  static const Color busDelayedBgDark = Color(0xFF331C13);
  static const Color busDelayedTextDark = Color(0xFFFDBA74);

  static const Color busDue = Color(0xFF6F61EF);
  static const Color busDueBg = Color(0xFFF2F1FF);
  static const Color busDueBgDark = Color(0xFF1E1A3C);
  static const Color busDueTextDark = Color(0xFFA59CF8);

  static const Color busOffline = Color(0xFF606A85);
  static const Color busOfflineBg = Color(0xFFF1F4F8);
  static const Color busOfflineBgDark = Color(0xFF1F2430);
  static const Color busOfflineTextDark = Color(0xFF9098A9);

  static const Color routeActive = Color(0xFF6F61EF);
  static const Color stopActive = Color(0xFF6F61EF);

  /// Authoritative fallback route color when dynamic Supabase route color is unavailable.
  static const Color routeDefault = Color(0xFF64748B);
  static const Color routeDefaultBg = Color(0xFFF1F5F9);
  static const Color routeDefaultBgDark = Color(0xFF1E293B);

  // Onboarding gradient stops
  static const List<Color> onboardingGradientLight = [
    Color(0xFFFAFBFF),
    Color(0xFFEAE8F9),
    Color(0xFFB5B1E7),
  ];
  static const List<Color> onboardingGradientDark = [
    Color(0xFF161922),
    Color(0xFF1B1A33),
    Color(0xFF221F45),
  ];

  // Header and Card gradient stops
  static const Color headerGradientStart = Color(0xFFE5F1FF);
  static const Color headerGradientStartDark = Color(0xFF1B1A33);
  static const Color headerGradientEnd = Color(0xFFF1F4F8);
  static const Color headerGradientEndDark = Color(0xFF0F1117);

  // Adaptive Status Helpers
  static Color adaptiveStatusBg(
    BuildContext context, {
    required bool isLive,
    bool isDelayed = false,
    bool isDue = false,
    bool isOffline = false,
  }) {
    final dark = isDark(context);
    if (isLive) return dark ? busLiveBgDark : busLiveBg;
    if (isDelayed) return dark ? busDelayedBgDark : busDelayedBg;
    if (isDue) return dark ? busDueBgDark : busDueBg;
    return dark ? busOfflineBgDark : busOfflineBg;
  }

  static Color adaptiveStatusText(
    BuildContext context, {
    required bool isLive,
    bool isDelayed = false,
    bool isDue = false,
    bool isOffline = false,
  }) {
    final dark = isDark(context);
    if (isLive) return dark ? busLiveTextDark : busLive;
    if (isDelayed) return dark ? busDelayedTextDark : busDelayed;
    if (isDue) return dark ? busDueTextDark : busDue;
    return dark ? busOfflineTextDark : busOffline;
  }
}
