/// A timetable departure associated with a route.
///
/// The supplied timetable stores `bus_id` as the route identifier and only
/// provides a route departure time, not per-stop arrival times.
class ScheduledDeparture {
  const ScheduledDeparture({
    required this.id,
    required this.routeId,
    required this.hour,
    required this.minute,
    this.second = 0,
    this.isSpecial = false,
    this.sortOrder = 0,
  });

  final String id;
  final String routeId;
  final int hour;
  final int minute;
  final int second;
  final bool isSpecial;
  final int sortOrder;

  int get secondsAfterMidnight => hour * 3600 + minute * 60 + second;

  String get formattedTime {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final minuteText = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minuteText $period';
  }

  DateTime onDate(DateTime date) =>
      DateTime(date.year, date.month, date.day, hour, minute, second);

  factory ScheduledDeparture.fromJson(Map<String, dynamic> json) {
    final rawTime = json['departure_time'] as String;
    final timeParts = rawTime.split(':');
    if (timeParts.length < 2 || timeParts.length > 3) {
      throw FormatException('Invalid departure_time: $rawTime');
    }

    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final second = timeParts.length == 3 ? int.parse(timeParts[2]) : 0;
    if (hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        second < 0 ||
        second > 59) {
      throw FormatException('Invalid departure_time: $rawTime');
    }

    final routeId = (json['bus_id'] ?? json['route_id']) as String;
    final id =
        (json['timing_id'] ?? json['id'])?.toString() ??
        '$routeId-$rawTime-${json['sort_order'] ?? 0}';

    return ScheduledDeparture(
      id: id,
      routeId: routeId,
      hour: hour,
      minute: minute,
      second: second,
      isSpecial: json['is_special'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
