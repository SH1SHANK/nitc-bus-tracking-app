import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Minimal transit route progress visualization between campus hubs.
class RouteProgressIndicator extends StatelessWidget {
  const RouteProgressIndicator({
    super.key,
    required this.originName,
    required this.destinationName,
    this.progressPercent = 0.65,
  });

  final String originName;
  final String destinationName;
  final double progressPercent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              originName,
              style: TrackletTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: TrackletColors.textSecondary,
              ),
            ),
            Text(
              destinationName,
              style: TrackletTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: TrackletColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: TrackletSpacing.xs),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Background Track
            Container(
              height: 6,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: TrackletColors.surface,
                borderRadius: TrackletRadii.roundedFull,
              ),
            ),
            // Active Progress
            LayoutBuilder(
              builder: (context, constraints) {
                final activeWidth =
                    constraints.maxWidth * progressPercent.clamp(0.0, 1.0);
                return Container(
                  height: 6,
                  width: activeWidth,
                  decoration: const BoxDecoration(
                    color: TrackletColors.primary,
                    borderRadius: TrackletRadii.roundedFull,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
