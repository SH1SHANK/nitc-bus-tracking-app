import 'package:flutter/material.dart';

import '../../../core/formatting/transit_formatter.dart';
import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/scheduled_departure.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../home_transit_logic.dart';

/// A compact, timetable-backed card showing upcoming scheduled departures
/// for the selected boarding stop.
class NextBusesCard extends StatelessWidget {
  const NextBusesCard({
    super.key,
    required this.stopName,
    this.title,
    this.subtitle,
    this.scheduledDepartures = const [],
    this.routes = const [],
    this.onViewSchedule,
    this.maxItems = 4,
    this.buses = const [],
    this.estimates = const [],
    this.onBusTap,
  });

  final String stopName;
  final String? title;
  final String? subtitle;
  final List<ScheduledDeparture> scheduledDepartures;
  final List<BusRoute> routes;
  final VoidCallback? onViewSchedule;
  final int maxItems;

  // Backwards-compatible parameters for live bus listings if provided
  final List<Bus> buses;
  final List<BusArrivalEstimate> estimates;
  final ValueChanged<Bus>? onBusTap;

  @override
  Widget build(BuildContext context) {
    final hasEstimates = estimates.isNotEmpty;
    final hasBuses = buses.isNotEmpty;
    final displayDepartures = scheduledDepartures.take(maxItems).toList();
    final hasDepartures = displayDepartures.isNotEmpty;

    // If explicit live estimates or buses were passed, render live mode
    if (hasEstimates || hasBuses) {
      return _buildLiveBusesView(context);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TrackletColors.surface,
        borderRadius: BorderRadius.circular(TrackletRadii.xl),
        border: Border.all(color: TrackletColors.border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? 'Scheduled departures',
                      style: const TextStyle(
                        color: TrackletColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle ?? '$stopName · Upcoming schedule',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TrackletColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                fit: FlexFit.loose,
                child: Material(
                  color: TrackletColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onViewSchedule,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        minWidth: 48,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'View schedule',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: TrackletColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_outward_rounded,
                            color: TrackletColors.primary,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Disclaimer Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFF92400E),
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Institute timetable · Reference only',
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Actual bus timings may vary. These times are not live arrival predictions.',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Departures List or Empty State
          if (!hasDepartures)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: TrackletColors.background2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TrackletColors.border, width: 1),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.event_busy_rounded,
                    color: TrackletColors.textSecondary,
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No more scheduled departures for this service period.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TrackletColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Check the full timetable for complete service hours and weekend schedules.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TrackletColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  if (onViewSchedule != null) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: onViewSchedule,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: TrackletColors.primary,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'View full timetable',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: TrackletColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TrackletColors.border, width: 1),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: displayDepartures.length,
                separatorBuilder:
                    (context, index) => const Divider(
                      color: TrackletColors.border,
                      height: 1,
                      indent: 68,
                    ),
                itemBuilder: (context, index) {
                  final departure = displayDepartures[index];
                  final route =
                      routes
                          .where((r) => r.id == departure.routeId)
                          .firstOrNull;
                  final routeColor = route?.color ?? const Color(0xFF64748B);
                  final isFirst = index == 0;

                  final busLabel = departure.busNumber;
                  final stopJourney = _formatRouteStops(route);
                  final detailText =
                      busLabel != null
                          ? '$busLabel · $stopJourney'
                          : stopJourney;
                  final routeSubtitle =
                      isFirst ? '$detailText · Next listed' : detailText;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: routeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.directions_bus_rounded,
                            color: routeColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                route?.name ?? 'Campus route',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: TrackletColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                routeSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: TrackletColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              departure.formattedTime,
                              style: TextStyle(
                                color:
                                    isFirst
                                        ? TrackletColors.primary
                                        : TrackletColors.textPrimary,
                                fontSize: 14,
                                fontWeight:
                                    isFirst ? FontWeight.w800 : FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    departure.isSpecial
                                        ? TrackletColors.busDelayedBg
                                        : TrackletColors.background2,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                departure.isSpecial ? 'Special' : 'Scheduled',
                                style: TextStyle(
                                  color:
                                      departure.isSpecial
                                          ? TrackletColors.busDelayed
                                          : TrackletColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveBusesView(BuildContext context) {
    final displayEstimates = estimates.take(maxItems).toList();
    final displayBuses = buses.take(maxItems).toList();
    final hasEstimates = displayEstimates.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                title ?? 'Other live buses',
                style: const TextStyle(
                  color: TrackletColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                ),
              ),
            ),
            Flexible(
              child: Text(
                subtitle ?? 'Near $stopName',
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
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: TrackletColors.surface,
            borderRadius: BorderRadius.circular(TrackletRadii.lg),
            border: Border.all(color: TrackletColors.border, width: 1),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount:
                hasEstimates ? displayEstimates.length : displayBuses.length,
            separatorBuilder:
                (context, index) => const Divider(
                  color: TrackletColors.border,
                  height: 1,
                  indent: 72,
                ),
            itemBuilder: (context, index) {
              if (hasEstimates) {
                final estimate = displayEstimates[index];
                return _EstimateListItem(
                  estimate: estimate,
                  onTap: () => onBusTap?.call(estimate.bus),
                );
              }
              final bus = displayBuses[index];
              return _BusListItem(bus: bus, onTap: () => onBusTap?.call(bus));
            },
          ),
        ),
      ],
    );
  }

  static String _formatRouteStops(BusRoute? route) {
    if (route == null) return 'Campus route';
    final desc = route.description;
    if (desc != null && desc.contains('→')) {
      final parts =
          desc
              .split('→')
              .map((s) => s.trim())
              .where((s) => !s.toLowerCase().startsWith('return'))
              .toList();
      if (parts.length >= 2) {
        return '${parts.first} ↔ ${parts.last}';
      }
    }
    if (desc != null && desc.isNotEmpty) {
      return desc;
    }
    return 'Campus service';
  }
}

class _EstimateListItem extends StatelessWidget {
  const _EstimateListItem({required this.estimate, this.onTap});

  final BusArrivalEstimate estimate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bus = estimate.bus;
    final route = estimate.route;
    final statusColor =
        bus.isStale
            ? TrackletColors.textSecondary
            : switch (bus.status) {
              BusStatus.live => TrackletColors.busLive,
              BusStatus.delayed => TrackletColors.busDelayed,
              BusStatus.due => TrackletColors.busDue,
              BusStatus.offline => TrackletColors.busOffline,
            };

    final subtitle =
        estimate.currentPositionText != null &&
                estimate.currentPositionText!.isNotEmpty
            ? '${bus.numberPlate} · ${estimate.currentPositionText}'
            : '${bus.numberPlate} · ${TransitFormatter.formatLastUpdated(bus.lastUpdated)}';

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
                      '${bus.name} · ${route.name}',
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
                      subtitle,
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
                        bus.isStale
                            ? 'Stale'
                            : estimate.isRouteUncertain
                            ? 'Uncertain'
                            : bus.status.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    estimate.eta.isValid
                        ? '~${estimate.eta.minutes} min'
                        : 'View map',
                    style: TextStyle(
                      color:
                          estimate.eta.isValid
                              ? TrackletColors.primary
                              : TrackletColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

class _BusListItem extends StatelessWidget {
  const _BusListItem({required this.bus, this.onTap});

  final Bus bus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        bus.isStale
            ? TrackletColors.textSecondary
            : switch (bus.status) {
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
                        bus.isStale ? 'Stale' : bus.status.displayName,
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
