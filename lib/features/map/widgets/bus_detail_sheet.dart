import 'package:flutter/material.dart';

import '../../../core/formatting/transit_formatter.dart';
import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_card.dart';
import '../../../design_system/components/tracklet_status_badge.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Bottom inspection card shown when a bus or stop is tapped on the map.
class BusDetailSheet extends StatelessWidget {
  const BusDetailSheet({
    super.key,
    required this.bus,
    this.route,
    required this.onClose,
  });

  final Bus bus;
  final BusRoute? route;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return TrackletCard(
      padding: const EdgeInsets.all(TrackletSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bus.name, style: TrackletTypography.titleLarge),
                    const SizedBox(height: 2),
                    Text(bus.numberPlate, style: TrackletTypography.bodySmall),
                  ],
                ),
              ),
              TrackletStatusBadge(
                label: bus.status.displayName,
                status: switch (bus.status) {
                  BusStatus.live => TrackletBadgeStatus.live,
                  BusStatus.delayed => TrackletBadgeStatus.delayed,
                  BusStatus.due => TrackletBadgeStatus.due,
                  BusStatus.offline => TrackletBadgeStatus.offline,
                },
              ),
              IconButton(
                icon: const TrackletIcon(TrackletIcons.close, size: 20),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.md),
          const Divider(),
          const SizedBox(height: TrackletSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DetailStat(
                label: 'Speed',
                value: TransitFormatter.formatSpeed(bus.position.speedKmH),
                icon: TrackletIcons.speed,
              ),
              _DetailStat(
                label: 'Occupancy',
                value: bus.occupancy,
                icon: TrackletIcons.seat,
              ),
              _DetailStat(
                label: 'Updated',
                value: TransitFormatter.formatLastUpdated(bus.lastUpdated),
                icon: TrackletIcons.time,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TrackletIcon(icon, size: 18, color: TrackletColors.textSecondary),
        const SizedBox(height: TrackletSpacing.xs),
        Text(value, style: TrackletTypography.labelLarge),
        Text(label, style: TrackletTypography.bodySmall),
      ],
    );
  }
}
