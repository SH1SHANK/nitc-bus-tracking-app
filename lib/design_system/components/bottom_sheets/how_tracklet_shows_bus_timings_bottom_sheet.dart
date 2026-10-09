import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/typography.dart';
import '../tracklet_button.dart';

/// Authentic Attendrix Bottom Sheet: "How Tracklet Calculates Bus Departures".
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
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28.0),
        topRight: Radius.circular(28.0),
      ),
      child: Container(
        width: double.infinity,
        color: TrackletColors.surface,
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
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: TrackletColors.border,
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                ),
              ),

              // Title
              Text(
                'How Tracklet Shows Bus Timings',
                style: TrackletTypography.displaySmall.copyWith(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w700,
                  color: TrackletColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'Tracklet uses official NIT Calicut transit timetables along with your walking distance to help you decide whether to walk to the stop.',
                style: TrackletTypography.bodySmall.copyWith(
                  color: TrackletColors.textSecondary,
                  fontSize: 13.0,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20.0),

              // Recommendation explanations
              _buildStatusCard(
                icon: '🟢',
                title: 'Worth Waiting',
                description:
                    'The bus is scheduled soon and you have comfortable time to walk to the nearest stop.',
                color: TrackletColors.success.withValues(alpha: 0.1),
                borderColor: TrackletColors.success.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 10.0),
              _buildStatusCard(
                icon: '⚠️',
                title: 'Hurry',
                description:
                    'Departure is approaching! Walk briskly to make sure you catch this shuttle.',
                color: TrackletColors.warning.withValues(alpha: 0.1),
                borderColor: TrackletColors.warning.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 10.0),
              _buildStatusCard(
                icon: '🚶',
                title: 'Skip This Bus',
                description:
                    'Walking to the stop will take longer than remaining departure time. Consider catching the next shuttle.',
                color: TrackletColors.tertiary.withValues(alpha: 0.1),
                borderColor: TrackletColors.tertiary.withValues(alpha: 0.3),
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

  Widget _buildStatusCard({
    required String icon,
    required String title,
    required String description,
    required Color color,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18.0)),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: TrackletColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: TrackletColors.textSecondary,
                    height: 1.3,
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
