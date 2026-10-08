import 'package:flutter/material.dart';

import 'colors.dart';

/// Tracklet typography hierarchy based on Outfit (Primary) and Satoshi (Secondary).
///
/// Owns font families, semantic scales, line heights, letter spacings,
/// and tabular numeric presentations.
abstract final class TrackletTypography {
  /// Primary font family used for UI headers, display, navigation, and body.
  static const String primaryFontFamily = 'Outfit';

  /// Secondary font family used for subtitles, badges, and complementary copy.
  static const String secondaryFontFamily = 'Satoshi';

  /// Default font family fallback chain.
  static const List<String> fontFallbacks = <String>[
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'sans-serif',
  ];

  // ===========================================================================
  // DISPLAY STYLES (Outfit)
  // ===========================================================================

  static const TextStyle displayLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.22,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
    color: TrackletColors.textPrimary,
  );

  // ===========================================================================
  // HEADLINE STYLES (Outfit)
  // ===========================================================================

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.28,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
    color: TrackletColors.textPrimary,
  );

  // ===========================================================================
  // TITLE STYLES (Outfit)
  // ===========================================================================

  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: TrackletColors.textPrimary,
  );

  // ===========================================================================
  // BODY STYLES (Outfit)
  // ===========================================================================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: TrackletColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: TrackletColors.textSecondary,
  );

  // ===========================================================================
  // LABEL STYLES (Satoshi)
  // ===========================================================================

  static const TextStyle labelLarge = TextStyle(
    fontFamily: secondaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.35,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: secondaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.35,
    color: TrackletColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: secondaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.3,
    color: TrackletColors.textSecondary,
  );

  // ===========================================================================
  // CAPTION STYLES (Satoshi)
  // ===========================================================================

  static const TextStyle caption = TextStyle(
    fontFamily: secondaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.3,
    color: TrackletColors.textSecondary,
  );

  static const TextStyle captionSmall = TextStyle(
    fontFamily: secondaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.25,
    color: TrackletColors.textSecondary,
  );

  // ===========================================================================
  // NUMERIC STYLES (Tabular Figures for ETAs, Bus Numbers, Timetables)
  // ===========================================================================

  /// Large tabular numeric display for countdowns and primary ETAs.
  static const TextStyle numericLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.2,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    color: TrackletColors.textPrimary,
  );

  /// Medium tabular numeric display for bus numbers, route badges, and stop ETAs.
  static const TextStyle numericMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.25,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    color: TrackletColors.textPrimary,
  );

  /// Standard tabular numeric text for departure times and coordinates.
  static const TextStyle numericSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.35,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    color: TrackletColors.textPrimary,
  );

  /// Helper to convert any TextStyle into one with tabular figures enabled.
  static TextStyle withTabularFigures(TextStyle style) {
    final List<FontFeature> features = List<FontFeature>.from(
      style.fontFeatures ?? <FontFeature>[],
    );
    if (!features.contains(const FontFeature.tabularFigures())) {
      features.add(const FontFeature.tabularFigures());
    }
    return style.copyWith(fontFeatures: features);
  }
}
