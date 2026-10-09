import 'package:flutter/material.dart';

import '../../../data/transit/stop.dart';
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
    this.onTap,
  });

  final Stop stop;
  final bool isSelected;
  final bool isRouteStop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final markerColor =
        isSelected
            ? TrackletColors.primary
            : isRouteStop
            ? TrackletColors.primary
            : TrackletColors.textSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${stop.name}${isSelected
              ? ', selected stop'
              : isRouteStop
              ? ', on selected route'
              : ', campus stop'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 112,
          height: 60,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 104),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? TrackletColors.primary
                            : TrackletColors.surfaceElevated,
                    borderRadius: TrackletRadii.roundedSm,
                    border: Border.all(
                      color:
                          isSelected
                              ? TrackletColors.primary
                              : isRouteStop
                              ? TrackletColors.primary
                              : TrackletColors.border,
                      width: isRouteStop || isSelected ? 1.5 : 1,
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
                          isSelected || isRouteStop
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
    );
  }
}
