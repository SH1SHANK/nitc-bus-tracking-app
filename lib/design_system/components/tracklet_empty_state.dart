import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'tracklet_button.dart';

/// Reusable empty state view.
class TrackletEmptyState extends StatelessWidget {
  const TrackletEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final Widget? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TrackletSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(height: TrackletSpacing.lg),
            ],
            Text(
              title,
              style: TrackletTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TrackletSpacing.sm),
            Text(
              description,
              style: TrackletTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: TrackletSpacing.xl),
              TrackletButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: TrackletButtonVariant.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
