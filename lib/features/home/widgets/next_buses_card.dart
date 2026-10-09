import 'package:flutter/material.dart';

import '../../../core/formatting/transit_formatter.dart';
import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/scheduled_departure.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';

/// A compact, data-backed list of other buses currently in the network.
class NextBusesCard extends StatelessWidget {
  const NextBusesCard({
    super.key,
    required this.stopName,
    this.buses = const [],
    this.scheduledDepartures = const [],
    this.routes = const [],
    this.onBusTap,
  });

  final String stopName;
  final List<Bus> buses;
  final List<ScheduledDeparture> scheduledDepartures;
  final List<BusRoute> routes;
  final ValueChanged<Bus>? onBusTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Text(
                'Next buses',
                style: TextStyle(
                  color: TrackletColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                ),
              ),
            ),
            Flexible(
              child: Text(
                'Near $stopName',
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TrackletColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (buses.isEmpty && scheduledDepartures.isNotEmpty) ...[
          const SizedBox(height: 5),
          const Text(
            'Scheduled route departure times; stop arrival times are not included.',
            style: TextStyle(color: TrackletColors.textSecondary, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        if (buses.isEmpty && scheduledDepartures.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: TrackletColors.surface,
              borderRadius: BorderRadius.circular(TrackletRadii.lg),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.departure_board_rounded,
                  color: TrackletColors.textSecondary,
                  size: 22,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No other buses are available to display.',
                    style: TextStyle(
                      color: TrackletColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: TrackletColors.surface,
              borderRadius: BorderRadius.circular(TrackletRadii.lg),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount:
                  buses.isNotEmpty ? buses.length : scheduledDepartures.length,
              separatorBuilder:
                  (context, index) => const Divider(
                    color: TrackletColors.border,
                    height: 1,
                    indent: 72,
                  ),
              itemBuilder:
                  (context, index) =>
                      buses.isNotEmpty
                          ? _BusListItem(
                            bus: buses[index],
                            onTap: () => onBusTap?.call(buses[index]),
                          )
                          : _ScheduledDepartureListItem(
                            departure: scheduledDepartures[index],
                            route:
                                routes
                                    .where(
                                      (route) =>
                                          route.id ==
                                          scheduledDepartures[index].routeId,
                                    )
                                    .firstOrNull,
                          ),
            ),
          ),
      ],
    );
  }
}

class _BusListItem extends StatelessWidget {
  const _BusListItem({required this.bus, this.onTap});

  final Bus bus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (bus.status) {
      BusStatus.live => TrackletColors.busLive,
      BusStatus.delayed => TrackletColors.busDelayed,
      BusStatus.due => TrackletColors.busDue,
      BusStatus.offline => TrackletColors.busOffline,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TrackletRadii.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TrackletColors.background2,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: TrackletColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bus.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TrackletColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${bus.numberPlate} · ${TransitFormatter.formatLastUpdated(bus.lastUpdated)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TrackletColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        bus.status.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'View map',
                    style: TextStyle(
                      color: TrackletColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduledDepartureListItem extends StatelessWidget {
  const _ScheduledDepartureListItem({
    required this.departure,
    required this.route,
  });

  final ScheduledDeparture departure;
  final BusRoute? route;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TrackletColors.background2,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: TrackletColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            route?.name ?? 'Campus route',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TrackletColors.textPrimary,
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              departure.formattedTime,
              style: const TextStyle(
                color: TrackletColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              departure.isSpecial ? 'Special' : 'Scheduled',
              style: const TextStyle(
                color: TrackletColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
