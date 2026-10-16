import 'package:flutter/material.dart';

import '../../../core/formatting/transit_formatter.dart';
import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_eta.dart';
import '../../../data/transit/bus_telemetry.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/route_stop_occurrence.dart';
import '../../../design_system/components/tracklet_card.dart';
import '../../../design_system/components/tracklet_status_badge.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Compact bus summary that reveals secondary telemetry and ordered route stops.
class BusDetailSheet extends StatefulWidget {
  const BusDetailSheet({
    super.key,
    required this.bus,
    this.route,
    this.stopOccurrences = const [],
    this.nextStop,
    this.eta = const BusEtaResult.unavailable(
      BusEtaStatus.unresolvedStopProgress,
    ),
    this.isFollowing = false,
    required this.onClose,
    this.onFollowBus,
    this.onFitRoute,
    this.onExpandedChanged,
  });

  final Bus bus;
  final BusRoute? route;
  final List<RouteStopOccurrence> stopOccurrences;
  final RouteStopOccurrence? nextStop;
  final BusEtaResult eta;
  final bool isFollowing;
  final VoidCallback onClose;
  final VoidCallback? onFollowBus;
  final VoidCallback? onFitRoute;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<BusDetailSheet> createState() => _BusDetailSheetState();
}

class _BusDetailSheetState extends State<BusDetailSheet> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bus = widget.bus;
    final stale =
        bus.isStale ||
        bus.status == BusStatus.offline ||
        DateTime.now().difference(bus.position.timestamp) >
            BusTelemetry.staleAfter;
    final status =
        stale
            ? BusStatus.offline
            : bus.position.hasSpeed && bus.position.speedKmH < 2
            ? BusStatus.due
            : bus.status;
    final statusLabel =
        stale
            ? 'Stale / offline'
            : bus.position.hasSpeed && bus.position.speedKmH < 2
            ? 'Stationary'
            : bus.status.displayName;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.56,
      ),
      child: TrackletCard(
        padding: const EdgeInsets.symmetric(
          horizontal: TrackletSpacing.md,
          vertical: TrackletSpacing.sm + 2,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TrackletColors.primary.withValues(alpha: 0.12),
                      borderRadius: TrackletRadii.roundedMd,
                      border: Border.all(
                        color: TrackletColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: TrackletColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: TrackletSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus.name,
                          style: TrackletTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (bus.numberPlate.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              bus.numberPlate,
                              style: TrackletTypography.caption.copyWith(
                                color: TrackletColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  TrackletStatusBadge(
                    label: statusLabel,
                    status: switch (status) {
                      BusStatus.live => TrackletBadgeStatus.live,
                      BusStatus.delayed => TrackletBadgeStatus.delayed,
                      BusStatus.due => TrackletBadgeStatus.delayed,
                      BusStatus.offline => TrackletBadgeStatus.offline,
                    },
                  ),
                  IconButton(
                    tooltip: 'Close bus details',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                    constraints: const BoxConstraints(
                      minWidth: TrackletSpacing.minTouchTarget,
                      minHeight: TrackletSpacing.minTouchTarget,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.route?.name ?? 'Route unavailable',
                style: TrackletTypography.bodySmall.copyWith(
                  color: TrackletColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.route?.description?.trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    widget.route!.description!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TrackletTypography.caption.copyWith(
                      color: TrackletColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: TrackletSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: const BoxDecoration(
                  color: TrackletColors.background,
                  borderRadius: TrackletRadii.roundedSm,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      size: 15,
                      color: TrackletColors.primary,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Next stop',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: TrackletColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.nextStop?.stop?.name ?? 'Unavailable',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TrackletTypography.labelMedium.copyWith(
                          color: TrackletColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (widget.eta.isValid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: TrackletColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.eta.displayValue,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: TrackletColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed:
                      () => setState(() {
                        _expanded = !_expanded;
                        widget.onExpandedChanged?.call(_expanded);
                      }),
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(_expanded ? 'Less detail' : 'More detail'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child:
                    _expanded
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _DetailValue(
                                    icon: Icons.speed_rounded,
                                    label: 'Speed',
                                    value:
                                        bus.position.hasSpeed
                                            ? TransitFormatter.formatSpeed(
                                              bus.position.speedKmH,
                                            )
                                            : '--',
                                  ),
                                ),
                                const SizedBox(width: TrackletSpacing.xs),
                                Expanded(
                                  child: _DetailValue(
                                    icon: Icons.timer_outlined,
                                    label: 'ETA',
                                    value: widget.eta.displayValue,
                                  ),
                                ),
                                const SizedBox(width: TrackletSpacing.xs),
                                Expanded(
                                  child: _DetailValue(
                                    icon: Icons.schedule_rounded,
                                    label: 'Updated',
                                    value: TransitFormatter.formatLastUpdated(
                                      bus.lastUpdated,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.stopOccurrences.isNotEmpty) ...[
                              const SizedBox(height: TrackletSpacing.sm),
                              const Text(
                                'Upcoming stops',
                                style: TrackletTypography.labelLarge,
                              ),
                              const SizedBox(height: 4),
                              for (final occurrence in widget.stopOccurrences)
                                if (occurrence.stop != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color:
                                                occurrence.stopId ==
                                                        widget.nextStop?.stopId
                                                    ? TrackletColors.primary
                                                    : TrackletColors
                                                        .textSecondary
                                                        .withValues(alpha: 0.4),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${occurrence.sequence + 1}. ${occurrence.stop!.name}',
                                            style: TrackletTypography.bodySmall
                                                .copyWith(
                                                  fontWeight:
                                                      occurrence.stopId ==
                                                              widget
                                                                  .nextStop
                                                                  ?.stopId
                                                          ? FontWeight.w700
                                                          : FontWeight.w400,
                                                  color:
                                                      occurrence.stopId ==
                                                              widget
                                                                  .nextStop
                                                                  ?.stopId
                                                          ? TrackletColors
                                                              .textPrimary
                                                          : TrackletColors
                                                              .textSecondary,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (occurrence.stopId ==
                                            widget.nextStop?.stopId)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: TrackletColors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Next',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: TrackletColors.primary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                            ] else if (widget
                                    .route
                                    ?.stopOccurrences
                                    .isNotEmpty ==
                                true) ...[
                              const SizedBox(height: TrackletSpacing.sm),
                              const Text(
                                'Stop progress unavailable',
                                style: TrackletTypography.bodySmall,
                              ),
                            ],
                            const SizedBox(height: TrackletSpacing.sm),
                            Wrap(
                              spacing: TrackletSpacing.sm,
                              children: [
                                if (widget.onFollowBus != null)
                                  TextButton.icon(
                                    onPressed: widget.onFollowBus,
                                    icon: const Icon(
                                      Icons.my_location_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Follow bus'),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          widget.isFollowing
                                              ? TrackletColors.primary
                                              : null,
                                    ),
                                  ),
                                if (widget.onFitRoute != null)
                                  TextButton.icon(
                                    onPressed: widget.onFitRoute,
                                    icon: const Icon(
                                      Icons.route_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Fit route'),
                                  ),
                              ],
                            ),
                          ],
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: TrackletColors.background2,
      borderRadius: TrackletRadii.roundedSm,
      border: Border.all(color: TrackletColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: TrackletColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                label,
                style: TrackletTypography.caption.copyWith(
                  color: TrackletColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TrackletTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: TrackletColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
