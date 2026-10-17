import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Reusable card container styled according to Tracklet design system.
class TrackletCard extends StatelessWidget {
  const TrackletCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TrackletSpacing.cardPadding),
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = TrackletRadii.roundedCard,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveBg =
        backgroundColor ??
        Theme.of(context).cardTheme.color ??
        TrackletColors.adaptiveSurfaceElevated(context);

    final effectiveBorderColor =
        borderColor ?? TrackletColors.adaptiveCardBorder(context);

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: borderRadius,
        border: Border.all(color: effectiveBorderColor, width: 1.0),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
