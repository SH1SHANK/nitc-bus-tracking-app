import 'package:tracklet/design_system/tokens/spacing.dart';
import 'package:tracklet/design_system/tokens/typography.dart';
import 'package:flutter/material.dart';

import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/shadows.dart';

/// A focused snapshot of the nearest campus bus and the stop it serves.
class AtAGlanceTransitCard extends StatelessWidget {
  const AtAGlanceTransitCard({
    super.key,
    required this.selectedStop,
    required this.nextBus,
    required this.route,
    this.onTap,
  });

  final Stop selectedStop;
  final Bus? nextBus;
  final BusRoute? route;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    final cardBg = TrackletColors.adaptiveSurfaceElevated(context);
    final textPrimary = TrackletColors.adaptiveTextPrimary(context);
    final textSecondary = TrackletColors.adaptiveTextSecondary(context);
    final border = TrackletColors.adaptiveBorder(context);

    final bus = nextBus;
    final isLive = bus?.isLive ?? false;
    final statusColor = switch (bus?.status) {
      BusStatus.live =>
        isDark ? TrackletColors.busLiveTextDark : TrackletColors.busLive,
      BusStatus.delayed =>
        isDark ? TrackletColors.busDelayedTextDark : TrackletColors.busDelayed,
      BusStatus.due =>
        isDark ? TrackletColors.busDueTextDark : TrackletColors.busDue,
      _ =>
        isDark ? TrackletColors.busOfflineTextDark : TrackletColors.busOffline,
    };
    final statusBackground = switch (bus?.status) {
      BusStatus.live =>
        isDark ? TrackletColors.busLiveBgDark : TrackletColors.busLiveBg,
      BusStatus.delayed =>
        isDark ? TrackletColors.busDelayedBgDark : TrackletColors.busDelayedBg,
      BusStatus.due =>
        isDark ? TrackletColors.busDueBgDark : TrackletColors.busDueBg,
      _ =>
        isDark ? TrackletColors.busOfflineBgDark : TrackletColors.busOfflineBg,
    };

    return Material(
      color: cardBg,
      borderRadius: TrackletRadii.roundedXl,
      child: InkWell(
        onTap: onTap,
        borderRadius: TrackletRadii.roundedXl,
        child: Container(
          padding: const EdgeInsets.all(TrackletSpacing.cardPaddingLg),
          decoration: BoxDecoration(
            borderRadius: TrackletRadii.roundedXl,
            border: isDark ? Border.all(color: border) : null,
            boxShadow: isDark ? null : const [TrackletShadows.md],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    TrackletIcons.mapPin,
                    color: TrackletColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      selectedStop.name,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: TrackletTypography.fontSize14,
                        fontWeight: TrackletTypography.weightBold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Boarding stop',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: TrackletTypography.fontSize12,
                      fontWeight: TrackletTypography.weightSemiBold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (bus == null)
                _EmptyBusState(onTap: onTap)
              else ...[
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: TrackletColors.primary,
                        borderRadius: TrackletRadii.roundedLg,
                      ),
                      child: const Icon(
                        TrackletIcons.bus,
                        color: TrackletColors.textInverse,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route?.name ?? bus.name,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: TrackletTypography.fontSize18,
                              height: TrackletTypography.lineHeightTight,
                              fontWeight: TrackletTypography.weightExtraBold,
                              letterSpacing:
                                  TrackletTypography.letterSpacingTitle,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bus.numberPlate,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: TrackletTypography.fontSize13,
                              fontWeight: TrackletTypography.weightMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TrackletSpacing.compactMd,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackground,
                        borderRadius: TrackletRadii.roundedPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            bus.status.displayName,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: TrackletTypography.fontSize12,
                              fontWeight: TrackletTypography.weightBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: border),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      isLive ? TrackletIcons.locateFixed : TrackletIcons.info,
                      color: isLive ? TrackletColors.busLive : textSecondary,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        isLive
                            ? 'Live location is available'
                            : 'Live location is not available',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: TrackletTypography.fontSize13,
                          fontWeight: TrackletTypography.weightSemiBold,
                        ),
                      ),
                    ),
                    const Icon(
                      TrackletIcons.arrowRight,
                      color: TrackletColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBusState extends StatelessWidget {
  const _EmptyBusState({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary = TrackletColors.adaptiveTextPrimary(context);
    final textSecondary = TrackletColors.adaptiveTextSecondary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No buses to show right now',
          style: TextStyle(
            color: textPrimary,
            fontSize: TrackletTypography.fontSize18,
            fontWeight: TrackletTypography.weightExtraBold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Check the campus map for the latest bus activity.',
          style: TextStyle(
            color: textSecondary,
            fontSize: TrackletTypography.fontSize14,
            height: TrackletTypography.lineHeightBody,
          ),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: onTap,
          icon: const Icon(TrackletIcons.map, size: 18),
          label: const Text('Open campus map'),
          style: TextButton.styleFrom(
            foregroundColor: TrackletColors.primary,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
