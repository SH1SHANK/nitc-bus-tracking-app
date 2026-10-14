import 'package:flutter/material.dart';

import '../../../data/transit/stop.dart';
import '../bus_stop_progress.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/shadows.dart';
import '../../../design_system/tokens/typography.dart';

/// Short, tappable label for a campus stop with selected-route state.
class StopMarkerWidget extends StatelessWidget {
  const StopMarkerWidget({
    super.key,
    required this.stop,
    this.isSelected = false,
    this.isRouteStop = false,
    this.accentColor,
    this.showLabel = true,
    this.progress,
    this.onTap,
  });

  final Stop stop;
  final bool isSelected;
  final bool isRouteStop;
  final Color? accentColor;
  final bool showLabel;
  final BusStopProgress? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? TrackletColors.primary;
    final isCurrent = progress?.currentStopId == stop.id;
    final isNext = progress?.nextStop?.stopId == stop.id;
    final isVisited = progress?.visitedStopIds.contains(stop.id) == true;
    final markerColor =
        isSelected
            ? effectiveAccent
            : isCurrent
            ? TrackletColors.success
            : isVisited
            ? TrackletColors.textTertiary
            : isRouteStop || isNext
            ? effectiveAccent
            : TrackletColors.textSecondary;
    final stateLabel =
        isCurrent
            ? 'current stop'
            : isNext
            ? 'next stop'
            : isVisited
            ? 'visited stop'
            : isRouteStop
            ? 'on selected route'
            : 'campus stop';

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${stop.name}${isSelected ? ', selected stop' : ', $stateLabel'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: showLabel ? 112 : 48,
          height: showLabel ? 60 : 48,
          child: Center(
            child: AnimatedScale(
              scale: isSelected ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showLabel)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 104),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? effectiveAccent
                                : TrackletColors.surfaceElevated,
                        borderRadius: TrackletRadii.roundedSm,
                        border: Border.all(
                          color:
                              isSelected
                                  ? effectiveAccent
                                  : isRouteStop || isCurrent || isNext
                                  ? effectiveAccent
                                  : TrackletColors.border,
                          width:
                              isRouteStop || isSelected || isCurrent || isNext
                                  ? 1.5
                                  : 1,
                        ),
                        boxShadow: const [TrackletShadows.sm],
                      ),
                      child: Text(
                        stop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TrackletTypography.labelSmall.copyWith(
                          fontWeight:
                              isSelected || isRouteStop || isCurrent || isNext
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                          color:
                              isSelected
                                  ? TrackletColors.textInverse
                                  : TrackletColors.textPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 3),
                  Container(
                    width: isSelected ? 14 : 12,
                    height: isSelected ? 14 : 12,
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: TrackletColors.surfaceElevated,
                        width: 2,
                      ),
                      boxShadow: const [TrackletShadows.sm],
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              size: 9,
                              color: TrackletColors.textInverse,
                            )
                            : null,
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
