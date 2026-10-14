/// A backend-recorded trip event tied to a route stop.
class BusStopEvent {
  const BusStopEvent({
    required this.stopId,
    required this.type,
    required this.occurredAt,
  });

  final String stopId;
  final String type;
  final DateTime occurredAt;

  factory BusStopEvent.fromJson(Map<String, dynamic> json) => BusStopEvent(
    stopId: json['stop_id']?.toString() ?? '',
    type: json['event_type']?.toString() ?? '',
    occurredAt: DateTime.parse(json['occurred_at'] as String),
  );
}
