import 'package:flutter/material.dart';

import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/scheduled_departure.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../home_transit_logic.dart';

/// A route-aware arrival card. Arrival values are estimates, not timetable data.
class NextBusCard extends StatelessWidget {
  const NextBusCard({
    super.key,
    required this.selectedStop,
    required this.arrival,
    this.scheduledDeparture,
    this.scheduledRoute,
    required this.routePreview,
    this.isNearestStop = false,
    this.onTrackPressed,
  });

  final Stop selectedStop;
  final BusArrivalEstimate? arrival;
  final ScheduledDeparture? scheduledDeparture;
  final BusRoute? scheduledRoute;
  final Widget routePreview;
  final bool isNearestStop;
  final VoidCallback? onTrackPressed;

  @override
  Widget build(BuildContext context) {
    final bus = arrival?.bus;
    final route = arrival?.route;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TrackletSpacing.lg),
      decoration: BoxDecoration(
        color: TrackletColors.surface,
        borderRadius: BorderRadius.circular(TrackletRadii.xl),
        border: Border.all(color: TrackletColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: TrackletColors.background2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: TrackletColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  scheduledDeparture == null
                      ? 'NEXT BUS'
                      : 'NEXT SCHEDULED BUS',
                  style: const TextStyle(
                    color: TrackletColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (bus != null) _StatusPill(status: bus.status),
            ],
          ),
          const SizedBox(height: TrackletSpacing.md),
          if (arrival != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route?.name ?? bus!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: TrackletColors.textPrimary,
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${route?.code ?? 'Campus'}  ·  ${isNearestStop ? 'Nearest stop' : 'Board at'} ${selectedStop.name}',
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
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: TrackletColors.busDueBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${arrival!.etaMinutes}',
                        style: const TextStyle(
                          color: TrackletColors.primary,
                          fontSize: 30,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'MIN',
                        style: TextStyle(
                          color: TrackletColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else if (scheduledDeparture != null && scheduledRoute != null)
            _ScheduledDepartureSummary(
              departure: scheduledDeparture!,
              route: scheduledRoute!,
            )
          else
            _NoArrival(stop: selectedStop),
          const SizedBox(height: TrackletSpacing.md),
          const Divider(height: 1, color: TrackletColors.border),
          const SizedBox(height: TrackletSpacing.md),
          routePreview,
          const SizedBox(height: TrackletSpacing.md),
          const Divider(height: 1, color: TrackletColors.border),
          const SizedBox(height: TrackletSpacing.sm),
          Row(
            children: [
              Icon(
                scheduledDeparture != null
                    ? Icons.schedule_rounded
                    : bus == null
                    ? Icons.info_outline_rounded
                    : Icons.near_me_rounded,
                color: TrackletColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  scheduledDeparture != null
                      ? 'Scheduled departure · live location unavailable'
                      : bus == null
                      ? 'Live bus location unavailable'
                      : '${bus.position.speedKmH.round()} km/h',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TrackletColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onTrackPressed,
                style: TextButton.styleFrom(
                  foregroundColor: TrackletColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  minimumSize: const Size(0, 40),
                  backgroundColor: TrackletColors.background2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                icon: const Icon(Icons.map_outlined, size: 16),
                label: Text(
                  bus == null ? 'Open map' : 'Track bus',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final BusStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BusStatus.live => TrackletColors.busLive,
      BusStatus.delayed => TrackletColors.busDelayed,
      BusStatus.due => TrackletColors.busDue,
      BusStatus.offline => TrackletColors.busOffline,
    };
    final background = switch (status) {
      BusStatus.live => TrackletColors.busLiveBg,
      BusStatus.delayed => TrackletColors.busDelayedBg,
      BusStatus.due => TrackletColors.busDueBg,
      BusStatus.offline => TrackletColors.busOfflineBg,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduledDepartureSummary extends StatelessWidget {
  const _ScheduledDepartureSummary({
    required this.departure,
    required this.route,
  });

  final ScheduledDeparture departure;
  final BusRoute route;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              route.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TrackletColors.textPrimary,
                fontSize: 16,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              departure.isSpecial
                  ? 'Special scheduled departure'
                  : 'Scheduled route departure',
              style: const TextStyle(
                color: TrackletColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: TrackletColors.busDueBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          departure.formattedTime,
          style: const TextStyle(
            color: TrackletColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ],
  );
}

class _NoArrival extends StatelessWidget {
  const _NoArrival({required this.stop});

  final Stop stop;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(
        Icons.schedule_rounded,
        color: TrackletColors.primary,
        size: 23,
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Text(
          'No active buses are serving ${stop.name} right now.',
          style: const TextStyle(
            color: TrackletColors.textSecondary,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
