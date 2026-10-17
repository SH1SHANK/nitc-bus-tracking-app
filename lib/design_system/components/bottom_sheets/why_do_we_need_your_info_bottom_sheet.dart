import 'package:flutter/material.dart';
import 'package:tracklet/design_system/components/icons/tracklet_icons.dart';

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
        color: TrackletColors.adaptiveSurfaceElevated(context),
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
                  decoration: BoxDecoration(
                    color: TrackletColors.adaptiveBorder(context),
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
                        style: TrackletTypography.adaptive(
                          context,
                          TrackletTypography.headlineSmall,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: TrackletSpacing.sm),
                      Text(
                        'A few details help tailor your campus transit experience.',
                        style: TrackletTypography.adaptiveSecondary(
                          context,
                          TrackletTypography.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: TrackletSpacing.xl),
                      Text(
                        'How it helps',
                        style: TrackletTypography.adaptive(
                          context,
                          TrackletTypography.titleMedium,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: TrackletSpacing.md),
                      const _BenefitRow(
                        icon: TrackletIcons.navigation,
                        title: 'Stops that fit your day',
                        description:
                            'Prioritize shuttle stops near your hostel and department.',
                      ),
                      const SizedBox(height: TrackletSpacing.md),
                      const _BenefitRow(
                        icon: TrackletIcons.footprints,
                        title: 'Plan your walk',
                        description:
                            'Estimate the walk to your nearest stop when location is available.',
                      ),
                      const SizedBox(height: TrackletSpacing.md),
                      const _BenefitRow(
                        icon: TrackletIcons.gitCommit,
                        title: 'Relevant campus transit info',
                        description:
                            'Keep your campus profile and route information together.',
                      ),
                      const SizedBox(height: TrackletSpacing.xl),
                      Container(
                        padding: const EdgeInsets.all(TrackletSpacing.md),
                        decoration: BoxDecoration(
                          color: TrackletColors.adaptiveBackground(context),
                          borderRadius: TrackletRadii.roundedMd,
                          border: Border.all(
                            color: TrackletColors.adaptiveBorder(context),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              TrackletIcons.lock,
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
                                    style: TrackletTypography.adaptive(
                                      context,
                                      TrackletTypography.titleSmall,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: TrackletSpacing.xs),
                                  Text(
                                    'Location access is optional. You can change it anytime in your device settings.',
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
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                isDark
                    ? TrackletColors.primaryContainerDark
                    : TrackletColors.background2,
            borderRadius: TrackletRadii.roundedMd,
          ),
          child: Icon(
            icon,
            size: 19,
            color: isDark ? TrackletColors.primaryDark : TrackletColors.primary,
          ),
        ),
        const SizedBox(width: TrackletSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TrackletTypography.adaptive(
                  context,
                  TrackletTypography.titleSmall,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: TrackletSpacing.xs),
              Text(
                description,
                style: TrackletTypography.adaptiveSecondary(
                  context,
                  TrackletTypography.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
