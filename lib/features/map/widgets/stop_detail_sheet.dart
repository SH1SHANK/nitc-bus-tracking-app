import 'package:flutter/material.dart';

import '../../../data/transit/bus_route.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Compact, dismissible details for the selected campus stop.
class StopDetailSheet extends StatelessWidget {
  const StopDetailSheet({
    super.key,
    required this.stop,
    this.routes = const [],
    required this.onClose,
    this.onSelectRoute,
  });

  final Stop stop;
  final List<BusRoute> routes;
  final VoidCallback onClose;
  final void Function(BusRoute route)? onSelectRoute;

  @override
  Widget build(BuildContext context) {
    final servingRoutes =
        routes.where((route) {
          if (route.stopOccurrences.isNotEmpty) {
            return route.stopOccurrences.any(
              (occurrence) => occurrence.stopId == stop.id,
            );
          }
          return route.stopIds.contains(stop.id);
        }).toList();

    return Material(
      color: TrackletColors.surfaceElevated,
      elevation: 3,
      shadowColor: TrackletColors.textPrimary.withValues(alpha: 0.14),
      borderRadius: TrackletRadii.roundedLg,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.32,
        ),
        padding: const EdgeInsets.all(TrackletSpacing.md),
        decoration: BoxDecoration(
          borderRadius: TrackletRadii.roundedLg,
          border: Border.all(color: TrackletColors.border),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: TrackletColors.background2,
                      borderRadius: TrackletRadii.roundedSm,
                    ),
                    child: const Icon(
                      Icons.place_rounded,
                      color: TrackletColors.primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: TrackletSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TrackletTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (stop.code.isNotEmpty)
                          Text(
                            stop.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TrackletTypography.caption,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    tooltip: 'Close stop details',
                    icon: const Icon(Icons.close_rounded),
                    color: TrackletColors.textSecondary,
                    constraints: const BoxConstraints(
                      minWidth: TrackletSpacing.minTouchTarget,
                      minHeight: TrackletSpacing.minTouchTarget,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              if (stop.description?.trim().isNotEmpty == true) ...[
                const SizedBox(height: TrackletSpacing.xs),
                Text(
                  stop.description!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TrackletTypography.bodySmall,
                ),
              ],
              const SizedBox(height: TrackletSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.directions_walk_rounded,
                    size: 16,
                    color: TrackletColors.textSecondary,
                  ),
                  const SizedBox(width: TrackletSpacing.xs),
                  Text(
                    'About ${stop.walkingTimeMinutes} min walk',
                    style: TrackletTypography.bodySmall.copyWith(
                      color: TrackletColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${servingRoutes.length} ${servingRoutes.length == 1 ? 'route' : 'routes'}',
                    style: TrackletTypography.labelSmall.copyWith(
                      color: TrackletColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (servingRoutes.isNotEmpty) ...[
                const SizedBox(height: TrackletSpacing.xs),
                Wrap(
                  spacing: TrackletSpacing.xs,
                  runSpacing: TrackletSpacing.xs,
                  children: [
                    for (final route in servingRoutes)
                      ActionChip(
                        label: Text(
                          route.code.isNotEmpty ? route.code : route.name,
                        ),
                        onPressed:
                            onSelectRoute == null
                                ? null
                                : () => onSelectRoute!(route),
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(
                          Icons.directions_bus_rounded,
                          size: 15,
                          color: TrackletColors.primary,
                        ),
                        labelStyle: TrackletTypography.labelSmall.copyWith(
                          color: TrackletColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: TrackletColors.background,
                        side: const BorderSide(color: TrackletColors.border),
                        shape: const StadiumBorder(),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
