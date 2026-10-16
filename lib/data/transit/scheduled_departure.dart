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
    this.busNumber,
  });

  final String id;
  final String routeId;
  final int hour;
  final int minute;
  final int second;
  final bool isSpecial;
  final int sortOrder;
  final String? busNumber;

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

    final rawBusId = json['bus_id']?.toString();
    final rawRouteId = json['route_id']?.toString();
    const busToRoute = {
      '412d0b2c-fa7e-4b2b-a584-7368976c367d':
          '10000000-0000-4000-8000-000000000001', // Bus 1 -> R1 (East ↔ MBH)
      '8a3970be-2e40-4010-901d-1f53e6e8b2a5':
          '10000000-0000-4000-8000-000000000001', // Bus 2 -> R1 (East ↔ MBH)
      'a54ce8f3-7be3-4198-926b-37a5502fa132':
          '20000000-0000-4000-8000-000000000002', // Bus 3 -> R2 (East ↔ LH)
      '18b31782-e38a-4942-9d25-bc814d7248aa':
          '20000000-0000-4000-8000-000000000002', // Bus 4 -> R2 (East ↔ LH)
      '30275530-8cea-46ea-9949-ca7b01592aae':
          '30000000-0000-4000-8000-000000000003', // A/C 1 -> R3 (Architecture ↔ LH)
      '5012969a-d3a2-4961-bb92-a0519c82cb7b':
          '40000000-0000-4000-8000-000000000004', // A/C 2 -> R4 (Architecture ↔ MBH)
    };
    final routeId =
        rawRouteId ??
        (rawBusId != null ? busToRoute[rawBusId] : null) ??
        rawBusId ??
        '';
    const busIdToNumber = {
      '412d0b2c-fa7e-4b2b-a584-7368976c367d': 'Bus 1',
      '8a3970be-2e40-4010-901d-1f53e6e8b2a5': 'Bus 2',
      'a54ce8f3-7be3-4198-926b-37a5502fa132': 'Bus 3',
      '18b31782-e38a-4942-9d25-bc814d7248aa': 'Bus 4',
      '30275530-8cea-46ea-9949-ca7b01592aae': 'A/C 1',
      '5012969a-d3a2-4961-bb92-a0519c82cb7b': 'A/C 2',
    };
    final busNumber =
        (json['bus_number'] ??
                (rawBusId != null ? busIdToNumber[rawBusId] : null))
            as String?;
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
      busNumber: busNumber,
    );
  }
}
