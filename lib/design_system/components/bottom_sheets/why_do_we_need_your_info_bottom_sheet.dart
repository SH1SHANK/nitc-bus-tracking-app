import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';
import '../tracklet_button.dart';

/// Explains how onboarding details support Tracklet's campus transit features.
class WhyDoWeNeedYourInfoBottomSheet extends StatelessWidget {
  const WhyDoWeNeedYourInfoBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => const WhyDoWeNeedYourInfoBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(TrackletRadii.xl),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        color: TrackletColors.surface,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(
                    top: TrackletSpacing.md,
                    bottom: TrackletSpacing.sm,
                  ),
                  decoration: const BoxDecoration(
                    color: TrackletColors.border,
                    borderRadius: TrackletRadii.roundedFull,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    TrackletSpacing.xl,
                    TrackletSpacing.sm,
                    TrackletSpacing.xl,
                    TrackletSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why we need your info',
                        style: TrackletTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: TrackletSpacing.sm),
                      Text(
                        'A few details help tailor your campus transit experience.',
                        style: TrackletTypography.bodyMedium.copyWith(
                          color: TrackletColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: TrackletSpacing.xl),
                      Text(
                        'How it helps',
                        style: TrackletTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: TrackletSpacing.md),
                      const _BenefitRow(
                        icon: Icons.near_me_outlined,
                        title: 'Stops that fit your day',
                        description:
                            'Prioritize shuttle stops near your hostel and department.',
                      ),
                      const SizedBox(height: TrackletSpacing.md),
                      const _BenefitRow(
                        icon: Icons.directions_walk_outlined,
                        title: 'Plan your walk',
                        description:
                            'Estimate the walk to your nearest stop when location is available.',
                      ),
                      const SizedBox(height: TrackletSpacing.md),
                      const _BenefitRow(
                        icon: Icons.route_outlined,
                        title: 'Relevant campus transit info',
                        description:
                            'Keep your campus profile and route information together.',
                      ),
                      const SizedBox(height: TrackletSpacing.xl),
                      Container(
                        padding: const EdgeInsets.all(TrackletSpacing.md),
                        decoration: BoxDecoration(
                          color: TrackletColors.background,
                          borderRadius: TrackletRadii.roundedMd,
                          border: Border.all(color: TrackletColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: TrackletColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: TrackletSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your choice matters',
                                    style: TrackletTypography.titleSmall
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: TrackletSpacing.xs),
                                  Text(
                                    'Location access is optional. You can change it anytime in your device settings.',
                                    style: TrackletTypography.bodySmall
                                        .copyWith(
                                          color: TrackletColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TrackletSpacing.xl,
                  TrackletSpacing.sm,
                  TrackletSpacing.xl,
                  TrackletSpacing.md,
                ),
                child: TrackletButton(
                  label: 'Got it',
                  isFullWidth: true,
                  size: TrackletButtonSize.large,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: TrackletColors.background2,
          borderRadius: TrackletRadii.roundedMd,
        ),
        child: Icon(icon, size: 19, color: TrackletColors.primary),
      ),
      const SizedBox(width: TrackletSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TrackletTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TrackletSpacing.xs),
            Text(
              description,
              style: TrackletTypography.bodySmall.copyWith(
                color: TrackletColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
