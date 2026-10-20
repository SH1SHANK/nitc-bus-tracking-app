import 'package:flutter/material.dart';

import 'colors.dart';

/// Tracklet typography hierarchy based on Outfit (Primary) and Satoshi (Secondary).
///
/// Owns font families, semantic scales, line heights, letter spacings,
/// and tabular numeric presentations aligned with Attendrix design standards.
abstract final class TrackletTypography {
  /// Primary font family used for UI headers, display, navigation, and body.
  static const double letterSpacingSubtle = 0.2;
  static const double letterSpacingCompact = 0.4;
  static const double letterSpacingLabel = 0.5;
  static const double letterSpacingEmphasis = 0.7;
  static const double letterSpacingWide = 0.8;
  static const double letterSpacingExpanded = 1.0;
  static const double letterSpacingTight = -0.2;
  static const double letterSpacingTitle = -0.3;
  static const double letterSpacingDense = -0.35;
  static const double letterSpacingHeading = -0.45;
  static const double letterSpacingDisplay = -0.6;
  static const double letterSpacingDisplayLarge = -0.7;

  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;
  static const FontWeight weightExtraBold = FontWeight.w800;
  static const FontWeight weightBlack = FontWeight.w900;

  static const double lineHeightLoading = 1.12;
  static const double lineHeightTight = 1.2;
  static const double lineHeightDense = 1.25;
  static const double lineHeightCompact = 1.3;
  static const double lineHeightBodyCompact = 1.35;
  static const double lineHeightBody = 1.4;
  static const double lineHeightBodyRelaxed = 1.45;
  static const double lineHeightRelaxed = 1.5;

  static const String primaryFontFamily = 'Outfit';

  /// Secondary font family used for subtitles, badges, and complementary copy.
  static const String secondaryFontFamily = 'Satoshi';

  // Primitive font-size scale (logical text pixels).
  static const double fontSize9 = 9;
  static const double fontSize10 = 10;
  static const double fontSize10_5 = 10.5;
  static const double fontSize11 = 11;
  static const double fontSize11_5 = 11.5;
  static const double fontSize12 = 12;
  static const double fontSize12_5 = 12.5;
  static const double fontSize13 = 13;
  static const double fontSize13_5 = 13.5;
  static const double fontSize14 = 14;
  static const double fontSize14_5 = 14.5;
  static const double fontSize15 = 15;
  static const double fontSize16 = 16;
  static const double fontSize17 = 17;
  static const double fontSize18 = 18;
  static const double fontSize19 = 19;
  static const double fontSize20 = 20;
  static const double fontSize22 = 22;
  static const double fontSize24 = 24;
  static const double fontSize26 = 26;
  static const double fontSize28 = 28;
  static const double fontSize32 = 32;
  static const double fontSize34 = 34;
  static const double fontSize45 = 45;
  static const double fontSize57 = 57;

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
    fontSize: fontSize57,
    fontWeight: weightRegular,
    letterSpacing: -0.5,
    height: 1.15,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize45,
    fontWeight: weightRegular,
    letterSpacing: -0.4,
    height: 1.18,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize34,
    fontWeight: weightSemiBold,
    letterSpacing: 0.0,
    height: 1.22,
    color: TrackletColors.textPrimary,
  );

  // ===========================================================================
  // HEADLINE STYLES (Outfit)
  // ===========================================================================

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize32,
    fontWeight: weightRegular,
    letterSpacing: -0.2,
    height: lineHeightDense,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize24,
    fontWeight: weightMedium,
    letterSpacing: -0.2,
    height: lineHeightCompact,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize22,
    fontWeight: weightBold,
    letterSpacing: -0.1,
    height: 1.32,
    color: TrackletColors.textPrimary,
  );

  // ===========================================================================
  // TITLE STYLES (Outfit)
  // ===========================================================================

  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize22,
    fontWeight: weightMedium,
    letterSpacing: -0.1,
    height: lineHeightBodyCompact,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize18,
    fontWeight: weightMedium,
    letterSpacing: 0.0,
    height: lineHeightBody,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize16,
    fontWeight: weightMedium,
    letterSpacing: 0.0,
    height: lineHeightBody,
    color: TrackletColors.textPrimary,
  );

  // ===========================================================================
  // LABEL STYLES (Outfit & Satoshi)
  // ===========================================================================

  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize16,
    fontWeight: weightMedium,
    letterSpacing: 0.0,
    height: lineHeightBodyCompact,
    color: TrackletColors.textSecondary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize14,
    fontWeight: weightMedium,
    letterSpacing: 0.0,
    height: lineHeightBodyCompact,
    color: TrackletColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize12,
    fontWeight: weightMedium,
    letterSpacing: 0.0,
    height: lineHeightCompact,
    color: TrackletColors.textSecondary,
  );

  // ===========================================================================
  // BODY STYLES (Outfit & Satoshi)
  // ===========================================================================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: secondaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize16,
    fontWeight: weightMedium,
    letterSpacing: 0.0,
    height: lineHeightRelaxed,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize14,
    fontWeight: weightRegular,
    letterSpacing: 0.0,
    height: lineHeightBodyRelaxed,
    color: TrackletColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: secondaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize12,
    fontWeight: weightRegular,
    letterSpacing: 0.0,
    height: lineHeightBody,
    color: TrackletColors.textSecondary,
  );

  // ===========================================================================
  // CAPTION STYLES (Satoshi)
  // ===========================================================================

  static const TextStyle caption = TextStyle(
    fontFamily: secondaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize11,
    fontWeight: weightRegular,
    letterSpacing: 0.2,
    height: lineHeightCompact,
    color: TrackletColors.textSecondary,
  );

  static const TextStyle captionSmall = TextStyle(
    fontFamily: secondaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize10,
    fontWeight: weightRegular,
    letterSpacing: 0.2,
    height: lineHeightDense,
    color: TrackletColors.textSecondary,
  );

  // ===========================================================================
  // NUMERIC STYLES (Tabular Figures for ETAs, Bus Numbers, Timetables)
  // ===========================================================================

  /// Large tabular numeric display for countdowns and primary ETAs.
  static const TextStyle numericLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize28,
    fontWeight: weightBold,
    letterSpacing: -0.4,
    height: lineHeightTight,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    color: TrackletColors.textPrimary,
  );

  /// Medium tabular numeric display for bus numbers, route badges, and stop ETAs.
  static const TextStyle numericMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize20,
    fontWeight: weightBold,
    letterSpacing: -0.2,
    height: lineHeightDense,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    color: TrackletColors.textPrimary,
  );

  /// Standard tabular numeric text for departure times and coordinates.
  static const TextStyle numericSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: fontSize14,
    fontWeight: weightSemiBold,
    height: lineHeightBodyCompact,
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

  // ===========================================================================
  // COMPLETE MATERIAL 3 TEXT THEMES
  // ===========================================================================

  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );

  static final TextTheme darkTextTheme = TextTheme(
    displayLarge: displayLarge.copyWith(color: TrackletColors.darkTextPrimary),
    displayMedium: displayMedium.copyWith(
      color: TrackletColors.darkTextPrimary,
    ),
    displaySmall: displaySmall.copyWith(color: TrackletColors.darkTextPrimary),
    headlineLarge: headlineLarge.copyWith(
      color: TrackletColors.darkTextPrimary,
    ),
    headlineMedium: headlineMedium.copyWith(
      color: TrackletColors.darkTextPrimary,
    ),
    headlineSmall: headlineSmall.copyWith(
      color: TrackletColors.darkTextPrimary,
    ),
    titleLarge: titleLarge.copyWith(color: TrackletColors.darkTextPrimary),
    titleMedium: titleMedium.copyWith(color: TrackletColors.darkTextPrimary),
    titleSmall: titleSmall.copyWith(color: TrackletColors.darkTextPrimary),
    bodyLarge: bodyLarge.copyWith(color: TrackletColors.darkTextPrimary),
    bodyMedium: bodyMedium.copyWith(color: TrackletColors.darkTextPrimary),
    bodySmall: bodySmall.copyWith(color: TrackletColors.darkTextSecondary),
    labelLarge: labelLarge.copyWith(color: TrackletColors.darkTextSecondary),
    labelMedium: labelMedium.copyWith(color: TrackletColors.darkTextSecondary),
    labelSmall: labelSmall.copyWith(color: TrackletColors.darkTextSecondary),
  );

  // ===========================================================================
  // CONTEXT-ADAPTIVE HELPERS
  // ===========================================================================

  static TextStyle adaptive(
    BuildContext context,
    TextStyle style, {
    Color? lightColor,
    Color? darkColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isDark
            ? (darkColor ?? TrackletColors.darkTextPrimary)
            : (lightColor ?? TrackletColors.textPrimary);
    return style.copyWith(color: color);
  }

  static TextStyle adaptiveSecondary(BuildContext context, TextStyle style) {
    return adaptive(
      context,
      style,
      lightColor: TrackletColors.textSecondary,
      darkColor: TrackletColors.darkTextSecondary,
    );
  }
}
