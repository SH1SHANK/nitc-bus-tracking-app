import 'stop.dart';

/// Represents an ordered stop occurrence along a transit route.
///
/// Handles repeated stop occurrences natively (e.g., loops passing the same stop twice).
class RouteStopOccurrence {
  const RouteStopOccurrence({
    required this.routeId,
    required this.stopId,
    required this.sequence,
    this.stop,
    this.distanceFromStart,
    this.estimatedDurationSec,
  });

  final String routeId;
  final String stopId;
  final int sequence;
  final Stop? stop;
  final double? distanceFromStart;
  final int? estimatedDurationSec;

  RouteStopOccurrence copyWith({
    String? routeId,
    String? stopId,
    int? sequence,
    Stop? stop,
    double? distanceFromStart,
    int? estimatedDurationSec,
  }) {
    return RouteStopOccurrence(
      routeId: routeId ?? this.routeId,
      stopId: stopId ?? this.stopId,
      sequence: sequence ?? this.sequence,
      stop: stop ?? this.stop,
      distanceFromStart: distanceFromStart ?? this.distanceFromStart,
      estimatedDurationSec: estimatedDurationSec ?? this.estimatedDurationSec,
    );
  }

  Map<String, dynamic> toJson() => {
    'route_id': routeId,
    'stop_id': stopId,
    'sequence': sequence,
    'distance_from_start': distanceFromStart,
    'estimated_duration_sec': estimatedDurationSec,
    if (stop != null) 'stop': stop!.toJson(),
  };

  factory RouteStopOccurrence.fromJson(
    Map<String, dynamic> json, {
    Stop? stop,
  }) {
    final nestedStop =
        json['stops'] is Map<String, dynamic>
            ? Stop.fromJson(json['stops'] as Map<String, dynamic>)
            : stop;

    return RouteStopOccurrence(
      routeId: json['route_id']?.toString() ?? '',
      stopId: json['stop_id']?.toString() ?? '',
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      stop: nestedStop,
      distanceFromStart: (json['distance_from_start'] as num?)?.toDouble(),
      estimatedDurationSec: (json['estimated_duration_sec'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteStopOccurrence &&
          runtimeType == other.runtimeType &&
          routeId == other.routeId &&
          stopId == other.stopId &&
          sequence == other.sequence;

  @override
  int get hashCode => Object.hash(routeId, stopId, sequence);

  @override
  String toString() =>
      'RouteStopOccurrence(route: $routeId, stop: $stopId, seq: $sequence)';
}
