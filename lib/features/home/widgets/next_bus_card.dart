import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/formatting/transit_formatter.dart';
import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/bus_stop_progress.dart';
import '../../../data/transit/scheduled_departure.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/tokens/colors.dart';
import '../home_transit_logic.dart';

/// A compact, map-oriented live bus card designed for rapid campus rider scanning.
///
/// Prioritizes:
/// 1. Bus identity and live status pill.
/// 2. Prominent current physical location and relation to the user's boarding stop.
/// 3. Compact 3–4 stop trip progress timeline with mutually consistent, ordered states.
/// 4. Data-aware secondary ETA (reclaiming space when unavailable).
/// 5. Single primary map action ("Track bus").
class NextBusCard extends StatelessWidget {
  const NextBusCard({
    super.key,
    required this.selectedStop,
    required this.arrival,
    this.stops = const [],
    this.scheduledDeparture,
    this.scheduledRoute,
    this.routePreview,
    this.busProgress,
    this.busLocationHint,
    this.onTrackPressed,
    this.onViewFullRoute,
  });

  final Stop selectedStop;
  final BusArrivalEstimate? arrival;
  final List<Stop> stops;
  final ScheduledDeparture? scheduledDeparture;
  final BusRoute? scheduledRoute;
  final Widget? routePreview;
  final BusStopProgress? busProgress;
  final String? busLocationHint;
  final VoidCallback? onTrackPressed;
  final VoidCallback? onViewFullRoute;

  @override
  Widget build(BuildContext context) {
    final arrivalEstimate = arrival;
    final bus = arrivalEstimate?.bus;
    final route = arrivalEstimate?.route ?? scheduledRoute;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TrackletColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TrackletColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Bus Icon, Title/Route Subtitle & Live Status Pill
          _HeaderRow(
            bus: bus,
            route: route,
            arrival: arrivalEstimate,
            scheduledDeparture: scheduledDeparture,
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: TrackletColors.border),
          const SizedBox(height: 14),

          // 2. Main Content Body
          if (arrivalEstimate != null && bus != null) ...[
            // Current Physical Location Section
            _CurrentLocationSection(
              bus: bus,
              route: route,
              selectedStop: selectedStop,
              arrival: arrivalEstimate,
              progress: arrivalEstimate.progress ?? busProgress,
              locationHint: busLocationHint,
              allStops: stops,
            ),

            const SizedBox(height: 14),

            // 3. Compact Directional Trip Progress (or custom preview fallback)
            _TripProgressSection(
              route: route,
              bus: bus,
              selectedStop: selectedStop,
              progress: arrivalEstimate.progress ?? busProgress,
              progressDetails: arrivalEstimate.progressDetails,
              allStops: stops,
              customPreview: routePreview,
              onViewFullRoute:
                  onViewFullRoute ??
                  (route != null
                      ? () => _showFullRouteSheet(
                        context,
                        route: route,
                        allStops: stops,
                        selectedStop: selectedStop,
                        progress: arrivalEstimate.progress ?? busProgress,
                      )
                      : null),
            ),
          ] else if (scheduledDeparture != null && scheduledRoute != null) ...[
            _ScheduledDepartureSummary(
              departure: scheduledDeparture!,
              route: scheduledRoute!,
            ),
          ] else ...[
            _NoArrival(stop: selectedStop),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1, color: TrackletColors.border),
          const SizedBox(height: 14),

          // 4. Footer: Compact Freshness & Secondary ETA (Left) + Primary Track Action (Right)
          _FooterRow(
            bus: bus,
            arrival: arrivalEstimate,
            scheduledDeparture: scheduledDeparture,
            onTrackPressed: onTrackPressed,
          ),
        ],
      ),
    );
  }

  void _showFullRouteSheet(
    BuildContext context, {
    required BusRoute route,
    required List<Stop> allStops,
    required Stop selectedStop,
    required BusStopProgress? progress,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => _FullRouteSheet(
            route: route,
            allStops: allStops,
            selectedStop: selectedStop,
            progress: progress,
          ),
    );
  }
}

// ============================================================================
// HEADER SECTION
// ============================================================================

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.bus,
    required this.route,
    required this.arrival,
    required this.scheduledDeparture,
  });

  final Bus? bus;
  final BusRoute? route;
  final BusArrivalEstimate? arrival;
  final ScheduledDeparture? scheduledDeparture;

  @override
  Widget build(BuildContext context) {
    final title =
        scheduledDeparture != null
            ? 'Scheduled Bus Departure'
            : (route?.name ?? bus?.name ?? 'Campus Bus');
    final routeCode = route?.code;

    final String statusTag;
    if (scheduledDeparture != null) {
      statusTag = 'NEXT SCHEDULED BUS';
    } else if (bus == null) {
      statusTag = 'NEXT BUS';
    } else if (bus!.isStale || bus!.status == BusStatus.offline) {
      statusTag = 'LAST KNOWN BUS';
    } else if (arrival?.isAtStop == true) {
      statusTag = 'AT YOUR STOP';
    } else if (arrival?.isConfirmed == true) {
      statusTag = 'NEXT BUS';
    } else {
      statusTag = 'BUS ON ROUTE';
    }

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: TrackletColors.background2,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Center(
            child: Icon(
              Icons.directions_bus_rounded,
              color: TrackletColors.primary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TrackletColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (routeCode != null && routeCode.isNotEmpty)
                    Text(
                      '$routeCode · ',
                      style: const TextStyle(
                        color: TrackletColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      statusTag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TrackletColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (bus != null)
          _StatusPill(
            status: bus!.status,
            isStale: bus!.isStale,
            isRouteUncertain: arrival?.isRouteUncertain ?? false,
          ),
      ],
    );
  }
}

// ============================================================================
// CURRENT LOCATION SECTION
// ============================================================================

class _CurrentLocationSection extends StatelessWidget {
  const _CurrentLocationSection({
    required this.bus,
    required this.route,
    required this.selectedStop,
    required this.arrival,
    required this.progress,
    required this.locationHint,
    required this.allStops,
  });

  final Bus bus;
  final BusRoute? route;
  final Stop selectedStop;
  final BusArrivalEstimate arrival;
  final BusStopProgress? progress;
  final String? locationHint;
  final List<Stop> allStops;

  @override
  Widget build(BuildContext context) {
    final details =
        arrival.progressDetails ??
        calculateRouteProgressDetails(
          route: route,
          bus: bus,
          allStops: allStops,
          progress: progress,
        );

    final isAtBoarding = arrival.isAtStop && !bus.isStale;

    final String locationTitle;
    if (arrival.currentPositionText != null &&
        arrival.currentPositionText!.isNotEmpty) {
      locationTitle = arrival.currentPositionText!;
    } else if (bus.isStale) {
      final near = details.currentStop ?? details.previousStop;
      locationTitle =
          near != null
              ? 'Stale location · Near ${near.name}'
              : (locationHint != null && locationHint!.isNotEmpty
                  ? 'Stale location · Near $locationHint'
                  : 'Stale location · ${route?.name ?? 'Campus bus'}');
    } else if (details.isAtStop && details.currentStop != null) {
      locationTitle = 'At ${details.currentStop!.name}';
    } else if (details.nextStop != null) {
      locationTitle =
          (details.distanceToNextStopMeters != null &&
                  details.distanceToNextStopMeters! < 80.0)
              ? 'Approaching ${details.nextStop!.name}'
              : 'En route to ${details.nextStop!.name}';
    } else if (details.previousStop != null) {
      locationTitle = 'Passed ${details.previousStop!.name}';
    } else {
      final nearest = nearestStopTo(bus.position.point, allStops);
      locationTitle =
          nearest != null
              ? 'Near ${nearest.name}'
              : 'En route · ${route?.name ?? 'Campus bus'}';
    }

    final String locationSubtitle;
    if (arrival.locationSubtitle != null &&
        arrival.locationSubtitle!.isNotEmpty) {
      locationSubtitle = arrival.locationSubtitle!;
    } else if (isAtBoarding) {
      locationSubtitle = 'Bus is at your boarding stop';
    } else if (bus.isStale) {
      locationSubtitle =
          'Last reported ${TransitFormatter.formatLastUpdated(bus.lastUpdated)}';
    } else if (details.previousStop != null &&
        details.nextStop != null &&
        details.distanceToNextStopMeters != null &&
        !details.isAtStop) {
      locationSubtitle =
          'Passed ${details.previousStop!.name} · ${details.distanceToNextStopMeters!.round()}m to ${details.nextStop!.name}';
    } else if (details.orderedStops.isNotEmpty &&
        details.orderedStops
            .sublist(
              (details.currentStopIndex + (details.isAtStop ? 1 : 0)).clamp(
                0,
                details.orderedStops.length,
              ),
            )
            .any((s) => s.id == selectedStop.id)) {
      locationSubtitle = '${selectedStop.name} is ahead on this trip';
    } else {
      locationSubtitle = 'Actual bus position from live GPS';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CURRENT LOCATION',
          style: TextStyle(
            color: TrackletColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: TrackletColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: TrackletColors.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locationTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TrackletColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locationSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TrackletColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isAtBoarding) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: TrackletColors.busLiveBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: TrackletColors.busLive.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: TrackletColors.busLive,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Board here',
                      style: TextStyle(
                        color: TrackletColors.busLive,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// TRIP PROGRESS SECTION (COMPACT 3–4 STOPS TIMELINE)
// ============================================================================

class _TripProgressSection extends StatelessWidget {
  const _TripProgressSection({
    required this.route,
    required this.bus,
    required this.selectedStop,
    required this.progress,
    required this.allStops,
    this.progressDetails,
    this.customPreview,
    this.onViewFullRoute,
  });

  final BusRoute? route;
  final Bus bus;
  final Stop selectedStop;
  final BusStopProgress? progress;
  final List<Stop> allStops;
  final BusRouteProgressDetails? progressDetails;
  final Widget? customPreview;
  final VoidCallback? onViewFullRoute;

  @override
  Widget build(BuildContext context) {
    final details =
        progressDetails ??
        calculateRouteProgressDetails(
          route: route,
          bus: bus,
          allStops: allStops,
          progress: progress,
        );

    final orderedStops = details.orderedStops;
    if (orderedStops.isEmpty && customPreview != null) {
      return customPreview!;
    }
    if (orderedStops.isEmpty) {
      return const SizedBox.shrink();
    }

    // Select timeline window: if boarding stop is upcoming on the remaining journey
    // within 6 stops, display the journey leading from current bus location to the boarding stop.
    final n = orderedStops.length;
    final int startIdx;
    final int count;
    final c = details.continuousProgressIndex;
    final busIdx = c.floor().clamp(0, n - 1);
    final nextBoardingIdx = orderedStops.indexWhere(
      (s) => s.id == selectedStop.id,
      busIdx,
    );

    if (nextBoardingIdx > busIdx && (nextBoardingIdx - busIdx + 1) <= 6) {
      var sIdx = busIdx;
      if ((nextBoardingIdx - busIdx + 1) < 3 && busIdx > 0) {
        sIdx = busIdx - 1;
      }
      startIdx = sIdx;
      count = nextBoardingIdx - startIdx + 1;
    } else if (n <= 4) {
      startIdx = 0;
      count = n;
    } else {
      if (c <= 1.5) {
        startIdx = 0;
        count = 4;
      } else if (c >= n - 2.5) {
        startIdx = n - 4;
        count = 4;
      } else {
        startIdx = (c.floor() - 1).clamp(0, n - 4);
        count = 4;
      }
    }

    final displayStops = orderedStops.sublist(startIdx, startIdx + count);

    return Container(
      decoration: BoxDecoration(
        color: TrackletColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TrackletColors.border.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TRIP PROGRESS',
                style: TextStyle(
                  color: TrackletColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              if (onViewFullRoute != null)
                InkWell(
                  onTap: onViewFullRoute,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'View full route',
                      style: TextStyle(
                        color: TrackletColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _TimelineRow(
            stops: displayStops,
            startIndex: startIdx,
            continuousIndex: details.continuousProgressIndex,
            selectedStopId: selectedStop.id,
            isAtStop: details.isAtStop,
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.stops,
    required this.startIndex,
    required this.continuousIndex,
    required this.selectedStopId,
    required this.isAtStop,
  });

  final List<Stop> stops;
  final int startIndex;
  final double continuousIndex;
  final String selectedStopId;
  final bool isAtStop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = stops.length;
        if (count == 0) return const SizedBox.shrink();

        // Bus position relative to this visible 3-4 stop window
        final relativeBus = (continuousIndex - startIndex).clamp(
          0.0,
          (count - 1).toDouble(),
        );

        const nodeSize = 14.0;
        const busSize = 28.0;
        final totalWidth = constraints.maxWidth;
        final trackWidth = totalWidth - busSize;
        final step = count > 1 ? trackWidth / (count - 1) : 0.0;

        double nodeCenterX(int index) => (busSize / 2) + index * step;
        final busCenterX = (busSize / 2) + relativeBus * step;
        final busLeft = (busCenterX - (busSize / 2)).clamp(
          0.0,
          totalWidth - busSize,
        );

        return Column(
          children: [
            // Progress line with stop node indicators and floating live bus
            SizedBox(
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // 1. Inactive background track line connecting all nodes
                  Positioned(
                    left: nodeCenterX(0),
                    width: (nodeCenterX(count - 1) - nodeCenterX(0)).clamp(
                      0.0,
                      totalWidth,
                    ),
                    top: 12.5,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: TrackletColors.border,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),

                  // 2. Active along-route progress line up to the bus
                  if (relativeBus > 0.01)
                    Positioned(
                      left: nodeCenterX(0),
                      width: (busCenterX - nodeCenterX(0)).clamp(
                        0.0,
                        totalWidth,
                      ),
                      top: 12.5,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: TrackletColors.primary,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),

                  // 3. Stop node circles
                  for (var i = 0; i < count; i++)
                    Positioned(
                      left: nodeCenterX(i) - (nodeSize / 2),
                      top: 7,
                      child: _buildStopNodeCircle(
                        isPassed: i < relativeBus - 0.15,
                        isNearBus: (i - relativeBus).abs() <= 0.15,
                      ),
                    ),

                  // 4. Floating Live Bus Icon positioned by distance!
                  Positioned(
                    left: busLeft,
                    top: 0,
                    child: _buildBusIcon(isAtStop: isAtStop),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Stop Names & Labels
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < count; i++) ...[
                  Expanded(
                    child: _buildStopLabel(
                      stop: stops[i],
                      absoluteIndex: startIndex + i,
                      relativeIndex: i,
                      relativeBus: relativeBus,
                      isBoarding: stops[i].id == selectedStopId,
                      isAtStop: isAtStop,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStopNodeCircle({
    required bool isPassed,
    required bool isNearBus,
  }) {
    if (isNearBus) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: isPassed ? TrackletColors.primary : TrackletColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isPassed ? TrackletColors.primary : TrackletColors.border,
            width: 2.2,
          ),
        ),
      );
    }

    if (isPassed) {
      return Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: TrackletColors.primary,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: TrackletColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: TrackletColors.border, width: 2.5),
      ),
    );
  }

  Widget _buildBusIcon({required bool isAtStop}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: TrackletColors.background2,
        shape: BoxShape.circle,
        border: Border.all(color: TrackletColors.primary, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: TrackletColors.primary.withValues(alpha: 0.28),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.directions_bus_rounded,
          size: 15,
          color: TrackletColors.primary,
        ),
      ),
    );
  }

  Widget _buildStopLabel({
    required Stop stop,
    required int absoluteIndex,
    required int relativeIndex,
    required double relativeBus,
    required bool isBoarding,
    required bool isAtStop,
  }) {
    final diff = relativeIndex - relativeBus;
    final isCurrent = diff.abs() <= 0.15;
    final isPrevious =
        !isCurrent && diff < 0 && (relativeBus - relativeIndex) < 1.15;
    final isPassed = !isCurrent && diff < -1.15;
    final isNext = !isCurrent && diff > 0 && diff < 1.15;

    final String statusText;
    final Color statusColor;

    if (isCurrent && isAtStop) {
      statusText = isBoarding ? 'Board here' : 'Current';
      statusColor =
          isBoarding ? TrackletColors.busLive : TrackletColors.primary;
    } else if (isBoarding && (isPassed || isPrevious)) {
      statusText = 'Passed';
      statusColor = TrackletColors.textTertiary;
    } else if (isBoarding) {
      statusText = 'Your stop';
      statusColor = TrackletColors.busLive;
    } else if (isCurrent) {
      statusText = 'Current';
      statusColor = TrackletColors.primary;
    } else if (isPrevious) {
      statusText = 'Previous';
      statusColor = TrackletColors.textSecondary;
    } else if (isPassed) {
      statusText = 'Passed';
      statusColor = TrackletColors.textTertiary;
    } else if (isNext) {
      statusText = 'Upcoming';
      statusColor = TrackletColors.textSecondary;
    } else {
      statusText = 'Upcoming';
      statusColor = TrackletColors.textSecondary;
    }

    final isHighlighted = isCurrent || (isBoarding && isAtStop);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Text(
            stop.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  isHighlighted
                      ? TrackletColors.textPrimary
                      : TrackletColors.textSecondary,
              fontSize: 11,
              fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            statusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight:
                  (isHighlighted || isBoarding)
                      ? FontWeight.w700
                      : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FOOTER SECTION: FRESHNESS, SECONDARY ETA & TRACK BUS ACTION
// ============================================================================

class _FooterRow extends StatelessWidget {
  const _FooterRow({
    required this.bus,
    required this.arrival,
    required this.scheduledDeparture,
    required this.onTrackPressed,
  });

  final Bus? bus;
  final BusArrivalEstimate? arrival;
  final ScheduledDeparture? scheduledDeparture;
  final VoidCallback? onTrackPressed;

  @override
  Widget build(BuildContext context) {
    final freshnessText =
        scheduledDeparture != null
            ? 'Scheduled departure · live location unavailable'
            : bus == null
            ? 'Live bus location unavailable'
            : 'Updated ${TransitFormatter.formatLastUpdated(bus!.lastUpdated)}';

    final hasValidEta = arrival?.eta.isValid == true;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: Freshness and Secondary ETA
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: TrackletColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      freshnessText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TrackletColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              if (hasValidEta) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${arrival!.eta.minutes}',
                      style: const TextStyle(
                        color: TrackletColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'MIN',
                      style: TextStyle(
                        color: TrackletColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(~${arrival!.eta.minutes} min away)',
                      style: const TextStyle(
                        color: TrackletColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ] else if (scheduledDeparture != null) ...[
                Text(
                  'Departing at ${scheduledDeparture!.formattedTime}',
                  style: const TextStyle(
                    color: TrackletColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else ...[
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ETA',
                      style: TextStyle(
                        color: TrackletColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Unavailable',
                      style: TextStyle(
                        color: TrackletColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Right Primary Action Button: Track bus ↗
        ElevatedButton(
          onPressed:
              onTrackPressed == null
                  ? null
                  : () {
                    HapticFeedback.lightImpact();
                    onTrackPressed!();
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: TrackletColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                bus == null ? 'Open map' : 'Track bus',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.north_east_rounded,
                size: 13,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// STATUS PILL COMPONENT
// ============================================================================

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.status,
    required this.isStale,
    this.isRouteUncertain = false,
  });

  final BusStatus status;
  final bool isStale;
  final bool isRouteUncertain;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    final Color background;
    final IconData icon;

    if (isStale) {
      label = 'Stale';
      color = TrackletColors.textSecondary;
      background = TrackletColors.alternate;
      icon = Icons.history_rounded;
    } else if (isRouteUncertain) {
      label = 'Route uncertain';
      color = TrackletColors.warningStrong;
      background = TrackletColors.notificationYellowBg;
      icon = Icons.help_outline_rounded;
    } else {
      switch (status) {
        case BusStatus.live:
          label = 'Live';
          color = TrackletColors.busLive;
          background = TrackletColors.busLiveBg;
          icon = Icons.sensors_rounded;
          break;
        case BusStatus.delayed:
          label = 'Delayed';
          color = TrackletColors.busDelayed;
          background = TrackletColors.busDelayedBg;
          icon = Icons.warning_amber_rounded;
          break;
        case BusStatus.due:
          label = 'At stop';
          color = TrackletColors.busDue;
          background = TrackletColors.busDueBg;
          icon = Icons.directions_bus_rounded;
          break;
        case BusStatus.offline:
          label = 'Offline';
          color = TrackletColors.busOffline;
          background = TrackletColors.busOfflineBg;
          icon = Icons.cloud_off_rounded;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FULL ROUTE BOTTOM SHEET MODAL
// ============================================================================

class _FullRouteSheet extends StatelessWidget {
  const _FullRouteSheet({
    required this.route,
    required this.allStops,
    required this.selectedStop,
    required this.progress,
  });

  final BusRoute route;
  final List<Stop> allStops;
  final Stop selectedStop;
  final BusStopProgress? progress;

  @override
  Widget build(BuildContext context) {
    final stopMap = {for (final s in allStops) s.id: s};
    final occurrences = [...route.stopOccurrences]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    final orderedStops = <Stop>[];
    if (occurrences.isNotEmpty) {
      for (final occ in occurrences) {
        final resolved = occ.stop ?? stopMap[occ.stopId];
        if (resolved != null) orderedStops.add(resolved);
      }
    } else {
      for (final id in route.stopIds) {
        final resolved = stopMap[id];
        if (resolved != null) orderedStops.add(resolved);
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: TrackletColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: TrackletColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: const TextStyle(
                          color: TrackletColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${route.code} · ${orderedStops.length} campus stops',
                        style: const TextStyle(
                          color: TrackletColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TrackletColors.border),
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: orderedStops.length,
              separatorBuilder:
                  (context, index) => const Divider(
                    height: 1,
                    indent: 36,
                    color: TrackletColors.border,
                  ),
              itemBuilder: (context, index) {
                final s = orderedStops[index];
                final currentBusStopIndex =
                    progress?.currentStopId != null
                        ? occurrences.indexWhere(
                          (o) =>
                              o.stopId == progress!.currentStopId &&
                              (progress!.nextStop == null ||
                                  o.sequence < progress!.nextStop!.sequence),
                        )
                        : -1;
                final nextBoardingStopIndex =
                    currentBusStopIndex >= 0
                        ? orderedStops.indexWhere(
                          (stop) => stop.id == selectedStop.id,
                          currentBusStopIndex,
                        )
                        : orderedStops.indexWhere(
                          (stop) => stop.id == selectedStop.id,
                        );

                final isCurrent =
                    currentBusStopIndex >= 0
                        ? index == currentBusStopIndex &&
                            progress?.currentStopId == s.id
                        : progress?.currentStopId == s.id;
                final isBoarding = index == nextBoardingStopIndex;
                final isPassed =
                    currentBusStopIndex >= 0
                        ? index < currentBusStopIndex
                        : progress?.visitedStopIds.contains(s.id) == true;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color:
                              isCurrent
                                  ? TrackletColors.primary
                                  : isBoarding
                                  ? TrackletColors.busLive
                                  : isPassed
                                  ? TrackletColors.textTertiary
                                  : TrackletColors.border,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          s.name,
                          style: TextStyle(
                            color:
                                isCurrent || isBoarding
                                    ? TrackletColors.textPrimary
                                    : TrackletColors.textSecondary,
                            fontSize: 15,
                            fontWeight:
                                isCurrent || isBoarding
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isCurrent) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: TrackletColors.background2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Bus location',
                            style: TextStyle(
                              color: TrackletColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ] else if (isBoarding) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: TrackletColors.busLiveBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Your stop',
                            style: TextStyle(
                              color: TrackletColors.busLive,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SCHEDULED DEPARTURE SUMMARY & NO ARRIVAL FALLBACKS
// ============================================================================

class _ScheduledDepartureSummary extends StatelessWidget {
  const _ScheduledDepartureSummary({
    required this.departure,
    required this.route,
  });

  final ScheduledDeparture departure;
  final BusRoute route;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              route.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TrackletColors.textPrimary,
                fontSize: 16,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              departure.isSpecial
                  ? 'Special scheduled departure'
                  : 'Scheduled route departure',
              style: const TextStyle(
                color: TrackletColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: TrackletColors.busDueBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          departure.formattedTime,
          style: const TextStyle(
            color: TrackletColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ],
  );
}

class _NoArrival extends StatelessWidget {
  const _NoArrival({required this.stop});

  final Stop stop;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(
        Icons.schedule_rounded,
        color: TrackletColors.primary,
        size: 23,
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Text(
          'No active buses are serving ${stop.name} right now.',
          style: const TextStyle(
            color: TrackletColors.textSecondary,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
