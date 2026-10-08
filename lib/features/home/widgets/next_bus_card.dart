import 'package:flutter/material.dart';

import '../../../core/formatting/transit_formatter.dart';
import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_card.dart';
import '../../../design_system/components/tracklet_status_badge.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import 'route_progress_indicator.dart';

/// Hero transit card on Home screen displaying immediate next bus arrival information.
class NextBusCard extends StatelessWidget {
  const NextBusCard({
    super.key,
    required this.selectedStop,
    required this.nextBus,
    required this.route,
    required this.etaMinutes,
    this.onTrackPressed,
  });

  final Stop selectedStop;
  final Bus? nextBus;
  final BusRoute? route;
  final int etaMinutes;
  final VoidCallback? onTrackPressed;

  @override
  Widget build(BuildContext context) {
    return TrackletCard(
      onTap: onTrackPressed,
      padding: const EdgeInsets.all(TrackletSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nearest stop & walking time header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const TrackletIcon(
                    TrackletIcons.busStop,
                    size: 18,
                    color: TrackletColors.primary,
                  ),
                  const SizedBox(width: TrackletSpacing.xs),
                  Text(
                    selectedStop.name,
                    style: TrackletTypography.titleMedium,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TrackletSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: TrackletColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  TransitFormatter.formatWalkingTime(
                    selectedStop.walkingTimeMinutes,
                  ),
                  style: TrackletTypography.labelSmall.copyWith(
                    color: TrackletColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.lg),

          // Next Bus Arrival Info
          if (nextBus != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  TransitFormatter.formatEta(etaMinutes),
                  style: TrackletTypography.numericLarge.copyWith(
                    color: TrackletColors.primary,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(width: TrackletSpacing.md),
                TrackletStatusBadge(
                  label: nextBus!.status.displayName,
                  status: switch (nextBus!.status) {
                    BusStatus.live => TrackletBadgeStatus.live,
                    BusStatus.delayed => TrackletBadgeStatus.delayed,
                    BusStatus.due => TrackletBadgeStatus.due,
                    BusStatus.offline => TrackletBadgeStatus.offline,
                  },
                ),
              ],
            ),
            const SizedBox(height: TrackletSpacing.xs),
            Text(
              route?.description ?? nextBus!.name,
              style: TrackletTypography.bodyMedium,
            ),
            const SizedBox(height: TrackletSpacing.lg),

            // Route Progress
            RouteProgressIndicator(
              originName: selectedStop.name,
              destinationName: 'Mega Hostel Hub',
              progressPercent: 0.60,
            ),
          ] else ...[
            Text(
              'No active buses right now',
              style: TrackletTypography.titleLarge.copyWith(
                color: TrackletColors.textSecondary,
              ),
            ),
            const SizedBox(height: TrackletSpacing.xs),
            const Text(
              'Next campus shuttle scheduled at 08:30 AM',
              style: TrackletTypography.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
