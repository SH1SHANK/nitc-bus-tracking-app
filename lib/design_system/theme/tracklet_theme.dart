import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart' as md;

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Primary theme definition for Tracklet.
class TrackletTheme {
  const TrackletTheme._();

  static ThemeData get lightTheme {
    final textTheme = TextTheme(
      displayLarge: TrackletTypography.displayLarge,
      displayMedium: TrackletTypography.displayMedium,
      headlineLarge: TrackletTypography.headlineLarge,
      headlineMedium: TrackletTypography.headlineMedium,
      titleLarge: TrackletTypography.titleLarge,
      titleMedium: TrackletTypography.titleMedium,
      bodyLarge: TrackletTypography.bodyLarge,
      bodyMedium: TrackletTypography.bodyMedium,
      bodySmall: TrackletTypography.bodySmall,
      labelLarge: TrackletTypography.labelLarge,
      labelMedium: TrackletTypography.labelMedium,
      labelSmall: TrackletTypography.labelSmall,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: TrackletTypography.fontFamily,
      colorScheme: const ColorScheme.light(
        primary: TrackletColors.primary,
        onPrimary: TrackletColors.textInverse,
        secondary: TrackletColors.secondary,
        onSecondary: TrackletColors.textInverse,
        surface: TrackletColors.surface,
        onSurface: TrackletColors.textPrimary,
        error: TrackletColors.busDelayed,
        onError: TrackletColors.textInverse,
      ),
      scaffoldBackgroundColor: TrackletColors.background,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        md.MoonTheme(tokens: md.MoonTokens.light),
      ],
      cardTheme: const CardThemeData(
        color: TrackletColors.surfaceElevated,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: TrackletRadii.roundedLg,
          side: BorderSide(color: TrackletColors.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: TrackletColors.background,
        foregroundColor: TrackletColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: TrackletColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: TrackletColors.textPrimary,
        size: 24,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TrackletColors.primary,
          foregroundColor: TrackletColors.textInverse,
          minimumSize: const Size(
            TrackletSpacing.minTouchTarget,
            TrackletSpacing.minTouchTarget,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: TrackletRadii.roundedMd,
          ),
          textStyle: TrackletTypography.labelLarge,
          elevation: 0,
        ),
      ),
    );
  }
}
