import 'package:flutter/material.dart';

import '../../../core/formatting/transit_formatter.dart';
import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/scheduled_departure.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
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
    final isDark = TrackletColors.isDark(context);
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
        color: TrackletColors.adaptiveSurfaceElevated(context),
        borderRadius: TrackletRadii.roundedXl,
        border: Border.all(
          color: TrackletColors.adaptiveCardBorder(context),
          width: 1,
        ),
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
                      style: TextStyle(
                        color: TrackletColors.adaptiveTextPrimary(context),
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
                      style: TextStyle(
                        color: TrackletColors.adaptiveTextSecondary(context),
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
                  color:
                      isDark
                          ? TrackletColors.primary.withValues(alpha: 0.18)
                          : TrackletColors.primary.withValues(alpha: 0.08),
                  borderRadius: TrackletRadii.roundedInput,
                  child: InkWell(
                    onTap: onViewSchedule,
                    borderRadius: TrackletRadii.roundedInput,
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'View schedule',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    isDark
                                        ? TrackletColors.primaryDark
                                        : TrackletColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            TrackletIcons.externalLink,
                            color:
                                isDark
                                    ? TrackletColors.primaryDark
                                    : TrackletColors.primary,
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
              color:
                  isDark
                      ? TrackletColors.warningContainerDark
                      : TrackletColors.warningContainer,
              borderRadius: TrackletRadii.roundedCard,
              border: Border.all(
                color:
                    isDark
                        ? TrackletColors.warningContainerDark.withValues(
                          alpha: 0.3,
                        )
                        : TrackletColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      TrackletIcons.info,
                      size: 16,
                      color:
                          isDark
                              ? TrackletColors.onWarningContainerDark
                              : TrackletColors.onWarningContainer,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Institute timetable · Reference only',
                        style: TextStyle(
                          color:
                              isDark
                                  ? TrackletColors.onWarningContainerDark
                                  : TrackletColors.onWarningContainer,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Actual bus timings may vary. These times are not live arrival predictions.',
                  style: TextStyle(
                    color:
                        isDark
                            ? TrackletColors.onWarningContainerDark
                            : TrackletColors.onWarningContainer,
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
                color:
                    isDark
                        ? TrackletColors.darkSurfaceContainer
                        : TrackletColors.background2,
                borderRadius: TrackletRadii.roundedBanner,
                border: Border.all(
                  color: TrackletColors.adaptiveCardBorder(context),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    TrackletIcons.calendarX,
                    color: TrackletColors.adaptiveTextSecondary(context),
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No more scheduled departures for this service period.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TrackletColors.adaptiveTextPrimary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check the full timetable for complete service hours and weekend schedules.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TrackletColors.adaptiveTextSecondary(context),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  if (onViewSchedule != null) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: onViewSchedule,
                      borderRadius: TrackletRadii.roundedSm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              TrackletIcons.calendar,
                              size: 14,
                              color:
                                  isDark
                                      ? TrackletColors.primaryDark
                                      : TrackletColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'View full timetable',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? TrackletColors.primaryDark
                                          : TrackletColors.primary,
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
                color: TrackletColors.adaptiveSurfaceElevated(context),
                borderRadius: TrackletRadii.roundedLg,
                border: Border.all(
                  color: TrackletColors.adaptiveCardBorder(context),
                  width: 1,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: displayDepartures.length,
                separatorBuilder:
                    (context, index) => Divider(
                      color: TrackletColors.adaptiveDivider(context),
                      height: 1,
                      indent: 68,
                    ),
                itemBuilder: (context, index) {
                  final departure = displayDepartures[index];
                  final route =
                      routes
                          .where((r) => r.id == departure.routeId)
                          .firstOrNull;
                  final routeColor =
                      route?.color ?? TrackletColors.routeDefault;
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
                            borderRadius: TrackletRadii.roundedCard,
                          ),
                          child: Icon(
                            TrackletIcons.bus,
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
                                style: TextStyle(
                                  color: TrackletColors.adaptiveTextPrimary(
                                    context,
                                  ),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                routeSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: TrackletColors.adaptiveTextSecondary(
                                    context,
                                  ),
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
                                        ? (isDark
                                            ? TrackletColors.primaryDark
                                            : TrackletColors.primary)
                                        : TrackletColors.adaptiveTextPrimary(
                                          context,
                                        ),
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
                                        ? (isDark
                                            ? TrackletColors.busDelayedBgDark
                                            : TrackletColors.busDelayedBg)
                                        : (isDark
                                            ? TrackletColors
                                                .darkSurfaceContainerHighest
                                            : TrackletColors.background2),
                                borderRadius: TrackletRadii.roundedCompact,
                              ),
                              child: Text(
                                departure.isSpecial ? 'Special' : 'Scheduled',
                                style: TextStyle(
                                  color:
                                      departure.isSpecial
                                          ? (isDark
                                              ? TrackletColors
                                                  .busDelayedTextDark
                                              : TrackletColors.busDelayed)
                                          : TrackletColors.adaptiveTextSecondary(
                                            context,
                                          ),
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
                style: TextStyle(
                  color: TrackletColors.adaptiveTextPrimary(context),
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
                style: TextStyle(
                  color: TrackletColors.adaptiveTextSecondary(context),
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
            color: TrackletColors.adaptiveSurfaceElevated(context),
            borderRadius: TrackletRadii.roundedLg,
            border: Border.all(
              color: TrackletColors.adaptiveCardBorder(context),
              width: 1,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount:
                hasEstimates ? displayEstimates.length : displayBuses.length,
            separatorBuilder:
                (context, index) => Divider(
                  color: TrackletColors.adaptiveDivider(context),
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
    final isDark = TrackletColors.isDark(context);
    final bus = estimate.bus;
    final route = estimate.route;
    final statusColor =
        bus.isStale
            ? TrackletColors.adaptiveTextSecondary(context)
            : switch (bus.status) {
              BusStatus.live =>
                isDark
                    ? TrackletColors.busLiveTextDark
                    : TrackletColors.busLive,
              BusStatus.delayed =>
                isDark
                    ? TrackletColors.busDelayedTextDark
                    : TrackletColors.busDelayed,
              BusStatus.due =>
                isDark ? TrackletColors.busDueTextDark : TrackletColors.busDue,
              BusStatus.offline =>
                isDark
                    ? TrackletColors.busOfflineTextDark
                    : TrackletColors.busOffline,
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
        borderRadius: TrackletRadii.roundedLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? TrackletColors.primaryContainerDark
                          : TrackletColors.background2,
                  borderRadius: TrackletRadii.roundedButton,
                ),
                child: Icon(
                  TrackletIcons.bus,
                  color:
                      isDark
                          ? TrackletColors.primaryDark
                          : TrackletColors.primary,
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
                      style: TextStyle(
                        color: TrackletColors.adaptiveTextPrimary(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: TrackletColors.adaptiveTextSecondary(context),
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
                              ? (isDark
                                  ? TrackletColors.primaryDark
                                  : TrackletColors.primary)
                              : TrackletColors.adaptiveTextSecondary(context),
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
    final isDark = TrackletColors.isDark(context);
    final statusColor =
        bus.isStale
            ? TrackletColors.adaptiveTextSecondary(context)
            : switch (bus.status) {
              BusStatus.live =>
                isDark
                    ? TrackletColors.busLiveTextDark
                    : TrackletColors.busLive,
              BusStatus.delayed =>
                isDark
                    ? TrackletColors.busDelayedTextDark
                    : TrackletColors.busDelayed,
              BusStatus.due =>
                isDark ? TrackletColors.busDueTextDark : TrackletColors.busDue,
              BusStatus.offline =>
                isDark
                    ? TrackletColors.busOfflineTextDark
                    : TrackletColors.busOffline,
            };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: TrackletRadii.roundedLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? TrackletColors.primaryContainerDark
                          : TrackletColors.background2,
                  borderRadius: TrackletRadii.roundedButton,
                ),
                child: Icon(
                  TrackletIcons.bus,
                  color:
                      isDark
                          ? TrackletColors.primaryDark
                          : TrackletColors.primary,
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
                      style: TextStyle(
                        color: TrackletColors.adaptiveTextPrimary(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${bus.numberPlate} · ${TransitFormatter.formatLastUpdated(bus.lastUpdated)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: TrackletColors.adaptiveTextSecondary(context),
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
                  Text(
                    'View map',
                    style: TextStyle(
                      color: TrackletColors.adaptiveTextSecondary(context),
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
