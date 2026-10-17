import 'package:flutter/material.dart';

import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_eta.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/bus_stop_progress.dart';
import '../../../data/transit/bus_telemetry.dart';
import '../../../data/transit/route_stop_occurrence.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/components/icons/tracklet_icons.dart';
import '../home_transit_logic.dart';

/// A compact stop-by-stop timeline for the selected bus route.
class LiveBusRoutePreview extends StatelessWidget {
  const LiveBusRoutePreview({
    super.key,
    required this.route,
    required this.stop,
    required this.stops,
    required this.bus,
    this.destinationStop,
    this.progress,
  });

  final BusRoute? route;
  final Stop stop;
  final List<Stop> stops;
  final Bus? bus;
  final Stop? destinationStop;
  final BusStopProgress? progress;

  @override
  Widget build(BuildContext context) {
    final stopById = {for (final item in stops) item.id: item};
    final routeStopIds = route?.stopIds ?? const <String>[];
    final routeStops =
        routeStopIds.map((id) => stopById[id]).whereType<Stop>().toList();
    final isLoopRoute =
        routeStopIds.length > 1 && routeStopIds.first == routeStopIds.last;
    final routeOccurrences = [...?route?.stopOccurrences]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    if (isLoopRoute && routeStops.length > 1) {
      routeStops.removeLast();
    }
    final selectedIndex = routeStops.indexWhere((item) => item.id == stop.id);
    final previousStopIndices = List<int?>.generate(2, (index) {
      if (selectedIndex < 0 || routeStops.length < 2) return null;
      final targetIndex = selectedIndex - (2 - index);
      if (isLoopRoute) {
        return (targetIndex + routeStops.length) % routeStops.length;
      }
      return targetIndex >= 0 ? targetIndex : null;
    });
    final previousStops =
        previousStopIndices
            .map((index) => index == null ? null : routeStops[index])
            .toList();
    final nextStops = <Stop>[];
    final nextStopIndices = <int?>[];
    if (selectedIndex >= 0 && routeStops.length > 1) {
      final remainingStops =
          isLoopRoute
              ? routeStops.length - 1
              : routeStops.length - selectedIndex - 1;
      for (var offset = 1; offset <= remainingStops; offset++) {
        final targetIndex = selectedIndex + offset;
        final index =
            isLoopRoute ? targetIndex % routeStops.length : targetIndex;
        nextStops.add(routeStops[index]);
        nextStopIndices.add(index);
      }
    }
    final displayedNextStops = nextStops.isEmpty ? <Stop?>[null] : nextStops;
    final displayedNextIndices =
        nextStopIndices.isEmpty ? <int?>[null] : nextStopIndices;
    final searchedDestination = destinationStop;
    final destinationIsServed =
        searchedDestination != null &&
        routeStops.any((item) => item.id == searchedDestination.id);
    final highlightedDestination =
        searchedDestination == null
            ? null
            : destinationIsServed
            ? searchedDestination
            : nearestStopTo(searchedDestination.location, routeStops);
    final routeLabel = route?.name ?? 'Campus route';
    final currentBus = bus;
    var eventBusStopId = progress?.currentStopId;
    if (eventBusStopId == null &&
        progress?.lastEventType == 'departed' &&
        progress?.nextStop != null) {
      final reverse = progress!.direction == 'reverse';
      final departedSequence =
          progress!.nextStop!.sequence + (reverse ? 1 : -1);
      eventBusStopId =
          route?.stopOccurrences
              .where((occurrence) => occurrence.sequence == departedSequence)
              .firstOrNull
              ?.stopId;
    }
    final nearestGpsStop =
        currentBus == null ||
                !BusTelemetry.isValidPoint(currentBus.position.point)
            ? null
            : nearestStopTo(currentBus.position.point, routeStops);
    final gpsStopIsNear =
        nearestGpsStop != null &&
        currentBus != null &&
        currentBus.position.point.distanceToMeters(nearestGpsStop.location) <=
            RouteProgressProjector.maxOffRouteMeters;
    final busStopId = gpsStopIsNear ? nearestGpsStop.id : eventBusStopId;
    final busStopRouteIndex =
        busStopId == null
            ? -1
            : routeStops.indexWhere((item) => item.id == busStopId);
    final visitedStopIds = progress?.visitedStopIds ?? const <String>{};

    Widget timeline() {
      return LayoutBuilder(
        builder: (context, constraints) {
          const nodeWidth = 104.0;
          const segmentWidth = 24.0;
          final nodes = <Stop?>[...previousStops, stop, ...displayedNextStops];
          final nodeRouteIndices = <int?>[
            ...previousStopIndices,
            selectedIndex < 0 ? null : selectedIndex,
            ...displayedNextIndices,
          ];
          final contentWidth =
              nodes.length * nodeWidth + (nodes.length - 1) * segmentWidth;

          return SizedBox(
            height: 104,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width:
                    contentWidth < constraints.maxWidth
                        ? constraints.maxWidth
                        : contentWidth,
                height: 104,
                child: Row(
                  children: [
                    for (var index = 0; index < nodes.length; index++) ...[
                      SizedBox(
                        width: nodeWidth,
                        child: _RouteStopNode(
                          stop: nodes[index],
                          positionLabel: _positionLabel(
                            index: index,
                            boardingIndex: previousStops.length,
                            node: nodes[index],
                            nodeRouteIndex: nodeRouteIndices[index],
                            occurrences: routeOccurrences,
                            isBusStopNode:
                                busStopRouteIndex >= 0 &&
                                nodeRouteIndices[index] == busStopRouteIndex,
                            gpsStopIsNear: gpsStopIsNear,
                            progress: progress,
                            visitedStopIds: visitedStopIds,
                          ),
                          isBoardingStop: index == previousStops.length,
                          isBusStop:
                              busStopRouteIndex >= 0 &&
                              nodeRouteIndices[index] == busStopRouteIndex,
                          isDestination:
                              nodes[index]?.id == highlightedDestination?.id,
                          isClosestDestination:
                              !destinationIsServed &&
                              nodes[index]?.id == highlightedDestination?.id,
                        ),
                      ),
                      if (index < nodes.length - 1)
                        Container(
                          width: segmentWidth,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 88),
                          color:
                              visitedStopIds.contains(nodes[index]?.id)
                                  ? TrackletColors.primary
                                  : TrackletColors.adaptiveBorder(context),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final routeTracker = timeline();
    final textSecondary = TrackletColors.adaptiveTextSecondary(context);

    return Semantics(
      container: true,
      label:
          searchedDestination == null
              ? '$routeLabel route tracker. ${routeStops.length} stops. Boarding at ${stop.name}.'
              : '$routeLabel route tracker. Boarding at ${stop.name}. ${destinationIsServed ? 'Destination' : 'Estimated closest stop to ${searchedDestination.name}'}: ${highlightedDestination?.name ?? 'unavailable'}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ROUTE TRACKER',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (route != null)
                Text(
                  route!.code,
                  style: const TextStyle(
                    color: TrackletColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (searchedDestination != null) ...[
            const SizedBox(height: 7),
            Text(
              destinationIsServed
                  ? '${searchedDestination.name} is on this route'
                  : 'Estimated closest route stop to ${searchedDestination.name}: ${highlightedDestination?.name ?? 'unavailable'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 13),
          routeTracker,
        ],
      ),
    );
  }

  String _positionLabel({
    required int index,
    required int boardingIndex,
    required Stop? node,
    required int? nodeRouteIndex,
    required List<RouteStopOccurrence> occurrences,
    required bool isBusStopNode,
    required bool gpsStopIsNear,
    required BusStopProgress? progress,
    required Set<String> visitedStopIds,
  }) {
    if (index == boardingIndex &&
        isBusStopNode &&
        (gpsStopIsNear || progress?.currentStopId == node?.id)) {
      return 'Board here';
    }
    if (isBusStopNode) {
      if (gpsStopIsNear) return 'Bus near';
      if (progress?.currentStopId == node?.id) return 'Bus here';
      if (progress?.lastEventType == 'departed') return 'Last departed';
    }
    if (index == boardingIndex) return 'Board here';
    final sequence =
        nodeRouteIndex != null && nodeRouteIndex < occurrences.length
            ? occurrences[nodeRouteIndex].sequence
            : nodeRouteIndex;
    if (sequence != null && progress?.nextStop?.sequence == sequence) {
      return 'Next stop';
    }
    if (node != null && visitedStopIds.contains(node.id)) return 'Passed';
    if (index < boardingIndex) return 'Earlier stop';
    return 'Upcoming';
  }
}

class _RouteStopNode extends StatelessWidget {
  const _RouteStopNode({
    required this.stop,
    required this.positionLabel,
    required this.isBoardingStop,
    required this.isDestination,
    required this.isClosestDestination,
    this.isBusStop = false,
  });

  final Stop? stop;
  final String positionLabel;
  final bool isBoardingStop;
  final bool isDestination;
  final bool isClosestDestination;
  final bool isBusStop;

  @override
  Widget build(BuildContext context) {
    final isDark = TrackletColors.isDark(context);
    final textPrimary = TrackletColors.adaptiveTextPrimary(context);
    final textSecondary = TrackletColors.adaptiveTextSecondary(context);
    final textMuted = TrackletColors.adaptiveTextMuted(context);

    final accent =
        isBusStop
            ? TrackletColors.busLive
            : isBoardingStop
            ? TrackletColors.primary
            : TrackletColors.secondary;
    final isHighlighted = isBoardingStop || isDestination || isBusStop;
    final accessibleLabel =
        stop == null
            ? '$positionLabel unavailable'
            : [
              stop!.name,
              positionLabel,
              if (isDestination)
                isClosestDestination
                    ? 'closest stop to destination'
                    : 'destination',
            ].join(', ');

    return Column(
      children: [
        SizedBox(
          height: 32,
          child: Center(
            child: Semantics(
              label: accessibleLabel,
              selected: isBoardingStop || isDestination || isBusStop,
              child: Container(
                width: isHighlighted ? 22 : 14,
                height: isHighlighted ? 22 : 14,
                decoration: BoxDecoration(
                  color:
                      isHighlighted
                          ? TrackletColors.adaptiveSurfaceElevated(context)
                          : (isDark
                              ? TrackletColors.darkSurfaceContainerHighest
                              : TrackletColors.alternate),
                  shape: BoxShape.circle,
                  border:
                      isHighlighted
                          ? Border.all(
                            color: isBusStop ? TrackletColors.busLive : accent,
                            width: isBusStop ? 2 : 4,
                          )
                          : null,
                  boxShadow:
                      isBoardingStop
                          ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child:
                    isBusStop
                        ? const Icon(
                          TrackletIcons.bus,
                          size: 12,
                          color: TrackletColors.busLive,
                        )
                        : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          stop?.name ?? '—',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isHighlighted ? textPrimary : textSecondary,
            fontSize: 11,
            height: 1.2,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          positionLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isBoardingStop || isBusStop ? accent : textMuted,
            fontSize: 10,
            fontWeight:
                isBoardingStop || isBusStop ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
