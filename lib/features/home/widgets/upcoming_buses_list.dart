import 'package:flutter/material.dart';

import '../../../core/formatting/transit_formatter.dart';
import '../../../data/transit/bus.dart';
import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/components/tracklet_card.dart';
import '../../../design_system/components/tracklet_status_badge.dart';
import '../../../design_system/tokens/colors.dart';
import 'package:tracklet/design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// List of upcoming campus buses scheduled or running in the network.
class UpcomingBusesList extends StatelessWidget {
  const UpcomingBusesList({super.key, required this.buses, this.onBusSelected});

  final List<Bus> buses;
  final void Function(Bus bus)? onBusSelected;

  @override
  Widget build(BuildContext context) {
    if (buses.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = TrackletColors.isDark(context);
    final iconBoxColor =
        isDark
            ? TrackletColors.darkSurfaceContainerHighest
            : TrackletColors.background;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Buses',
          style: TrackletTypography.adaptive(
            context,
            TrackletTypography.headlineMedium,
          ),
        ),
        const SizedBox(height: TrackletSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: buses.length,
          separatorBuilder:
              (_, _) => const SizedBox(height: TrackletSpacing.sm),
          itemBuilder: (context, index) {
            final bus = buses[index];
            return TrackletCard(
              onTap: () => onBusSelected?.call(bus),
              padding: const EdgeInsets.symmetric(
                horizontal: TrackletSpacing.lg,
                vertical: TrackletSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBoxColor,
                      borderRadius: TrackletRadii.roundedSm,
                    ),
                    child: const TrackletIcon(
                      TrackletIcons.bus,
                      color: TrackletColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: TrackletSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus.name,
                          style: TrackletTypography.adaptive(
                            context,
                            TrackletTypography.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${bus.numberPlate} • ${TransitFormatter.formatLastUpdated(bus.lastUpdated)}',
                          style: TrackletTypography.adaptiveSecondary(
                            context,
                            TrackletTypography.bodySmall,
                          ),
                        ),
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
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
