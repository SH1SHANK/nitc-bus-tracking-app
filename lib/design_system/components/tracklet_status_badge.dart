import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

enum TrackletBadgeStatus { live, delayed, due, offline, info }

/// Pill-shaped semantic status badge used for bus status, route badges, and live indicators.
class TrackletStatusBadge extends StatelessWidget {
  const TrackletStatusBadge({
    super.key,
    required this.label,
    required this.status,
    this.showPulse = false,
  });

  final String label;
  final TrackletBadgeStatus status;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    final (textColor, bgColor) = switch (status) {
      TrackletBadgeStatus.live => (
        TrackletColors.busLive,
        TrackletColors.busLiveBg,
      ),
      TrackletBadgeStatus.delayed => (
        TrackletColors.busDelayed,
        TrackletColors.busDelayedBg,
      ),
      TrackletBadgeStatus.due => (
        TrackletColors.busDue,
        TrackletColors.busDueBg,
      ),
      TrackletBadgeStatus.offline => (
        TrackletColors.busOffline,
        TrackletColors.busOfflineBg,
      ),
      TrackletBadgeStatus.info => (
        TrackletColors.primary,
        const Color(0xFFE8F1FC),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.sm,
        vertical: TrackletSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: TrackletRadii.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPulse || status == TrackletBadgeStatus.live) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: TrackletSpacing.xs),
          ],
          Text(
            label,
            style: TrackletTypography.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
