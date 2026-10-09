import 'package:flutter/material.dart';

import '../../../data/transit/bus_route.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/components/icons/tracklet_icon.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/shadows.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Bottom card presenting comprehensive stop metadata and served routes.
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
        routes.where((r) {
          if (r.stopOccurrences.isNotEmpty) {
            return r.stopOccurrences.any((o) => o.stopId == stop.id);
          }
          return r.stopIds.contains(stop.id);
        }).toList();

    return Material(
      color: TrackletColors.surfaceElevated,
      elevation: 6,
      borderRadius: TrackletRadii.roundedLg,
      child: Container(
        padding: const EdgeInsets.all(TrackletSpacing.md),
        decoration: BoxDecoration(
          borderRadius: TrackletRadii.roundedLg,
          border: Border.all(color: TrackletColors.border),
          boxShadow: const [TrackletShadows.md],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TrackletColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const TrackletIcon(
                    TrackletIcons.busStop,
                    color: TrackletColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: TrackletSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.name,
                        style: TrackletTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: TrackletColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (stop.code.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: TrackletColors.background2,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                stop.code,
                                style: TrackletTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: TrackletColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '~${stop.walkingTimeMinutes} min walk',
                            style: TrackletTypography.bodySmall.copyWith(
                              color: TrackletColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: TrackletColors.textSecondary,
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (stop.description != null && stop.description!.isNotEmpty) ...[
              const SizedBox(height: TrackletSpacing.sm),
              Text(
                stop.description!,
                style: TrackletTypography.bodySmall.copyWith(
                  color: TrackletColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: TrackletSpacing.sm),
            const Divider(height: 1, color: TrackletColors.border),
            const SizedBox(height: TrackletSpacing.sm),
            Text(
              'Serving Routes (${servingRoutes.length})',
              style: TrackletTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: TrackletColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            if (servingRoutes.isEmpty)
              Text(
                'No active routes scheduled for this stop.',
                style: TrackletTypography.bodySmall.copyWith(
                  color: TrackletColors.textTertiary,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children:
                    servingRoutes.map((route) {
                      return InkWell(
                        onTap: () => onSelectRoute?.call(route),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: TrackletColors.background2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: TrackletColors.primary.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: TrackletColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                route.code.isNotEmpty ? route.code : route.name,
                                style: TrackletTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: TrackletColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
