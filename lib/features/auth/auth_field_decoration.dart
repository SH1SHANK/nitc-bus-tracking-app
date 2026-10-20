import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/motion.dart';
import '../../design_system/tokens/radii.dart';
import '../../design_system/tokens/spacing.dart';
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

    const duration = TrackletMotion.standard;
    return child
        .animate(delay: delay)
        .fadeIn(duration: duration, curve: TrackletMotion.easeOut)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: duration,
          curve: TrackletMotion.easeOut,
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
    borderRadius: TrackletRadii.roundedCard,
  );

  final secondaryColor =
      isDark ? TrackletColors.darkTextSecondary : TrackletColors.textSecondary;

  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: TrackletTypography.labelMedium.copyWith(
      color: secondaryColor,
      fontWeight: TrackletTypography.weightSemiBold,
    ),
    floatingLabelStyle: TrackletTypography.labelMedium.copyWith(
      color: TrackletColors.primary,
      fontWeight: TrackletTypography.weightBold,
    ),
    errorStyle: TrackletTypography.labelSmall.copyWith(
      color: TrackletColors.errorBorder,
      fontWeight: TrackletTypography.weightSemiBold,
    ),
    hintStyle: TrackletTypography.labelLarge.copyWith(
      color: secondaryColor,
      fontWeight: TrackletTypography.weightBold,
    ),
    prefixIcon: Icon(icon, color: secondaryColor, size: TrackletSpacing.icon),
    prefixIconConstraints: const BoxConstraints(
      minWidth: TrackletSpacing.minTouchTarget,
      minHeight: TrackletSpacing.minTouchTarget,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor:
        isDark
            ? TrackletColors.darkSurfaceElevated
            : TrackletColors.primaryBackground,
    contentPadding: const EdgeInsetsDirectional.fromSTEB(
      TrackletSpacing.lg,
      18,
      TrackletSpacing.lg,
      18,
    ),
    enabledBorder: border(
      isDark ? TrackletColors.darkBorder : TrackletColors.alternate,
    ),
    focusedBorder: border(TrackletColors.primary),
    errorBorder: border(TrackletColors.errorBorder),
    focusedErrorBorder: border(TrackletColors.errorBorder),
  );
}
