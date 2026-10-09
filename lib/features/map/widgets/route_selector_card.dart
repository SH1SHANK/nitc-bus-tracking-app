import 'package:flutter/material.dart';

import '../../../data/transit/bus_route.dart';
import '../../../data/transit/route_geometry.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/shadows.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Top floating control for campus route selection and geometry status.
class RouteSelectorCard extends StatelessWidget {
  const RouteSelectorCard({
    super.key,
    required this.routes,
    required this.selectedRoute,
    required this.onSelectRoute,
    this.onToggleStopsList,
    this.isStopsListExpanded = false,
  });

  final List<BusRoute> routes;
  final BusRoute? selectedRoute;
  final void Function(BusRoute route) onSelectRoute;
  final VoidCallback? onToggleStopsList;
  final bool isStopsListExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TrackletColors.surfaceElevated.withValues(alpha: 0.98),
        borderRadius: TrackletRadii.roundedLg,
        border: Border.all(color: TrackletColors.border),
        boxShadow: const [TrackletShadows.sm],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.md,
        vertical: TrackletSpacing.sm + 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  routes.map((route) {
                    final isSelected = selectedRoute?.id == route.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => onSelectRoute(route),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? TrackletColors.primary
                                    : TrackletColors.background2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? TrackletColors.primary
                                      : TrackletColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                route.code.isNotEmpty ? route.code : route.name,
                                style: TrackletTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isSelected
                                          ? TrackletColors.textInverse
                                          : TrackletColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          if (selectedRoute != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedRoute!.name,
                        style: TrackletTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: TrackletColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (selectedRoute!.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          selectedRoute!.description!,
                          style: TrackletTypography.bodySmall.copyWith(
                            color: TrackletColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (onToggleStopsList != null)
                  InkWell(
                    onTap: onToggleStopsList,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Text(
                            '${selectedRoute!.stopOccurrences.length} stops',
                            style: TrackletTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: TrackletColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            isStopsListExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                            color: TrackletColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Route Geometry Availability Badge
            _buildGeometryStatusBadge(selectedRoute!.geometry),
          ],
        ],
      ),
    );
  }

  Widget _buildGeometryStatusBadge(RouteGeometry geometry) {
    final (label, icon, bgColor, textColor) = switch (geometry.status) {
      RouteGeometryStatus.available => (
        'Road-following path verified',
        Icons.check_circle_outline,
        TrackletColors.busLiveBg,
        TrackletColors.busLive,
      ),
      RouteGeometryStatus.missing => (
        'Road-following path pending verification • Showing ordered stops',
        Icons.info_outline,
        TrackletColors.background2,
        TrackletColors.textSecondary,
      ),
      RouteGeometryStatus.invalid => (
        'Route geometry format invalid',
        Icons.warning_amber_outlined,
        TrackletColors.notificationYellowBgLight,
        TrackletColors.notificationAmber,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TrackletTypography.labelSmall.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
