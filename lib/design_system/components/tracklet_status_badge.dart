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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (textColor, bgColor) = switch (status) {
      TrackletBadgeStatus.live => (
        isDark ? TrackletColors.busLiveTextDark : TrackletColors.busLive,
        isDark ? TrackletColors.busLiveBgDark : TrackletColors.busLiveBg,
      ),
      TrackletBadgeStatus.delayed => (
        isDark ? TrackletColors.busDelayedTextDark : TrackletColors.busDelayed,
        isDark ? TrackletColors.busDelayedBgDark : TrackletColors.busDelayedBg,
      ),
      TrackletBadgeStatus.due => (
        isDark ? TrackletColors.busDueTextDark : TrackletColors.busDue,
        isDark ? TrackletColors.busDueBgDark : TrackletColors.busDueBg,
      ),
      TrackletBadgeStatus.offline => (
        isDark ? TrackletColors.busOfflineTextDark : TrackletColors.busOffline,
        isDark ? TrackletColors.busOfflineBgDark : TrackletColors.busOfflineBg,
      ),
      TrackletBadgeStatus.info => (
        TrackletColors.primary,
        isDark
            ? TrackletColors.permissionBlueBgDark
            : TrackletColors.permissionBlueBg,
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
              width: TrackletSpacing.compact,
              height: TrackletSpacing.compact,
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
              fontWeight: TrackletTypography.weightSemiBold,
            ),
          ),
        ],
      ),
    );
  }
}
