import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

enum TrackletButtonVariant { primary, secondary, outline, ghost }

enum TrackletButtonSize { small, medium, large }

/// Accessible, styled button component for Tracklet.
class TrackletButton extends StatelessWidget {
  const TrackletButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = TrackletButtonVariant.primary,
    this.size = TrackletButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final TrackletButtonVariant variant;
  final TrackletButtonSize size;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      TrackletButtonSize.small => 36.0,
      TrackletButtonSize.medium => 48.0,
      TrackletButtonSize.large => 56.0,
    };

    final horizontalPadding = switch (size) {
      TrackletButtonSize.small => TrackletSpacing.md,
      TrackletButtonSize.medium => TrackletSpacing.lg,
      TrackletButtonSize.large => TrackletSpacing.xl,
    };

    final isEnabled = onPressed != null && !isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? border;

    switch (variant) {
      case TrackletButtonVariant.primary:
        backgroundColor = isEnabled
            ? TrackletColors.primary
            : TrackletColors.surface;
        foregroundColor = isEnabled
            ? TrackletColors.textInverse
            : TrackletColors.textTertiary;
        border = null;
      case TrackletButtonVariant.secondary:
        backgroundColor = isEnabled
            ? TrackletColors.secondary
            : TrackletColors.surface;
        foregroundColor = isEnabled
            ? TrackletColors.textInverse
            : TrackletColors.textTertiary;
        border = null;
      case TrackletButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled
            ? TrackletColors.primary
            : TrackletColors.textTertiary;
        border = BorderSide(
          color: isEnabled ? TrackletColors.border : TrackletColors.divider,
        );
      case TrackletButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled
            ? TrackletColors.textPrimary
            : TrackletColors.textTertiary;
        border = null;
    }

    final buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: TrackletSpacing.sm),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: TrackletSpacing.sm),
        ],
        Text(
          label,
          style: TrackletTypography.labelLarge.copyWith(color: foregroundColor),
        ),
      ],
    );

    Widget content = Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: TrackletRadii.roundedMd,
        side: border ?? BorderSide.none,
      ),
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: TrackletRadii.roundedMd,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: TrackletSpacing.minTouchTarget,
            minWidth: TrackletSpacing.minTouchTarget,
          ),
          height: height,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          alignment: Alignment.center,
          child: buttonChild,
        ),
      ),
    );

    if (isFullWidth) {
      content = SizedBox(width: double.infinity, child: content);
    }

    return content;
  }
}
