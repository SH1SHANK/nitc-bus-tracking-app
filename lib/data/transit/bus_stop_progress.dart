import 'bus_stop_event.dart';
import 'route_stop_occurrence.dart';

class BusStopProgress {
  const BusStopProgress({
    required this.visitedStopIds,
    required this.currentStopId,
    required this.nextStop,
    required this.upcomingStops,
    required this.direction,
    this.isLoopRoute = false,
    this.lastEventType,
    this.lastEventAt,
  });

  final Set<String> visitedStopIds;
  final String? currentStopId;
  final RouteStopOccurrence? nextStop;
  final List<RouteStopOccurrence> upcomingStops;
  final String direction;
  final bool isLoopRoute;
  final String? lastEventType;
  final DateTime? lastEventAt;
}

BusStopProgress? resolveBusStopProgress({
  required List<RouteStopOccurrence> routeStops,
  required List<BusStopEvent> events,
  required String direction,
}) {
  final stops = [...routeStops]
    ..sort((a, b) => a.sequence.compareTo(b.sequence));
  if (stops.isEmpty || events.isEmpty) return null;
  final isLoop = stops.length > 1 && stops.first.stopId == stops.last.stopId;
  final cycleLength = isLoop ? stops.length - 1 : stops.length;
  final orderedEvents = [...events]
    ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

  final forward = _resolveDirection(
    stops,
    cycleLength,
    isLoop,
    orderedEvents,
    false,
  );
  final reverse = _resolveDirection(
    stops,
    cycleLength,
    isLoop,
    orderedEvents,
    true,
  );
  if (forward == null) return reverse?.progress;
  if (reverse == null) return forward.progress;
  if (forward.skippedStops < reverse.skippedStops) return forward.progress;
  if (reverse.skippedStops < forward.skippedStops) return reverse.progress;
  final configuredReverse =
      direction.toLowerCase() == 'reverse' ||
      direction.toLowerCase() == 'backward';
  final forwardNext = forward.progress.nextStop?.sequence;
  final reverseNext = reverse.progress.nextStop?.sequence;
  if (forwardNext != reverseNext &&
      (forwardNext != null && reverseNext != null)) {
    return null;
  }
  // The route direction is the only remaining directional evidence on ties.
  return configuredReverse ? reverse.progress : forward.progress;
}

({BusStopProgress progress, int skippedStops})? _resolveDirection(
  List<RouteStopOccurrence> stops,
  int cycleLength,
  bool isLoop,
  List<BusStopEvent> orderedEvents,
  bool reverse,
) {
  var cursor = -1;
  var skippedStops = 0;
  var lastType = '';
  DateTime? lastEventAt;
  for (final event in orderedEvents) {
    if (event.type != 'arrived' && event.type != 'departed') continue;
    lastEventAt = event.occurredAt;
    if (cursor >= 0 &&
        stops[cursor].stopId == event.stopId &&
        lastType == 'arrived' &&
        event.type == 'departed') {
      lastType = event.type;
      continue;
    }
    var matched = false;
    for (var offset = 0; offset < cycleLength; offset++) {
      final rawIndex =
          cursor < 0
              ? (reverse ? cycleLength - 1 - offset : offset)
              : cursor + (reverse ? -(offset + 1) : offset + 1);
      if (!isLoop && (rawIndex < 0 || rawIndex >= cycleLength)) break;
      final index = (rawIndex + cycleLength) % cycleLength;
      if (stops[index].stopId == event.stopId) {
        cursor = index;
        if (offset > 0 && lastType.isNotEmpty) skippedStops += offset;
        matched = true;
        break;
      }
    }
    if (!matched) return null;
    lastType = event.type;
  }
  if (cursor < 0) return null;

  final rawNextIndex = cursor + (reverse ? -1 : 1);
  final hasNext = isLoop || (rawNextIndex >= 0 && rawNextIndex < cycleLength);
  final nextIndex =
      isLoop ? (rawNextIndex + cycleLength) % cycleLength : rawNextIndex;
  final next = hasNext ? stops[nextIndex] : null;
  final upcoming = <RouteStopOccurrence>[];
  if (hasNext) {
    for (
      var count = 0, index = nextIndex;
      count < cycleLength - 1 &&
          (isLoop || (reverse ? index >= 0 : index < cycleLength));
      count++,
      index =
          isLoop
              ? (index + (reverse ? -1 : 1) + cycleLength) % cycleLength
              : index + (reverse ? -1 : 1)
    ) {
      upcoming.add(stops[index]);
    }
  }

  final visited = <String>{};
  for (
    var index = reverse ? cycleLength - 1 : 0;
    index != cursor;
    index += reverse ? -1 : 1
  ) {
    if (index >= 0 && index < cycleLength) visited.add(stops[index].stopId);
  }
  return (
    progress: BusStopProgress(
      visitedStopIds: visited,
      currentStopId: lastType == 'arrived' ? stops[cursor].stopId : null,
      nextStop: next,
      upcomingStops: upcoming,
      direction: reverse ? 'reverse' : 'forward',
      isLoopRoute: isLoop,
      lastEventType: lastType,
      lastEventAt: lastEventAt,
    ),
    skippedStops: skippedStops,
  );
}
