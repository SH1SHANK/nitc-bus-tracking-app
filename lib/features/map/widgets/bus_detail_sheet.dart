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
        padding: const EdgeInsets.all(TrackletSpacing.md),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bus.name, style: TrackletTypography.titleLarge),
                        if (bus.numberPlate.trim().isNotEmpty)
                          Text(
                            bus.numberPlate,
                            style: TrackletTypography.bodySmall,
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
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TrackletSpacing.xs),
              Text(
                widget.route?.name ?? 'Route unavailable',
                style: TrackletTypography.bodyMedium.copyWith(
                  color: TrackletColors.textSecondary,
                ),
              ),
              if (widget.route?.description?.trim().isNotEmpty == true)
                Text(
                  widget.route!.description!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TrackletTypography.bodySmall.copyWith(
                    color: TrackletColors.textSecondary,
                  ),
                ),
              const SizedBox(height: TrackletSpacing.sm),
              Row(
                children: [
                  const Expanded(child: Text('Next stop')),
                  Text(
                    widget.nextStop?.stop?.name ?? 'Unavailable',
                    style: TrackletTypography.labelLarge.copyWith(
                      color: TrackletColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed:
                      () => setState(() {
                        _expanded = !_expanded;
                        widget.onExpandedChanged?.call(_expanded);
                      }),
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  label: Text(_expanded ? 'Less detail' : 'More detail'),
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
                            const Divider(height: TrackletSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: _DetailValue(
                                    label: 'Speed',
                                    value:
                                        bus.position.hasSpeed
                                            ? TransitFormatter.formatSpeed(
                                              bus.position.speedKmH,
                                            )
                                            : '--',
                                  ),
                                ),
                                Expanded(
                                  child: _DetailValue(
                                    label: 'ETA',
                                    value: widget.eta.displayValue,
                                  ),
                                ),
                                Expanded(
                                  child: _DetailValue(
                                    label: 'Updated',
                                    value: TransitFormatter.formatLastUpdated(
                                      bus.lastUpdated,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.stopOccurrences.isNotEmpty) ...[
                              const SizedBox(height: TrackletSpacing.md),
                              const Text(
                                'Upcoming stops',
                                style: TrackletTypography.labelLarge,
                              ),
                              const SizedBox(height: TrackletSpacing.xs),
                              for (final occurrence in widget.stopOccurrences)
                                if (occurrence.stop != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    child: Text(
                                      '${occurrence.sequence + 1}. ${occurrence.stop!.name}',
                                      style: TrackletTypography.bodySmall,
                                    ),
                                  ),
                            ] else if (widget
                                    .route
                                    ?.stopOccurrences
                                    .isNotEmpty ==
                                true) ...[
                              const SizedBox(height: TrackletSpacing.md),
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
                                    icon: const Icon(Icons.my_location_rounded),
                                    label: const Text('Follow bus'),
                                  ),
                                if (widget.onFitRoute != null)
                                  TextButton.icon(
                                    onPressed: widget.onFitRoute,
                                    icon: const Icon(Icons.route_rounded),
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
  const _DetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TrackletTypography.bodySmall),
      Text(value, style: TrackletTypography.labelLarge),
    ],
  );
}
