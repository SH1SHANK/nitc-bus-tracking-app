import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/data/transit/bus_stop_event.dart';
import 'package:tracklet/data/transit/route_stop_occurrence.dart';
import 'package:tracklet/features/map/bus_stop_progress.dart';

RouteStopOccurrence stop(String id, int sequence) =>
    RouteStopOccurrence(routeId: 'route', stopId: id, sequence: sequence);

BusStopEvent event(String id, String type, int second) => BusStopEvent(
  stopId: id,
  type: type,
  occurredAt: DateTime.utc(2026, 10, 14, 10, 0, second),
);

void main() {
  test('resolves current, visited, and next from geofence event order', () {
    final progress = resolveBusStopProgress(
      routeStops: [stop('a', 0), stop('b', 1), stop('c', 2)],
      events: [
        event('a', 'arrived', 1),
        event('a', 'departed', 2),
        event('b', 'arrived', 3),
      ],
      direction: 'forward',
    );

    expect(progress?.visitedStopIds, {'a'});
    expect(progress?.currentStopId, 'b');
    expect(progress?.nextStop?.stopId, 'c');
    expect(progress?.upcomingStops.map((item) => item.stopId), ['c']);
  });

  test(
    'walks reverse direction and resolves repeated stops on loop routes',
    () {
      final reverse = resolveBusStopProgress(
        routeStops: [stop('a', 0), stop('b', 1), stop('c', 2)],
        events: [event('c', 'arrived', 1)],
        direction: 'reverse',
      );
      expect(reverse?.nextStop?.stopId, 'b');

      final loop = resolveBusStopProgress(
        routeStops: [stop('a', 0), stop('b', 1), stop('a', 2)],
        events: [
          event('a', 'arrived', 1),
          event('a', 'departed', 2),
          event('b', 'arrived', 3),
          event('b', 'departed', 4),
          event('a', 'arrived', 5),
        ],
        direction: 'forward',
      );
      expect(loop?.currentStopId, 'a');
      expect(loop?.nextStop?.sequence, 1);
    },
  );

  test(
    'uses ordered trip events to resolve reverse direction or stays unknown',
    () {
      final inferredReverse = resolveBusStopProgress(
        routeStops: [stop('a', 0), stop('b', 1), stop('c', 2)],
        events: [
          event('c', 'arrived', 1),
          event('c', 'departed', 2),
          event('b', 'arrived', 3),
        ],
        direction: 'forward',
      );
      expect(inferredReverse?.direction, 'reverse');
      expect(inferredReverse?.nextStop?.stopId, 'a');

      expect(
        resolveBusStopProgress(
          routeStops: [stop('a', 0), stop('b', 1), stop('c', 2)],
          events: [event('b', 'arrived', 1)],
          direction: 'forward',
        ),
        isNull,
      );
    },
  );

  test(
    'does not infer stop progress without an arrival or departure event',
    () {
      expect(
        resolveBusStopProgress(
          routeStops: [stop('a', 0), stop('b', 1)],
          events: [event('a', 'route_deviation', 1)],
          direction: 'forward',
        ),
        isNull,
      );
    },
  );
}
