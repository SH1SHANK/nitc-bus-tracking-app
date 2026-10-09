import 'package:flutter/material.dart';

import '../../../data/transit/bus_route.dart';
import '../../../data/transit/route_geometry.dart';
import '../../../data/transit/route_stop_occurrence.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';

import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Compact, expandable route summary with the route's ordered stop occurrences.
class RouteStopsSheet extends StatelessWidget {
  const RouteStopsSheet({
    super.key,
    required this.route,
    required this.stopOccurrences,
    this.selectedStop,
    required this.isExpanded,
    required this.onToggle,
    required this.onSelectStop,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final BusRoute route;
  final List<RouteStopOccurrence> stopOccurrences;
  final Stop? selectedStop;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(Stop stop) onSelectStop;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.52;

    return Material(
      color: TrackletColors.surfaceElevated,
      elevation: 3,
      shadowColor: TrackletColors.textPrimary.withValues(alpha: 0.14),
      borderRadius: TrackletRadii.roundedLg,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            TrackletSpacing.md,
            TrackletSpacing.sm,
            TrackletSpacing.md,
            TrackletSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: TrackletRadii.roundedLg,
            border: Border.all(color: TrackletColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                button: true,
                label:
                    '${isExpanded ? 'Collapse' : 'Expand'} ${route.name}, ${stopOccurrences.length} stops',
                child: GestureDetector(
                  onVerticalDragEnd: (DragEndDetails details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if ((isExpanded && velocity > 0) ||
                        (!isExpanded && velocity < 0)) {
                      onToggle();
                    }
                  },
                  child: InkWell(
                    onTap: onToggle,
                    borderRadius: TrackletRadii.roundedSm,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: TrackletSpacing.xs,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 34,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: TrackletColors.border,
                              borderRadius: TrackletRadii.roundedFull,
                            ),
                          ),
                          const SizedBox(height: TrackletSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      route.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TrackletTypography.titleSmall
                                          .copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '${stopOccurrences.length} ${stopOccurrences.length == 1 ? 'stop' : 'stops'} · Ordered route stops',
                                      style: TrackletTypography.bodySmall
                                          .copyWith(
                                            color: TrackletColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: TrackletSpacing.sm),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_down_rounded
                                    : Icons.keyboard_arrow_up_rounded,
                                color: TrackletColors.primary,
                                size: 24,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isExpanded) ...[
                if (route.geometry.status != RouteGeometryStatus.available)
                  _GeometryNotice(status: route.geometry.status),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(TrackletSpacing.lg),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: TrackletColors.primary,
                      ),
                    ),
                  )
                else if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: TrackletSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TrackletTypography.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: onRetry,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (stopOccurrences.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: TrackletSpacing.md,
                    ),
                    child: Text(
                      'No stops are available for this route yet.',
                      style: TrackletTypography.bodySmall.copyWith(
                        color: TrackletColors.textSecondary,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(
                        top: TrackletSpacing.xs,
                        bottom: TrackletSpacing.xs,
                      ),
                      itemCount: stopOccurrences.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        final occurrence = stopOccurrences[index];
                        final stop = occurrence.stop;
                        final isSelected =
                            selectedStop != null &&
                            stop != null &&
                            selectedStop!.id == stop.id;

                        return Semantics(
                          button: stop != null,
                          selected: isSelected,
                          label:
                              'Stop ${occurrence.sequence + 1}: ${stop?.name ?? 'Unavailable stop'}',
                          child: InkWell(
                            key: ValueKey(
                              'route-stop-${occurrence.sequence}-${occurrence.stopId}',
                            ),
                            onTap:
                                stop == null ? null : () => onSelectStop(stop),
                            borderRadius: TrackletRadii.roundedSm,
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: TrackletSpacing.sm,
                                vertical: TrackletSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? TrackletColors.background2
                                        : Colors.transparent,
                                borderRadius: TrackletRadii.roundedSm,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? TrackletColors.primary
                                              : TrackletColors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? TrackletColors.primary
                                                : TrackletColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      '${occurrence.sequence + 1}',
                                      style: TrackletTypography.labelSmall
                                          .copyWith(
                                            color:
                                                isSelected
                                                    ? TrackletColors.textInverse
                                                    : TrackletColors
                                                        .textSecondary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: TrackletSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      stop?.name ?? 'Stop unavailable',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TrackletTypography.bodyMedium
                                          .copyWith(
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                            color: TrackletColors.textPrimary,
                                          ),
                                    ),
                                  ),
                                  if (stop?.code.isNotEmpty == true) ...[
                                    const SizedBox(width: TrackletSpacing.xs),
                                    Text(
                                      stop!.code,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TrackletTypography.caption,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GeometryNotice extends StatelessWidget {
  const _GeometryNotice({required this.status});

  final RouteGeometryStatus status;

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      RouteGeometryStatus.available => '',
      RouteGeometryStatus.missing =>
        'Road-following path is not available yet. The stop order is shown below.',
      RouteGeometryStatus.invalid =>
        'Road-following path is being verified. The stop order is shown below.',
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: TrackletSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.sm,
        vertical: TrackletSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: TrackletColors.background,
        borderRadius: TrackletRadii.roundedSm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: TrackletColors.textSecondary,
          ),
          const SizedBox(width: TrackletSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: TrackletTypography.caption.copyWith(
                color: TrackletColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
