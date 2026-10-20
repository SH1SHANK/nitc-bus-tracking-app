import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/services/notifications/notification_navigation.dart';

void main() {
  group('notificationDestination', () {
    test('arrival and disruption payloads open the inbox', () {
      expect(
        notificationDestination({
          'type': 'arrival',
          'bus_id': '00000000-0000-4000-8000-000000000001',
          'stop_id': '00000000-0000-4000-8000-000000000002',
          'route_id': '00000000-0000-4000-8000-000000000003',
        }),
        '/notifications',
      );
      expect(
        notificationDestination({
          'type': 'disruption',
          'announcement_id': '00000000-0000-4000-8000-000000000004',
          'route_id': '00000000-0000-4000-8000-000000000003',
        }),
        '/notifications',
      );
    });

    test('announcement payload opens the inbox', () {
      expect(
        notificationDestination({
          'type': 'announcement',
          'announcement_id': '00000000-0000-4000-8000-000000000004',
        }),
        '/notifications',
      );
    });

    test('reminder payload opens the reminders screen', () {
      expect(
        notificationDestination({
          'type': 'reminder',
          'reminder_id': '00000000-0000-4000-8000-000000000005',
          'stop_id': '00000000-0000-4000-8000-000000000002',
        }),
        '/reminders',
      );
    });

    test('unknown and malformed payloads safely open the inbox', () {
      expect(notificationDestination(null), '/notifications');
      expect(notificationDestination({'type': 'unknown'}), '/notifications');
      expect(
        notificationDestination({
          'type': 'reminder',
          'reminder_id': 'not-a-uuid',
        }),
        '/notifications',
      );
      expect(
        notificationDestination({
          'type': 'arrival',
          'bus_id': '00000000-0000-4000-8000-000000000001',
        }),
        '/notifications',
      );
    });
  });
}
