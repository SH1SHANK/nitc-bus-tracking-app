import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Reusable brand lockup displaying the official BusTracker Logo and Wordmark.
class TrackletBrandLockup extends StatelessWidget {
  const TrackletBrandLockup({
    super.key,
    this.showLogo = true,
    this.showWordmark = true,
    this.logoSize = 36.0,
    this.wordmarkHeight = 22.0,
    this.spacing = TrackletSpacing.sm,
    this.axis = Axis.horizontal,
    this.withContainer = false,
    this.isDark,
  });

  /// Displays the standalone bus logo icon in a styled container.
  const TrackletBrandLockup.logoOnly({
    super.key,
    this.logoSize = 36.0,
    this.withContainer = false,
    this.isDark,
  })  : showLogo = true,
        showWordmark = false,
        wordmarkHeight = 0,
        spacing = 0,
        axis = Axis.horizontal;

  /// Displays the standalone wordmark.
  const TrackletBrandLockup.wordmarkOnly({
    super.key,
    this.wordmarkHeight = 22.0,
    this.withContainer = false,
    this.isDark,
  })  : showLogo = false,
        showWordmark = true,
        logoSize = 0,
        spacing = 0,
        axis = Axis.horizontal;

  final bool showLogo;
  final bool showWordmark;
  final double logoSize;
  final double wordmarkHeight;
  final double spacing;
  final Axis axis;
  final bool withContainer;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = isDark ?? TrackletColors.isDark(context);

    final Widget logoWidget = showLogo
        ? Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: effectiveIsDark
                  ? TrackletColors.darkSurfaceElevated
                  : TrackletColors.surfaceElevated,
              borderRadius: BorderRadius.circular(logoSize * 0.28),
              border: Border.all(
                color: effectiveIsDark
                    ? TrackletColors.darkCardBorder
                    : TrackletColors.cardBorder,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: TrackletColors.primary.withValues(
                    alpha: effectiveIsDark ? 0.2 : 0.1,
                  ),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(logoSize * 0.16),
            child: Image.asset(
              'assets/branding/bustracker_bus_icon.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          )
        : const SizedBox.shrink();

    final Widget wordmarkWidget = showWordmark
        ? Image.asset(
            'assets/branding/bustracker_wordmark.png',
            height: wordmarkHeight,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            color: effectiveIsDark ? TrackletColors.darkTextPrimary : null,
          )
        : const SizedBox.shrink();

    Widget content;
    if (showLogo && showWordmark) {
      if (axis == Axis.horizontal) {
        content = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            logoWidget,
            SizedBox(width: spacing),
            wordmarkWidget,
          ],
        );
      } else {
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            logoWidget,
            SizedBox(height: spacing),
            wordmarkWidget,
          ],
        );
      }
    } else if (showLogo) {
      content = logoWidget;
    } else {
      content = wordmarkWidget;
    }

    if (withContainer) {
      content = Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TrackletSpacing.md,
          vertical: TrackletSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: (effectiveIsDark
                  ? TrackletColors.darkSurface
                  : TrackletColors.surface)
              .withValues(alpha: 0.85),
          borderRadius: TrackletRadii.roundedPill,
          border: Border.all(
            color: (effectiveIsDark
                    ? TrackletColors.darkCardBorder
                    : TrackletColors.cardBorder)
                .withValues(alpha: 0.6),
          ),
        ),
        child: content,
      );
    }

    return Semantics(
      label: 'BusTracker • NITC Campus Transit',
      child: content,
    );
  }
}
