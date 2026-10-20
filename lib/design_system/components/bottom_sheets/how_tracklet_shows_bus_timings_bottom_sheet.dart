import 'package:tracklet/design_system/tokens/spacing.dart';
import '../../tokens/radii.dart';
import 'package:flutter/material.dart';
import 'package:tracklet/design_system/components/icons/tracklet_icons.dart';

import '../../tokens/colors.dart';
import '../../tokens/typography.dart';
import '../tracklet_button.dart';

/// Authentic Attendrix Bottom Sheet: "How BusTracker Calculates Bus Departures".
class HowTrackletShowsBusTimingsBottomSheet extends StatelessWidget {
  const HowTrackletShowsBusTimingsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => const HowTrackletShowsBusTimingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28.0),
        topRight: Radius.circular(28.0),
      ),
      child: Container(
        width: double.infinity,
        color: TrackletColors.adaptiveSurfaceElevated(context),
        padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Draggable Handle
              Center(
                child: Container(
                  width: 36.0,
                  height: 5.0,
                  margin: const EdgeInsets.only(bottom: TrackletSpacing.lg),
                  decoration: BoxDecoration(
                    color: TrackletColors.adaptiveBorder(context),
                    borderRadius: TrackletRadii.roundedFull,
                  ),
                ),
              ),

              // Title
              Text(
                'How BusTracker Shows Bus Timings',
                style: TrackletTypography.displaySmall.copyWith(
                  fontSize: TrackletTypography.fontSize22,
                  fontWeight: TrackletTypography.weightBold,
                  color: TrackletColors.adaptiveTextPrimary(context),
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'BusTracker uses official NIT Calicut transit timetables along with your walking distance to help you decide whether to walk to the stop.',
                style: TrackletTypography.bodySmall.copyWith(
                  color: TrackletColors.adaptiveTextSecondary(context),
                  fontSize: TrackletTypography.fontSize13,
                  height: TrackletTypography.lineHeightBody,
                ),
              ),
              const SizedBox(height: 20.0),

              // Recommendation explanations
              _buildStatusCard(
                context,
                icon: TrackletIcons.checkCircle2,
                iconColor: TrackletColors.success,
                title: 'Worth Waiting',
                description:
                    'The bus is scheduled soon and you have comfortable time to walk to the nearest stop.',
                color: TrackletColors.success.withValues(
                  alpha: isDark ? 0.2 : 0.1,
                ),
                borderColor: TrackletColors.success.withValues(
                  alpha: isDark ? 0.4 : 0.3,
                ),
              ),
              const SizedBox(height: 10.0),
              _buildStatusCard(
                context,
                icon: TrackletIcons.alertTriangle,
                iconColor: TrackletColors.warning,
                title: 'Hurry',
                description:
                    'Departure is approaching! Walk briskly to make sure you catch this shuttle.',
                color: TrackletColors.warning.withValues(
                  alpha: isDark ? 0.2 : 0.1,
                ),
                borderColor: TrackletColors.warning.withValues(
                  alpha: isDark ? 0.4 : 0.3,
                ),
              ),
              const SizedBox(height: 10.0),
              _buildStatusCard(
                context,
                icon: TrackletIcons.footprints,
                iconColor: TrackletColors.tertiary,
                title: 'Skip This Bus',
                description:
                    'Walking to the stop will take longer than remaining departure time. Consider catching the next shuttle.',
                color: TrackletColors.tertiary.withValues(
                  alpha: isDark ? 0.2 : 0.1,
                ),
                borderColor: TrackletColors.tertiary.withValues(
                  alpha: isDark ? 0.4 : 0.3,
                ),
              ),
              const SizedBox(height: 24.0),

              // Got it Button
              TrackletButton(
                label: 'Got it',
                isFullWidth: true,
                size: TrackletButtonSize.large,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required Color color,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(TrackletSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: TrackletRadii.roundedBanner,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.0, color: iconColor),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: TrackletTypography.fontSize14,
                    fontWeight: FontWeight.bold,
                    color: TrackletColors.adaptiveTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: TrackletTypography.fontSize12,
                    color: TrackletColors.adaptiveTextSecondary(context),
                    height: TrackletTypography.lineHeightCompact,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
