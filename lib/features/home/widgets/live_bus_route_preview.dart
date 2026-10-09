import 'package:flutter/material.dart';

import '../../../data/transit/bus.dart';
import '../../../data/transit/bus_route.dart';
import '../../../data/transit/stop.dart';
import '../../../design_system/tokens/colors.dart';
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
  });

  final BusRoute? route;
  final Stop stop;
  final List<Stop> stops;
  final Bus? bus;
  final Stop? destinationStop;

  @override
  Widget build(BuildContext context) {
    final stopById = {for (final item in stops) item.id: item};
    final routeStops =
        route?.stopIds.map((id) => stopById[id]).whereType<Stop>().toList() ??
        <Stop>[];
    if (routeStops.length > 1 && routeStops.first.id == routeStops.last.id) {
      routeStops.removeLast();
    }
    final selectedIndex = routeStops.indexWhere((item) => item.id == stop.id);
    final previousStops = List<Stop?>.generate(2, (index) {
      if (selectedIndex < 0 || routeStops.length < 2) return null;
      final offset = 2 - index;
      return routeStops[(selectedIndex - offset + routeStops.length * 2) %
          routeStops.length];
    });
    final nextStops = <Stop>[];
    if (selectedIndex >= 0 && routeStops.length > 1) {
      for (var offset = 1; offset < routeStops.length; offset++) {
        nextStops.add(routeStops[(selectedIndex + offset) % routeStops.length]);
      }
    }
    final displayedNextStops = nextStops.isEmpty ? <Stop?>[null] : nextStops;
    final searchedDestination = destinationStop;
    final destinationIsServed =
        searchedDestination != null &&
        routeStops.any((item) => item.id == searchedDestination.id);
    final highlightedDestination = searchedDestination == null
        ? null
        : destinationIsServed
        ? searchedDestination
        : nearestStopTo(searchedDestination.location, routeStops);
    final routeLabel = route?.name ?? 'Campus route';

    Widget timeline() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final anchorWidth = constraints.maxWidth / 5;
          const nextStopWidth = 104.0;
          final contentWidth =
              anchorWidth * 3 + nextStopWidth * displayedNextStops.length;

          return SizedBox(
            height: 104,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: contentWidth,
                height: 104,
                child: Stack(
                  children: [
                    if (nextStops.isNotEmpty)
                      Positioned(
                        left: anchorWidth / 2,
                        right: nextStopWidth / 2,
                        top: 15,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: TrackletColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        for (
                          var index = 0;
                          index < previousStops.length;
                          index++
                        )
                          SizedBox(
                            width: anchorWidth,
                            child: _RouteStopNode(
                              stop: previousStops[index],
                              positionLabel: index == 0
                                  ? '2 stops back'
                                  : 'Last stop',
                              isBoardingStop: false,
                              isDestination:
                                  previousStops[index]?.id ==
                                  highlightedDestination?.id,
                              isClosestDestination:
                                  !destinationIsServed &&
                                  previousStops[index]?.id ==
                                      highlightedDestination?.id,
                            ),
                          ),
                        SizedBox(
                          width: anchorWidth,
                          child: _RouteStopNode(
                            stop: stop,
                            positionLabel: 'Board here',
                            isBoardingStop: true,
                            isDestination:
                                stop.id == highlightedDestination?.id,
                            isClosestDestination:
                                !destinationIsServed &&
                                stop.id == highlightedDestination?.id,
                          ),
                        ),
                        for (final nextStop in displayedNextStops)
                          SizedBox(
                            width: nextStopWidth,
                            child: _RouteStopNode(
                              stop: nextStop,
                              positionLabel: 'Next stop',
                              isBoardingStop: false,
                              isDestination:
                                  nextStop?.id == highlightedDestination?.id,
                              isClosestDestination:
                                  !destinationIsServed &&
                                  nextStop?.id == highlightedDestination?.id,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final routeTracker = timeline();

    return Semantics(
      container: true,
      label: searchedDestination == null
          ? '$routeLabel route tracker. ${routeStops.length} stops. Boarding at ${stop.name}.'
          : '$routeLabel route tracker. Boarding at ${stop.name}. ${destinationIsServed ? 'Destination' : 'Closest stop to ${searchedDestination.name}'}: ${highlightedDestination?.name ?? 'unavailable'}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ROUTE TRACKER',
                  style: TextStyle(
                    color: TrackletColors.textSecondary,
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
                  : 'Closest route stop to ${searchedDestination.name}: ${highlightedDestination?.name ?? 'unavailable'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TrackletColors.textSecondary,
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
}

class _RouteStopNode extends StatelessWidget {
  const _RouteStopNode({
    required this.stop,
    required this.positionLabel,
    required this.isBoardingStop,
    required this.isDestination,
    required this.isClosestDestination,
  });

  final Stop? stop;
  final String positionLabel;
  final bool isBoardingStop;
  final bool isDestination;
  final bool isClosestDestination;

  @override
  Widget build(BuildContext context) {
    final accent = isBoardingStop
        ? TrackletColors.primary
        : TrackletColors.secondary;
    final isHighlighted = isBoardingStop || isDestination;
    final accessibleLabel = stop == null
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
              selected: isBoardingStop || isDestination,
              child: Container(
                width: isHighlighted ? 20 : 14,
                height: isHighlighted ? 20 : 14,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? TrackletColors.surface
                      : TrackletColors.alternate,
                  shape: BoxShape.circle,
                  border: isHighlighted
                      ? Border.all(color: accent, width: 4)
                      : null,
                  boxShadow: isBoardingStop
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
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
            color: isHighlighted
                ? TrackletColors.textPrimary
                : TrackletColors.textSecondary,
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
            color: isBoardingStop ? accent : TrackletColors.textTertiary,
            fontSize: 10,
            fontWeight: isBoardingStop ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
