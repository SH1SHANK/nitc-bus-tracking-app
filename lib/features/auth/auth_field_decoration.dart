import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/typography.dart';

class AuthEntrance extends StatelessWidget {
  const AuthEntrance({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return child
        .animate(delay: delay)
        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: 280.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

InputDecoration authInputDecoration({
  required String label,
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
  BuildContext? context,
}) {
  final isDark = context != null && TrackletColors.isDark(context);

  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderSide: BorderSide(color: color, width: 2.0),
    borderRadius: BorderRadius.circular(TrackletRadii.card),
  );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: TrackletTypography.labelMedium.copyWith(
      color:
          isDark
              ? TrackletColors.darkTextSecondary
              : TrackletColors.secondaryText,
      fontWeight: FontWeight.w600,
    ),
    floatingLabelStyle: TrackletTypography.labelMedium.copyWith(
      color: TrackletColors.primary,
      fontWeight: FontWeight.w700,
    ),
    errorStyle: TrackletTypography.labelSmall.copyWith(
      color: TrackletColors.errorBorder,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: TrackletTypography.labelLarge.copyWith(
      color:
          isDark
              ? TrackletColors.darkTextSecondary
              : TrackletColors.secondaryText,
      fontWeight: FontWeight.w700,
    ),
    prefixIcon: Icon(
      icon,
      color:
          isDark
              ? TrackletColors.darkTextSecondary
              : TrackletColors.secondaryText,
      size: 20,
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor:
        isDark
            ? TrackletColors.darkSurfaceElevated
            : TrackletColors.primaryBackground,
    contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 18),
    enabledBorder: border(
      isDark ? TrackletColors.darkBorder : TrackletColors.alternate,
    ),
    focusedBorder: border(TrackletColors.primary),
    errorBorder: border(TrackletColors.errorBorder),
    focusedErrorBorder: border(TrackletColors.errorBorder),
  );
}
