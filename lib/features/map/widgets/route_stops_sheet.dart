import 'package:flutter/material.dart';

import '../../../data/transit/bus_route.dart';
import '../../../data/transit/route_stop_occurrence.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/shadows.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Sheet presenting the ordered sequence of stops for the selected route.
class RouteStopsSheet extends StatelessWidget {
  const RouteStopsSheet({
    super.key,
    required this.route,
    required this.stopOccurrences,
    this.selectedStop,
    required this.onSelectStop,
    required this.onClose,
  });

  final BusRoute route;
  final List<RouteStopOccurrence> stopOccurrences;
  final Stop? selectedStop;
  final void Function(Stop stop) onSelectStop;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TrackletColors.surfaceElevated,
      elevation: 6,
      borderRadius: TrackletRadii.roundedLg,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.45,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: TrackletSpacing.md,
          vertical: TrackletSpacing.sm,
        ),
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
              children: [
                Expanded(
                  child: Text(
                    '${route.name} Stops',
                    style: TrackletTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: TrackletColors.textPrimary,
                    ),
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
            const SizedBox(height: 4),
            Text(
              'Sequential stops in loop order (${stopOccurrences.length} stops)',
              style: TrackletTypography.bodySmall.copyWith(
                color: TrackletColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: TrackletColors.border),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: stopOccurrences.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final occurrence = stopOccurrences[index];
                  final stop = occurrence.stop;
                  final isSelected =
                      selectedStop != null &&
                      stop != null &&
                      selectedStop!.id == stop.id;

                  return InkWell(
                    onTap: stop != null ? () => onSelectStop(stop) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? TrackletColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? TrackletColors.primary
                                  : TrackletColors.background2,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? TrackletColors.primary
                                    : TrackletColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${occurrence.sequence + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? TrackletColors.textInverse
                                      : TrackletColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              stop?.name ?? 'Stop #${occurrence.sequence + 1}',
                              style: TrackletTypography.bodyMedium.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? TrackletColors.primary
                                    : TrackletColors.textPrimary,
                              ),
                            ),
                          ),
                          if (stop?.code != null && stop!.code.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: TrackletColors.background2,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                stop.code,
                                style: TrackletTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: TrackletColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
