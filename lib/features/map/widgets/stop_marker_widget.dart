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
    this.onTap,
  });

  final Stop stop;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? TrackletColors.primary
                  : TrackletColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected
                    ? TrackletColors.primary
                    : TrackletColors.border,
                width: 1.0,
              ),
              boxShadow: const [TrackletShadows.sm],
            ),
            child: Text(
              stop.code,
              style: TrackletTypography.labelSmall.copyWith(
                color: isSelected
                    ? TrackletColors.textInverse
                    : TrackletColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isSelected
                  ? TrackletColors.primary
                  : TrackletColors.secondary,
              shape: BoxShape.circle,
              border: Border.all(color: TrackletColors.pure, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}
