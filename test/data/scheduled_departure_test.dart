import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/data/transit/scheduled_departure.dart';

void main() {
  test('parses the supplied timetable record and formats its time', () {
    final departure = ScheduledDeparture.fromJson({
      'timing_id': '000440bb-5edb-4b86-922a-865fd2319fa5',
      'bus_id': '64304048-d693-4d30-94f4-256448b27fac',
      'departure_time': '17:00:00',
      'is_special': false,
      'sort_order': 18,
    });

    expect(departure.id, '000440bb-5edb-4b86-922a-865fd2319fa5');
    expect(departure.routeId, '64304048-d693-4d30-94f4-256448b27fac');
    expect(departure.formattedTime, '5:00 PM');
    expect(departure.isSpecial, isFalse);
    expect(departure.sortOrder, 18);
  });
}
