import 'package:flutter/material.dart';

import '../../../data/transit/bus_route.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';

import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Compact map overlay showing the active route, route accent badge, and opening route selection.
class RouteSelectorCard extends StatelessWidget {
  const RouteSelectorCard({
    super.key,
    required this.selectedRoute,
    required this.stopCount,
    required this.onOpenRoutePicker,
    this.onClearRoute,
  });

  final BusRoute? selectedRoute;
  final int stopCount;
  final VoidCallback onOpenRoutePicker;
  final VoidCallback? onClearRoute;

  Color _parseRouteColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return TrackletColors.primary;
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
    } catch (_) {
      return TrackletColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = selectedRoute;
    final routeColor =
        route != null
            ? _parseRouteColor(route.colorHex)
            : TrackletColors.primary;

    return Semantics(
      button: true,
      label:
          route == null
              ? 'Choose a campus bus route'
              : 'Selected route ${route.code}, ${route.name}, $stopCount stops. Change route',
      child: Material(
        color: TrackletColors.surfaceElevated,
        borderRadius: TrackletRadii.roundedLg,
        elevation: 3,
        shadowColor: TrackletColors.textPrimary.withValues(alpha: 0.12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: TrackletRadii.roundedLg,
            border: Border.all(color: TrackletColors.border),
          ),
          child: InkWell(
            onTap: onOpenRoutePicker,
            borderRadius: TrackletRadii.roundedLg,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TrackletSpacing.md,
                vertical: TrackletSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 46),
                    height: 42,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color:
                          route != null
                              ? routeColor.withValues(alpha: 0.12)
                              : TrackletColors.background2,
                      borderRadius: TrackletRadii.roundedMd,
                      border: Border.all(
                        color:
                            route != null
                                ? routeColor.withValues(alpha: 0.3)
                                : TrackletColors.border,
                      ),
                    ),
                    child: Text(
                      route?.code.isNotEmpty == true ? route!.code : 'ROUTE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TrackletTypography.labelMedium.copyWith(
                        color:
                            route != null ? routeColor : TrackletColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: TrackletSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route?.name ?? 'Choose a route',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TrackletTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: TrackletColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                  AnimatedScale(
                    scale: (route != null && onClearRoute != null) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child:
                        (route != null && onClearRoute != null)
                            ? Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                color: TrackletColors.textSecondary,
                                tooltip: 'Clear selected route',
                                onPressed: onClearRoute,
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                  const Icon(
                    Icons.unfold_more_rounded,
                    color: TrackletColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
