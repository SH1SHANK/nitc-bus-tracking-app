import 'package:flutter/material.dart';

import '../../../core/formatting/transit_formatter.dart';
import '../../../core/geo/geo_point.dart';
import '../../../data/transit/bus.dart';
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
    this.userLocation,
    this.isDefaultStop = false,
    this.routes = const [],
    this.buses = const [],
    required this.onClose,
    this.onSelectRoute,
    this.onSelectBus,
    this.onSetAsDefaultStop,
  });

  final Stop stop;
  final GeoPoint? userLocation;
  final bool isDefaultStop;
  final List<BusRoute> routes;
  final List<Bus> buses;
  final VoidCallback onClose;
  final void Function(BusRoute route)? onSelectRoute;
  final void Function(Bus bus)? onSelectBus;
  final VoidCallback? onSetAsDefaultStop;

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

    final String walkTimeText;
    final IconData walkIcon;
    if (userLocation != null) {
      final distance = userLocation!.distanceToMeters(stop.location);
      if (distance <= 3000) {
        final minutes = TransitFormatter.estimateWalkMinutes(distance);
        walkTimeText =
            '${TransitFormatter.formatDistance(distance)} · ~${TransitFormatter.formatWalkingTime(minutes)}';
        walkIcon = Icons.directions_walk_rounded;
      } else {
        walkTimeText = '${TransitFormatter.formatDistance(distance)} away';
        walkIcon = Icons.straighten_rounded;
      }
    } else if (stop.walkingTimeMinutes > 0) {
      walkTimeText = 'About ${stop.walkingTimeMinutes} min walk';
      walkIcon = Icons.directions_walk_rounded;
    } else {
      walkTimeText = 'Campus stop';
      walkIcon = Icons.place_outlined;
    }

    return Material(
      color: TrackletColors.surfaceElevated,
      elevation: 4,
      shadowColor: TrackletColors.textPrimary.withValues(alpha: 0.16),
      borderRadius: TrackletRadii.roundedLg,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.44,
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
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TrackletColors.background2,
                      borderRadius: TrackletRadii.roundedMd,
                      border: Border.all(color: TrackletColors.border),
                    ),
                    child: const Icon(
                      Icons.place_rounded,
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
                          stop.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TrackletTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: TrackletColors.textPrimary,
                          ),
                        ),
                        if (stop.code.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              stop.code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TrackletTypography.caption.copyWith(
                                color: TrackletColors.textSecondary,
                              ),
                            ),
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
                  style: TrackletTypography.bodySmall.copyWith(
                    color: TrackletColors.textSecondary,
                  ),
                ),
              ],
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
                    Icon(
                      walkIcon,
                      size: 16,
                      color: TrackletColors.textSecondary,
                    ),
                    const SizedBox(width: TrackletSpacing.xs),
                    Expanded(
                      child: Text(
                        walkTimeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TrackletTypography.bodySmall.copyWith(
                          color: TrackletColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: TrackletSpacing.xs),
                    Text(
                      '${servingRoutes.length} ${servingRoutes.length == 1 ? 'route' : 'routes'}',
                      style: TrackletTypography.labelSmall.copyWith(
                        color: TrackletColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (servingRoutes.isNotEmpty) ...[
                const SizedBox(height: TrackletSpacing.sm),
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
                        backgroundColor: TrackletColors.surfaceElevated,
                        side: const BorderSide(color: TrackletColors.border),
                        shape: const StadiumBorder(),
                      ),
                  ],
                ),
              ],
              if (buses.isNotEmpty) ...[
                () {
                  final servingRouteIds =
                      servingRoutes.map((r) => r.id).toSet();
                  final busesServingStop =
                      buses
                          .where((b) => servingRouteIds.contains(b.routeId))
                          .toList();
                  if (busesServingStop.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: TrackletSpacing.sm),
                      Text(
                        'Live Buses',
                        style: TrackletTypography.labelSmall.copyWith(
                          color: TrackletColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final bus in busesServingStop)
                        InkWell(
                          onTap:
                              onSelectBus == null
                                  ? null
                                  : () => onSelectBus!(bus),
                          borderRadius: TrackletRadii.roundedMd,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: TrackletColors.background2,
                              borderRadius: TrackletRadii.roundedMd,
                              border: Border.all(color: TrackletColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.directions_bus_rounded,
                                  size: 18,
                                  color:
                                      bus.isStale
                                          ? TrackletColors.textSecondary
                                          : TrackletColors.busLive,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bus.name.isNotEmpty
                                            ? bus.name
                                            : 'Bus ${bus.numberPlate}',
                                        style: TrackletTypography.bodySmall
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: TrackletColors.textPrimary,
                                            ),
                                      ),
                                      Text(
                                        bus.isStale
                                            ? 'Telemetry stale'
                                            : (bus.position.speedKmH > 1
                                                ? '${bus.position.speedKmH.toStringAsFixed(0)} km/h • In transit'
                                                : 'At stop / Dwelling'),
                                        style: TrackletTypography.caption
                                            .copyWith(
                                              color:
                                                  TrackletColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        bus.isStale
                                            ? TrackletColors.alternate
                                            : TrackletColors.busLiveBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    bus.isStale ? 'Stale' : 'LIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          bus.isStale
                                              ? TrackletColors.textSecondary
                                              : TrackletColors.busLive,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                }(),
              ],
              if (isDefaultStop) ...[
                const SizedBox(height: TrackletSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 9,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: TrackletColors.primary.withValues(alpha: 0.08),
                    borderRadius: TrackletRadii.roundedMd,
                    border: Border.all(
                      color: TrackletColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: TrackletColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your selected boarding stop',
                        style: TrackletTypography.bodySmall.copyWith(
                          color: TrackletColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (onSetAsDefaultStop != null) ...[
                const SizedBox(height: TrackletSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onSetAsDefaultStop,
                    icon: const Icon(Icons.star_outline_rounded, size: 16),
                    label: const Text('Set as Boarding Stop'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TrackletColors.primary,
                      side: const BorderSide(color: TrackletColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: const RoundedRectangleBorder(
                        borderRadius: TrackletRadii.roundedMd,
                      ),
                    ),
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
