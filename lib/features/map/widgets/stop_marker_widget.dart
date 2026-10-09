import 'package:flutter/material.dart';

import '../../../data/transit/stop.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/shadows.dart';
import '../../../design_system/tokens/typography.dart';

/// Bus stop marker displayed on the campus map.
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
    final effectiveBorderColor =
        isSelected
            ? TrackletColors.primary
            : (isRouteStop
                ? TrackletColors.primary.withValues(alpha: 0.5)
                : TrackletColors.border);

    final dotColor =
        isSelected
            ? TrackletColors.primary
            : (isRouteStop ? TrackletColors.primary : TrackletColors.secondary);

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 80),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? TrackletColors.primary
                        : TrackletColors.surfaceElevated,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: effectiveBorderColor,
                  width: isSelected || isRouteStop ? 1.5 : 1.0,
                ),
                boxShadow: const [TrackletShadows.sm],
              ),
              child: Text(
                stop.code.isNotEmpty ? stop.code : stop.name,
                style: TrackletTypography.labelSmall.copyWith(
                  color:
                      isSelected
                          ? TrackletColors.textInverse
                          : (isRouteStop
                              ? TrackletColors.primary
                              : TrackletColors.textPrimary),
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: TrackletColors.pure, width: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
