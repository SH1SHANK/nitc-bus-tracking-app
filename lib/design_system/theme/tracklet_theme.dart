import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moon_design/moon_design.dart' as md;

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Primary theme definition for Tracklet.
class TrackletTheme {
  const TrackletTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: TrackletColors.primary,
      onPrimary: TrackletColors.textInverse,
      primaryContainer: TrackletColors.primaryContainer,
      onPrimaryContainer: TrackletColors.onPrimaryContainer,
      secondary: TrackletColors.secondary,
      onSecondary: TrackletColors.textInverse,
      secondaryContainer: TrackletColors.secondaryContainer,
      onSecondaryContainer: TrackletColors.onSecondaryContainer,
      tertiary: TrackletColors.tertiary,
      onTertiary: TrackletColors.textInverse,
      tertiaryContainer: TrackletColors.tertiaryContainer,
      onTertiaryContainer: TrackletColors.onTertiaryContainer,
      surface: TrackletColors.surface,
      onSurface: TrackletColors.textPrimary,
      surfaceContainerLowest: TrackletColors.surfaceContainerLowest,
      surfaceContainerLow: TrackletColors.surfaceContainer,
      surfaceContainer: TrackletColors.surfaceContainer,
      surfaceContainerHigh: TrackletColors.surfaceContainerHigh,
      surfaceContainerHighest: TrackletColors.surfaceElevated,
      onSurfaceVariant: TrackletColors.textSecondary,
      outline: TrackletColors.border,
      outlineVariant: TrackletColors.cardBorder,
      error: TrackletColors.error,
      onError: TrackletColors.textInverse,
      errorContainer: TrackletColors.errorContainer,
      onErrorContainer: TrackletColors.onErrorContainer,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: TrackletTypography.primaryFontFamily,
      fontFamilyFallback: TrackletTypography.fontFallbacks,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: TrackletColors.background,
      textTheme: TrackletTypography.lightTextTheme,
      extensions: <ThemeExtension<dynamic>>[
        md.MoonTheme(tokens: md.MoonTokens.light),
      ],
      cardTheme: const CardThemeData(
        color: TrackletColors.surfaceElevated,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: TrackletRadii.roundedCard,
          side: BorderSide(color: TrackletColors.cardBorder),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: TrackletColors.background,
        foregroundColor: TrackletColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TrackletTypography.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: TrackletColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: TrackletColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: TrackletColors.textPrimary,
        size: TrackletSpacing.iconMd,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TrackletColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TrackletSpacing.lg,
          vertical: TrackletSpacing.md,
        ),
        hintStyle: TrackletTypography.bodyMedium.copyWith(
          color: TrackletColors.textSecondary,
        ),
        labelStyle: TrackletTypography.labelMedium.copyWith(
          color: TrackletColors.textSecondary,
        ),
        floatingLabelStyle: TrackletTypography.labelMedium.copyWith(
          color: TrackletColors.primary,
          fontWeight: FontWeight.w700,
        ),
        errorStyle: TrackletTypography.labelSmall.copyWith(
          color: TrackletColors.errorBorder,
          fontWeight: FontWeight.w600,
        ),
        border: const OutlineInputBorder(
          borderRadius: TrackletRadii.roundedInput,
          borderSide: BorderSide(color: TrackletColors.inputBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: TrackletRadii.roundedInput,
          borderSide: BorderSide(color: TrackletColors.inputBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: TrackletRadii.roundedInput,
          borderSide: BorderSide(color: TrackletColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: TrackletRadii.roundedInput,
          borderSide: BorderSide(color: TrackletColors.errorBorder),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: TrackletRadii.roundedInput,
          borderSide: BorderSide(color: TrackletColors.errorBorder, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: TrackletColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: TrackletRadii.roundedDialog,
        ),
        titleTextStyle: TrackletTypography.titleLarge.copyWith(
          color: TrackletColors.textPrimary,
        ),
        contentTextStyle: TrackletTypography.bodyMedium.copyWith(
          color: TrackletColors.textSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: TrackletColors.surface,
        modalBackgroundColor: TrackletColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: TrackletRadii.roundedTopLg),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: TrackletColors.surface,
        elevation: 0,
        indicatorColor: TrackletColors.primary.withValues(alpha: 0.12),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: TrackletColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: TrackletRadii.roundedPill),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: TrackletColors.darkSurface,
        contentTextStyle: TextStyle(color: TrackletColors.textInverse),
        shape: RoundedRectangleBorder(borderRadius: TrackletRadii.roundedMd),
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
            borderRadius: TrackletRadii.roundedButton,
          ),
          textStyle: TrackletTypography.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TrackletColors.primary,
          minimumSize: const Size(
            TrackletSpacing.minTouchTarget,
            TrackletSpacing.minTouchTarget,
          ),
          side: const BorderSide(color: TrackletColors.border),
          shape: const RoundedRectangleBorder(
            borderRadius: TrackletRadii.roundedButton,
          ),
          textStyle: TrackletTypography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TrackletColors.primary,
          minimumSize: const Size(
            TrackletSpacing.minTouchTarget,
            TrackletSpacing.minTouchTarget,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: TrackletRadii.roundedButton,
          ),
          textStyle: TrackletTypography.labelLarge,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: TrackletColors.primary,
      onPrimary: TrackletColors.textInverse,
      primaryContainer: TrackletColors.primaryContainerDark,
      onPrimaryContainer: TrackletColors.onPrimaryContainerDark,
      secondary: TrackletColors.secondary,
      onSecondary: TrackletColors.textInverse,
      secondaryContainer: TrackletColors.secondaryContainerDark,
      onSecondaryContainer: TrackletColors.onSecondaryContainerDark,
      tertiary: TrackletColors.tertiary,
      onTertiary: TrackletColors.textInverse,
      tertiaryContainer: TrackletColors.tertiaryContainerDark,
      onTertiaryContainer: TrackletColors.onTertiaryContainerDark,
      surface: TrackletColors.darkSurface,
      onSurface: TrackletColors.darkTextPrimary,
      surfaceContainerLowest: TrackletColors.darkSurfaceContainerLowest,
      surfaceContainerLow: TrackletColors.darkSurface,
      surfaceContainer: TrackletColors.darkSurfaceContainer,
      surfaceContainerHigh: TrackletColors.darkSurfaceContainerHigh,
      surfaceContainerHighest: TrackletColors.darkSurfaceElevated,
      onSurfaceVariant: TrackletColors.darkTextSecondary,
      outline: TrackletColors.darkBorder,
      outlineVariant: TrackletColors.darkCardBorder,
      error: TrackletColors.error,
      onError: TrackletColors.textInverse,
      errorContainer: TrackletColors.errorContainerDark,
      onErrorContainer: TrackletColors.onErrorContainerDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: TrackletTypography.primaryFontFamily,
      fontFamilyFallback: TrackletTypography.fontFallbacks,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: TrackletColors.darkBackground,
      textTheme: TrackletTypography.darkTextTheme,
      extensions: <ThemeExtension<dynamic>>[
        md.MoonTheme(tokens: md.MoonTokens.dark),
      ],
      cardTheme: const CardThemeData(
        color: TrackletColors.darkSurfaceElevated,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: TrackletRadii.roundedCard,
          side: BorderSide(color: TrackletColors.darkCardBorder),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: TrackletColors.darkBackground,
        foregroundColor: TrackletColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TrackletTypography.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: TrackletColors.darkBackground,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: TrackletColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: TrackletColors.darkTextPrimary,
        size: TrackletSpacing.iconMd,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TrackletColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TrackletSpacing.lg,
          vertical: TrackletSpacing.md,
        ),
        hintStyle: TrackletTypography.bodyMedium.copyWith(
          color: TrackletColors.darkTextSecondary,
        ),
        labelStyle: TrackletTypography.labelMedium.copyWith(
          color: TrackletColors.darkTextSecondary,
        ),
        floatingLabelStyle: TrackletTypography.labelMedium.copyWith(
          color: TrackletColors.primary,
          fontWeight: FontWeight.w700,
        ),
        errorStyle: TrackletTypography.labelSmall.copyWith(
          color: TrackletColors.errorBorder,
          fontWeight: FontWeight.w600,
        ),
        border: const OutlineInputBorder(
          borderRadius: TrackletRadii.roundedInput,
          borderSide: BorderSide(color: TrackletColors.darkInputBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: TrackletRadii.roundedInput,
          borderSide: BorderSide(color: TrackletColors.darkInputBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: TrackletRadii.roundedInput,
          borderSide: BorderSide(color: TrackletColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: TrackletRadii.roundedInput,
          borderSide: BorderSide(color: TrackletColors.errorBorder),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: TrackletRadii.roundedInput,
          borderSide: BorderSide(color: TrackletColors.errorBorder, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: TrackletColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: TrackletRadii.roundedDialog,
        ),
        titleTextStyle: TrackletTypography.titleLarge.copyWith(
          color: TrackletColors.darkTextPrimary,
        ),
        contentTextStyle: TrackletTypography.bodyMedium.copyWith(
          color: TrackletColors.darkTextSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: TrackletColors.darkSurface,
        modalBackgroundColor: TrackletColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: TrackletRadii.roundedTopLg),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: TrackletColors.darkSurface,
        elevation: 0,
        indicatorColor: TrackletColors.primary.withValues(alpha: 0.12),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: TrackletColors.darkSurfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: TrackletRadii.roundedPill),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: TrackletColors.darkSurfaceElevated,
        contentTextStyle: TextStyle(color: TrackletColors.darkTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: TrackletRadii.roundedMd),
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
            borderRadius: TrackletRadii.roundedButton,
          ),
          textStyle: TrackletTypography.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TrackletColors.primary,
          minimumSize: const Size(
            TrackletSpacing.minTouchTarget,
            TrackletSpacing.minTouchTarget,
          ),
          side: const BorderSide(color: TrackletColors.darkBorder),
          shape: const RoundedRectangleBorder(
            borderRadius: TrackletRadii.roundedButton,
          ),
          textStyle: TrackletTypography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TrackletColors.primary,
          minimumSize: const Size(
            TrackletSpacing.minTouchTarget,
            TrackletSpacing.minTouchTarget,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: TrackletRadii.roundedButton,
          ),
          textStyle: TrackletTypography.labelLarge,
        ),
      ),
    );
  }

  /// Returns the recommended [SystemUiOverlayStyle] for the active theme mode.
  static SystemUiOverlayStyle systemUiOverlayStyle({required bool isDark}) {
    return isDark
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: TrackletColors.darkBackground,
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Colors.transparent,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: TrackletColors.background,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
          );
  }
}
