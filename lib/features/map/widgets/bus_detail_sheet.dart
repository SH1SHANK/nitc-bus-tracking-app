import 'package:flutter/material.dart';

import '../../../core/formatting/transit_formatter.dart';
import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_eta.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/route_stop_occurrence.dart';
import '../../../design_system/components/tracklet_card.dart';
import '../../../design_system/components/tracklet_status_badge.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Compact bus summary that reveals secondary telemetry and ordered route stops.
class BusDetailSheet extends StatefulWidget {
  const BusDetailSheet({
    super.key,
    required this.bus,
    this.route,
    this.stopOccurrences = const [],
    this.nextStop,
    this.eta = const BusEtaResult.unavailable(
      BusEtaStatus.unresolvedStopProgress,
    ),
    this.isFollowing = false,
    required this.onClose,
    this.onFollowBus,
    this.onFitRoute,
    this.onExpandedChanged,
  });

  final Bus bus;
  final BusRoute? route;
  final List<RouteStopOccurrence> stopOccurrences;
  final RouteStopOccurrence? nextStop;
  final BusEtaResult eta;
  final bool isFollowing;
  final VoidCallback onClose;
  final VoidCallback? onFollowBus;
  final VoidCallback? onFitRoute;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<BusDetailSheet> createState() => _BusDetailSheetState();
}

class _BusDetailSheetState extends State<BusDetailSheet> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    final bus = widget.bus;
    final trackingState = bus.trackingState();
    final bool hasLocation = bus.hasValidLocation;
    final String statusLabel = switch (trackingState) {
      BusTrackingState.liveMoving => bus.status.displayName,
      BusTrackingState.liveStationary => 'Stationary',
      BusTrackingState.stale => 'Stale / offline',
      BusTrackingState.noLocation => 'No GPS fix',
      BusTrackingState.offline => 'Offline',
    };
    final TrackletBadgeStatus badgeStatus = switch (trackingState) {
      BusTrackingState.liveMoving =>
        bus.status == BusStatus.delayed
            ? TrackletBadgeStatus.delayed
            : TrackletBadgeStatus.live,
      BusTrackingState.liveStationary => TrackletBadgeStatus.delayed,
      BusTrackingState.stale => TrackletBadgeStatus.offline,
      BusTrackingState.noLocation => TrackletBadgeStatus.offline,
      BusTrackingState.offline => TrackletBadgeStatus.offline,
    };

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.56,
      ),
      child: TrackletCard(
        padding: const EdgeInsets.symmetric(
          horizontal: TrackletSpacing.md,
          vertical: TrackletSpacing.sm + TrackletSpacing.xxs,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? TrackletColors.primaryContainerDark
                              : TrackletColors.primary.withValues(alpha: 0.12),
                      borderRadius: TrackletRadii.roundedMd,
                      border: Border.all(
                        color:
                            isDark
                                ? TrackletColors.primaryDark.withValues(
                                  alpha: 0.3,
                                )
                                : TrackletColors.primary.withValues(
                                  alpha: 0.25,
                                ),
                      ),
                    ),
                    child: Icon(
                      TrackletIcons.bus,
                      color:
                          isDark
                              ? TrackletColors.primaryDark
                              : TrackletColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: TrackletSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus.name,
                          style: TrackletTypography.titleMedium.copyWith(
                            fontWeight: TrackletTypography.weightBold,
                            color: TrackletColors.adaptiveTextPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (bus.numberPlate.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: TrackletSpacing.hairline,
                            ),
                            child: Text(
                              bus.numberPlate,
                              style: TrackletTypography.caption.copyWith(
                                color: TrackletColors.adaptiveTextSecondary(
                                  context,
                                ),
                                fontWeight: TrackletTypography.weightSemiBold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  TrackletStatusBadge(label: statusLabel, status: badgeStatus),
                  IconButton(
                    tooltip: 'Close bus details',
                    onPressed: widget.onClose,
                    icon: Icon(
                      TrackletIcons.x,
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: TrackletSpacing.minTouchTarget,
                      minHeight: TrackletSpacing.minTouchTarget,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.route?.name ?? 'Route unavailable',
                style: TrackletTypography.bodySmall.copyWith(
                  color: TrackletColors.adaptiveTextSecondary(context),
                  fontWeight: TrackletTypography.weightMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.route?.description?.trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: TrackletSpacing.xxs),
                  child: Text(
                    widget.route!.description!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TrackletTypography.caption.copyWith(
                      color: TrackletColors.adaptiveTextSecondary(context),
                    ),
                  ),
                ),
              const SizedBox(height: TrackletSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TrackletSpacing.compactMd,
                  vertical: TrackletSpacing.compact,
                ),
                decoration: BoxDecoration(
                  color: TrackletColors.adaptiveSurfaceContainer(context),
                  borderRadius: TrackletRadii.roundedSm,
                ),
                child: Row(
                  children: [
                    Icon(
                      TrackletIcons.mapPin,
                      size: 15,
                      color:
                          isDark
                              ? TrackletColors.primaryDark
                              : TrackletColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Next stop',
                      style: TextStyle(
                        fontSize: TrackletTypography.fontSize12,
                        fontWeight: TrackletTypography.weightMedium,
                        color: TrackletColors.adaptiveTextSecondary(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        !hasLocation
                            ? 'Location unavailable'
                            : (widget.nextStop?.stop?.name ?? 'Unavailable'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TrackletTypography.labelMedium.copyWith(
                          color: TrackletColors.adaptiveTextPrimary(context),
                          fontWeight: TrackletTypography.weightBold,
                        ),
                      ),
                    ),
                    if (widget.eta.isValid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TrackletSpacing.sm,
                          vertical: TrackletSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? TrackletColors.primaryContainerDark
                                  : TrackletColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                          borderRadius: TrackletRadii.roundedInput,
                        ),
                        child: Text(
                          widget.eta.displayValue,
                          style: TextStyle(
                            fontSize: TrackletTypography.fontSize11,
                            fontWeight: TrackletTypography.weightBold,
                            color:
                                isDark
                                    ? TrackletColors.primaryDark
                                    : TrackletColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed:
                      () => setState(() {
                        _expanded = !_expanded;
                        widget.onExpandedChanged?.call(_expanded);
                      }),
                  icon: Icon(
                    _expanded
                        ? TrackletIcons.chevronUp
                        : TrackletIcons.chevronDown,
                    size: 18,
                  ),
                  label: Text(_expanded ? 'Less detail' : 'More detail'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: TrackletSpacing.xs,
                      vertical: TrackletSpacing.xxs,
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child:
                    _expanded
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(
                              height: 12,
                              color: TrackletColors.adaptiveDivider(context),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _DetailValue(
                                    icon: TrackletIcons.gauge,
                                    label: 'Speed',
                                    value:
                                        hasLocation && bus.position.hasSpeed
                                            ? TransitFormatter.formatSpeed(
                                              bus.position.speedKmH,
                                            )
                                            : '--',
                                  ),
                                ),
                                const SizedBox(width: TrackletSpacing.xs),
                                Expanded(
                                  child: _DetailValue(
                                    icon: TrackletIcons.timer,
                                    label: 'ETA',
                                    value: widget.eta.displayValue,
                                  ),
                                ),
                                const SizedBox(width: TrackletSpacing.xs),
                                Expanded(
                                  child: _DetailValue(
                                    icon: TrackletIcons.clock,
                                    label: 'Updated',
                                    value: TransitFormatter.formatLastUpdated(
                                      bus.lastUpdated,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.stopOccurrences.isNotEmpty) ...[
                              const SizedBox(height: TrackletSpacing.sm),
                              Text(
                                'Upcoming stops',
                                style: TrackletTypography.labelLarge.copyWith(
                                  color: TrackletColors.adaptiveTextPrimary(
                                    context,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              for (final occurrence in widget.stopOccurrences)
                                if (occurrence.stop != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: TrackletSpacing.xxs,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color:
                                                occurrence.stopId ==
                                                        widget.nextStop?.stopId
                                                    ? (isDark
                                                        ? TrackletColors
                                                            .primaryDark
                                                        : TrackletColors
                                                            .primary)
                                                    : (isDark
                                                        ? TrackletColors
                                                            .darkBorder
                                                        : TrackletColors
                                                            .textSecondary
                                                            .withValues(
                                                              alpha: 0.4,
                                                            )),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${occurrence.sequence + 1}. ${occurrence.stop!.name}',
                                            style: TrackletTypography.bodySmall
                                                .copyWith(
                                                  fontWeight:
                                                      occurrence.stopId ==
                                                              widget
                                                                  .nextStop
                                                                  ?.stopId
                                                          ? TrackletTypography
                                                              .weightBold
                                                          : TrackletTypography
                                                              .weightRegular,
                                                  color:
                                                      occurrence.stopId ==
                                                              widget
                                                                  .nextStop
                                                                  ?.stopId
                                                          ? TrackletColors.adaptiveTextPrimary(
                                                            context,
                                                          )
                                                          : TrackletColors.adaptiveTextSecondary(
                                                            context,
                                                          ),
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (occurrence.stopId ==
                                            widget.nextStop?.stopId)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal:
                                                  TrackletSpacing.compact,
                                              vertical:
                                                  TrackletSpacing.hairline,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isDark
                                                      ? TrackletColors
                                                          .primaryContainerDark
                                                      : TrackletColors.primary
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                              borderRadius:
                                                  TrackletRadii.roundedCompact,
                                            ),
                                            child: Text(
                                              'Next',
                                              style: TextStyle(
                                                fontSize:
                                                    TrackletTypography
                                                        .fontSize10,
                                                fontWeight:
                                                    TrackletTypography
                                                        .weightBold,
                                                color:
                                                    isDark
                                                        ? TrackletColors
                                                            .primaryDark
                                                        : TrackletColors
                                                            .primary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                            ] else if (widget
                                    .route
                                    ?.stopOccurrences
                                    .isNotEmpty ==
                                true) ...[
                              const SizedBox(height: TrackletSpacing.sm),
                              Text(
                                'Stop progress unavailable',
                                style: TrackletTypography.bodySmall.copyWith(
                                  color: TrackletColors.adaptiveTextSecondary(
                                    context,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: TrackletSpacing.sm),
                            Wrap(
                              spacing: TrackletSpacing.sm,
                              children: [
                                if (widget.onFollowBus != null)
                                  TextButton.icon(
                                    onPressed:
                                        hasLocation ? widget.onFollowBus : null,
                                    icon: const Icon(
                                      TrackletIcons.locateFixed,
                                      size: 16,
                                    ),
                                    label: const Text('Follow bus'),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          widget.isFollowing
                                              ? (isDark
                                                  ? TrackletColors.primaryDark
                                                  : TrackletColors.primary)
                                              : null,
                                    ),
                                  ),
                                if (widget.onFitRoute != null)
                                  TextButton.icon(
                                    onPressed: widget.onFitRoute,
                                    icon: const Icon(
                                      TrackletIcons.gitCommit,
                                      size: 16,
                                    ),
                                    label: const Text('Fit route'),
                                  ),
                              ],
                            ),
                          ],
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TrackletSpacing.sm,
        vertical: TrackletSpacing.compact,
      ),
      decoration: BoxDecoration(
        color:
            isDark
                ? TrackletColors.darkSurfaceContainer
                : TrackletColors.background2,
        borderRadius: TrackletRadii.roundedSm,
        border: Border.all(color: TrackletColors.adaptiveBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 12,
                  color: TrackletColors.adaptiveTextSecondary(context),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TrackletTypography.caption.copyWith(
                    color: TrackletColors.adaptiveTextSecondary(context),
                    fontWeight: TrackletTypography.weightSemiBold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TrackletTypography.labelMedium.copyWith(
              fontWeight: TrackletTypography.weightBold,
              color: TrackletColors.adaptiveTextPrimary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
