import 'package:flutter/material.dart';

import '../../../design_system/components/tracklet_card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Settings tile to manage push notification and alert preferences.
class NotificationPreferencesTile extends StatelessWidget {
  const NotificationPreferencesTile({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return TrackletCard(
      padding: const EdgeInsets.all(TrackletSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: TrackletColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: TrackletColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: TrackletSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transit Alerts', style: TrackletTypography.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Get notified when buses approach your stop',
                  style: TrackletTypography.bodySmall,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            activeTrackColor: TrackletColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
