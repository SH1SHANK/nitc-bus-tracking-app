import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'icons/tracklet_icon.dart';
import 'icons/tracklet_icons.dart';
import 'tracklet_button.dart';

/// Reusable error state view with retry action.
class TrackletErrorState extends StatelessWidget {
  const TrackletErrorState({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TrackletSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TrackletIcon(
              TrackletIcons.error,
              size: 48,
              color: TrackletColors.busDelayed,
            ),
            const SizedBox(height: TrackletSpacing.lg),
            Text(
              title,
              style: TrackletTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TrackletSpacing.sm),
            Text(
              message,
              style: TrackletTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: TrackletSpacing.xl),
              TrackletButton(
                label: retryLabel,
                onPressed: onRetry,
                variant: TrackletButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
