import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/tracklet_fonts.dart';

/// Semantic types for standard application SnackBars.
enum TrackletSnackBarType { success, error, warning, info }

/// Standardized, accessible, floating SnackBar utility conforming to Tracklet design system tokens.
class TrackletSnackBar {
  const TrackletSnackBar._();

  /// Displays a success notification SnackBar.
  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: TrackletSnackBarType.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Displays an error notification SnackBar.
  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: TrackletSnackBarType.error,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Displays a warning notification SnackBar.
  static void showWarning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: TrackletSnackBarType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Displays an informational notification SnackBar.
  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: TrackletSnackBarType.info,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Displays a standardized floating SnackBar with proper semantic colors, icons, and safe dismissal.
  static void show(
    BuildContext context, {
    required String message,
    TrackletSnackBarType type = TrackletSnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final (Color bgColor, IconData icon) = switch (type) {
      TrackletSnackBarType.success => (
        TrackletColors.success,
        Icons.check_circle_outline_rounded,
      ),
      TrackletSnackBarType.error => (
        TrackletColors.error,
        Icons.error_outline_rounded,
      ),
      TrackletSnackBarType.warning => (
        TrackletColors.warningStrong,
        Icons.warning_amber_rounded,
      ),
      TrackletSnackBarType.info => (
        TrackletColors.primary,
        Icons.info_outline_rounded,
      ),
    };

    final effectiveDuration =
        duration ??
        (type == TrackletSnackBarType.error
            ? const Duration(seconds: 4)
            : const Duration(seconds: 3));

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bgColor,
        duration: effectiveDuration,
        elevation: 4.0,
        margin: const EdgeInsets.symmetric(
          horizontal: TrackletSpacing.screenMargin,
          vertical: TrackletSpacing.sm,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: TrackletRadii.roundedMd,
        ),
        content: Row(
          children: [
            Icon(icon, size: 20.0, color: TrackletColors.textInverse),
            const SizedBox(width: TrackletSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: TrackletFonts.outfit(
                  color: TrackletColors.textInverse,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        action:
            actionLabel != null
                ? SnackBarAction(
                  label: actionLabel,
                  textColor: TrackletColors.textInverse,
                  onPressed: onAction ?? () {},
                )
                : null,
      ),
    );
  }
}
