import 'package:flutter/material.dart';

import '../../../data/transit/bus_route.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';

import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Compact map overlay showing the active route and opening route selection.
class RouteSelectorCard extends StatelessWidget {
  const RouteSelectorCard({
    super.key,
    required this.selectedRoute,
    required this.stopCount,
    required this.onOpenRoutePicker,
  });

  final BusRoute? selectedRoute;
  final int stopCount;
  final VoidCallback onOpenRoutePicker;

  @override
  Widget build(BuildContext context) {
    final route = selectedRoute;

    return Semantics(
      button: true,
      label:
          route == null
              ? 'Choose a campus bus route'
              : 'Selected route ${route.code}, ${route.name}, $stopCount stops. Change route',
      child: Material(
        color: TrackletColors.surfaceElevated,
        borderRadius: TrackletRadii.roundedLg,
        elevation: 2,
        shadowColor: TrackletColors.textPrimary.withValues(alpha: 0.12),
        child: InkWell(
          onTap: onOpenRoutePicker,
          borderRadius: TrackletRadii.roundedLg,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(
              horizontal: TrackletSpacing.md,
              vertical: TrackletSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: TrackletRadii.roundedLg,
              border: Border.all(color: TrackletColors.border),
            ),
            child: Row(
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 44),
                  height: 40,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: const BoxDecoration(
                    color: TrackletColors.background2,
                    borderRadius: TrackletRadii.roundedSm,
                  ),
                  child: Text(
                    route?.code.isNotEmpty == true ? route!.code : 'ROUTE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TrackletTypography.labelMedium.copyWith(
                      color: TrackletColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: TrackletSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route?.name ?? 'Choose a route',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TrackletTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        route?.description?.trim().isNotEmpty == true
                            ? route!.description!.trim()
                            : '$stopCount ${stopCount == 1 ? 'stop' : 'stops'} · Campus loop',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TrackletTypography.bodySmall.copyWith(
                          color: TrackletColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TrackletSpacing.xs),
                const Icon(
                  Icons.expand_more_rounded,
                  color: TrackletColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
