import 'package:flutter/material.dart';
import '../../../design_system/tokens/shadows.dart';

import '../../../data/transit/bus_route.dart';
import '../../../data/transit/route_geometry.dart';
import '../../../data/transit/route_stop_occurrence.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/radii.dart';

import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

import '../../../design_system/components/tracklet_shimmer_text.dart';
import '../../../design_system/components/tracklet_skeleton.dart';

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
    final isDark = TrackletColors.isDark(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.54;
    final routeColor = _parseRouteColor(route.colorHex);

    return Material(
      color: TrackletColors.adaptiveSurfaceElevated(context),
      elevation: TrackletShadows.elevationLevel4,
      shadowColor: TrackletColors.adaptiveTextPrimary(
        context,
      ).withValues(alpha: isDark ? 0.28 : 0.16),
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
            border: Border.all(
              color: TrackletColors.adaptiveCardBorder(context),
            ),
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
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: TrackletColors.adaptiveBorder(context),
                                borderRadius: TrackletRadii.roundedFull,
                              ),
                            ),
                          ),
                          const SizedBox(height: TrackletSpacing.sm),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: routeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: TrackletSpacing.sm),
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
                                            fontWeight:
                                                TrackletTypography.weightBold,
                                            color:
                                                TrackletColors.adaptiveTextPrimary(
                                                  context,
                                                ),
                                          ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '${stopOccurrences.length} ${stopOccurrences.length == 1 ? 'stop' : 'stops'} · Ordered route stops',
                                      style: TrackletTypography.bodySmall.copyWith(
                                        color:
                                            TrackletColors.adaptiveTextSecondary(
                                              context,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: TrackletSpacing.sm),
                              Icon(
                                isExpanded
                                    ? TrackletIcons.chevronDown
                                    : TrackletIcons.chevronUp,
                                color: routeColor,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: TrackletSpacing.sm,
                      vertical: TrackletSpacing.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: TrackletShimmerText(
                            text: 'Loading route stops...',
                            style: TrackletTypography.bodySmall,
                          ),
                        ),
                        SizedBox(height: TrackletSpacing.md),
                        Row(
                          children: [
                            TrackletSkeleton(
                              width: 24,
                              height: 24,
                              borderRadius: TrackletRadii.roundedFull,
                            ),
                            SizedBox(width: TrackletSpacing.sm),
                            Expanded(
                              child: TrackletSkeleton(
                                width: double.infinity,
                                height: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: TrackletSpacing.sm),
                        Row(
                          children: [
                            TrackletSkeleton(
                              width: 24,
                              height: 24,
                              borderRadius: TrackletRadii.roundedFull,
                            ),
                            SizedBox(width: TrackletSpacing.sm),
                            Expanded(
                              child: TrackletSkeleton(
                                width: double.infinity,
                                height: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                        color: TrackletColors.adaptiveTextSecondary(context),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(
                        top: TrackletSpacing.xs,
                        bottom: TrackletSpacing.xs,
                      ),
                      itemCount: stopOccurrences.length,
                      itemBuilder: (context, index) {
                        final occurrence = stopOccurrences[index];
                        final stop = occurrence.stop;
                        final isSelected =
                            selectedStop != null &&
                            stop != null &&
                            selectedStop!.id == stop.id;
                        final isFirst = index == 0;
                        final isLast = index == stopOccurrences.length - 1;

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
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Timeline line
                                        Positioned(
                                          top: isFirst ? 18 : 0,
                                          bottom: isLast ? 18 : 0,
                                          width: 2,
                                          child: Container(
                                            color:
                                                TrackletColors.adaptiveBorder(
                                                  context,
                                                ),
                                          ),
                                        ),
                                        // Stepper circle
                                        Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? routeColor
                                                    : TrackletColors.adaptiveSurfaceElevated(
                                                      context,
                                                    ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? routeColor
                                                      : TrackletColors.adaptiveBorder(
                                                        context,
                                                      ),
                                              width: isSelected ? 2 : 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            '${occurrence.sequence + 1}',
                                            style: TrackletTypography.labelSmall
                                                .copyWith(
                                                  color:
                                                      isSelected
                                                          ? TrackletColors
                                                              .textInverse
                                                          : TrackletColors.adaptiveTextSecondary(
                                                            context,
                                                          ),
                                                  fontWeight:
                                                      TrackletTypography
                                                          .weightBold,
                                                  fontSize:
                                                      TrackletTypography
                                                          .fontSize10,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: TrackletSpacing.sm),
                                  Expanded(
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minHeight: 44,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: TrackletSpacing.xxs,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: TrackletSpacing.sm,
                                        vertical: TrackletSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? routeColor.withValues(
                                                  alpha: 0.08,
                                                )
                                                : Colors.transparent,
                                        borderRadius: TrackletRadii.roundedSm,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  stop?.name ??
                                                      'Stop unavailable',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TrackletTypography
                                                      .bodyMedium
                                                      .copyWith(
                                                        fontWeight:
                                                            isSelected
                                                                ? FontWeight
                                                                    .w700
                                                                : FontWeight
                                                                    .w500,
                                                        color:
                                                            TrackletColors.adaptiveTextPrimary(
                                                              context,
                                                            ),
                                                      ),
                                                ),
                                                if (stop?.code.isNotEmpty ==
                                                    true)
                                                  Text(
                                                    stop!.code,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TrackletTypography
                                                        .caption
                                                        .copyWith(
                                                          color:
                                                              TrackletColors.adaptiveTextSecondary(
                                                                context,
                                                              ),
                                                        ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              TrackletIcons.checkCircle2,
                                              size: 16,
                                              color: routeColor,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
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
      decoration: BoxDecoration(
        color: TrackletColors.adaptiveSurfaceContainer(context),
        borderRadius: TrackletRadii.roundedSm,
      ),
      child: Row(
        children: [
          Icon(
            TrackletIcons.info,
            size: 16,
            color: TrackletColors.adaptiveTextSecondary(context),
          ),
          const SizedBox(width: TrackletSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: TrackletTypography.caption.copyWith(
                color: TrackletColors.adaptiveTextSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
