import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/data/notifications/notification_models.dart';

void main() {
  group('BoardingReminder calculation & recurrence', () {
    test('Calculates 30 minutes lead notification time correctly', () {
      final reminder = BoardingReminder(
        id: 'rem-1',
        stopId: 'stop-1',
        intendedLeaveTime: '08:30:00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(reminder.reminderNoticeTimeFormatted, '08:00');
    });

    test('Calculates 30 minutes lead time correctly across the hour', () {
      final reminder = BoardingReminder(
        id: 'rem-2',
        stopId: 'stop-2',
        intendedLeaveTime: '09:15:00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(reminder.reminderNoticeTimeFormatted, '08:45');
    });

    test('Calculates 30 minutes lead time wrapping across midnight', () {
      final reminder = BoardingReminder(
        id: 'rem-3',
        stopId: 'stop-3',
        intendedLeaveTime: '00:15:00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(reminder.reminderNoticeTimeFormatted, '23:45');
    });

    test('Serializes and deserializes correctly', () {
      final now = DateTime.now();
      final reminder = BoardingReminder(
        id: 'rem-4',
        userId: 'user-123',
        stopId: 'stop-4',
        stopName: 'Main Gate',
        intendedLeaveTime: '17:45:00',
        timezone: 'Asia/Kolkata',
        recurrenceDays: const [1, 2, 3, 4, 5],
        isEnabled: true,
        lastProcessedStatus: 'idle',
        createdAt: now,
        updatedAt: now,
      );

      final json = reminder.toJson();
      expect(json['id'], 'rem-4');
      expect(json['stop_id'], 'stop-4');
      expect(json['intended_leave_time'], '17:45:00');
      expect(json['recurrence_pattern'], 'MON_FRI');

      final deserialized = BoardingReminder.fromJson({
        ...json,
        'stops': const {'name': 'Main Gate'},
      });
      expect(deserialized.id, reminder.id);
      expect(deserialized.stopName, 'Main Gate');
      expect(deserialized.reminderNoticeTimeFormatted, '17:15');
    });
  });

  group('NotificationItem tests', () {
    test('JSON serialization & copyWith', () {
      final now = DateTime.now();
      final item = NotificationItem(
        id: 'notif-1',
        userId: 'user-1',
        title: 'Route Diversion',
        body: 'Route R1 detour active.',
        notificationType: 'disruption',
        isRead: false,
        createdAt: now,
      );

      expect(item.isRead, false);
      final readItem = item.copyWith(isRead: true, readAt: now);
      expect(readItem.isRead, true);
      expect(readItem.readAt, now);

      final json = readItem.toJson();
      final fromJson = NotificationItem.fromJson(json);
      expect(fromJson.title, 'Route Diversion');
      expect(fromJson.type, 'disruption');
      expect(fromJson.isRead, true);
    });
  });
}
