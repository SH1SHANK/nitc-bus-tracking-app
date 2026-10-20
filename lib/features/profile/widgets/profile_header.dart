import 'package:flutter/material.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart'
    as animated;

import '../../../data/profile/profile.dart';
import '../../../design_system/components/tracklet_card.dart';
import '../../../design_system/components/voxel_avatar.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../dialogs/avatar_picker_sheet.dart';

/// User identity and academic profile card displaying branch, batch, and semester.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return TrackletCard(
      padding: const EdgeInsets.all(TrackletSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap:
                    () => AvatarPickerSheet.show(
                      context,
                      currentSeed: profile.avatarSeed,
                      userEmail: profile.email,
                      userName: profile.name,
                    ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    VoxelAvatar(
                      email: profile.email,
                      name: profile.name,
                      avatarSeed: profile.avatarSeed,
                      size: 56,
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(
                          TrackletSpacing.avatarRingInset,
                        ),
                        decoration: BoxDecoration(
                          color: TrackletColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: TrackletColors.adaptiveSurface(context),
                            width: 1.5,
                          ),
                        ),
                        child: const animated.LucideAnimatedIcon(
                          icon: animated.sparkles,
                          size: 11,
                          color: TrackletColors.textInverse,
                          trigger: animated.AnimationTrigger.manual,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TrackletSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: TrackletTypography.adaptive(
                        context,
                        TrackletTypography.titleLarge,
                      ),
                    ),
                    if (profile.username != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${profile.username}',
                        style: TrackletTypography.labelSmall.copyWith(
                          color: TrackletColors.primary,
                          fontWeight: TrackletTypography.weightBold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      profile.email,
                      style: TrackletTypography.adaptiveSecondary(
                        context,
                        TrackletTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TrackletSpacing.md),
          Divider(color: TrackletColors.adaptiveDivider(context)),
          const SizedBox(height: TrackletSpacing.md),

          // Academic Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ProfileBadge(label: profile.branch),
              _ProfileBadge(label: profile.batch),
              _ProfileBadge(label: profile.semester),
              if (profile.hostel.isNotEmpty)
                _ProfileBadge(label: profile.hostel),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.sm,
        vertical: TrackletSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: TrackletColors.adaptiveSurfaceElevated(context),
        borderRadius: TrackletRadii.roundedFull,
        border: Border.all(color: TrackletColors.adaptiveBorder(context)),
      ),
      child: Text(
        label,
        style: TrackletTypography.labelSmall.copyWith(
          color: TrackletColors.adaptiveTextSecondary(context),
          fontSize: TrackletTypography.fontSize11,
          fontWeight: TrackletTypography.weightSemiBold,
        ),
      ),
    );
  }
}
