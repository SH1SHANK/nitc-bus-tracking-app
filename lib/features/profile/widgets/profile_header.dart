import 'package:flutter/material.dart';

import '../../../data/profile/profile.dart';
import '../../../design_system/components/tracklet_card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// User identity and academic profile card.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return TrackletCard(
      padding: const EdgeInsets.all(TrackletSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: TrackletColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                profile.name.isNotEmpty
                    ? profile.name.substring(0, 1).toUpperCase()
                    : 'U',
                style: TrackletTypography.displayMedium.copyWith(
                  color: TrackletColors.textInverse,
                ),
              ),
            ),
          ),
          const SizedBox(width: TrackletSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: TrackletTypography.titleLarge),
                const SizedBox(height: 2),
                Text(profile.email, style: TrackletTypography.bodyMedium),
                if (profile.rollNumber != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Roll No: ${profile.rollNumber}',
                    style: TrackletTypography.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
