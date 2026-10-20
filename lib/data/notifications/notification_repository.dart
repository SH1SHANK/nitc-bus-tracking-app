import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logging/app_logger.dart';
import '../supabase/supabase_client_provider.dart';
import 'notification_models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return NotificationRepository(supabase);
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchUnreadCount();
});

final userInboxNotificationsProvider = FutureProvider<List<NotificationItem>>((
  ref,
) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.fetchInboxNotifications();
});

final userBoardingRemindersProvider = FutureProvider<List<BoardingReminder>>((
  ref,
) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.fetchBoardingReminders();
});

class NotificationRepository {
  final SupabaseClient? _supabase;

  NotificationRepository(this._supabase);

  String? get _currentUserId => _supabase?.auth.currentUser?.id;

  /// Fetch in-app notifications for authenticated user (last 7 days)
  Future<List<NotificationItem>> fetchInboxNotifications() async {
    final client = _supabase;
    final userId = _currentUserId;
    if (client == null || userId == null) return [];

    try {
      final response = await client
          .from('inbox_notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = response as List<dynamic>;
      return list
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'Failed to fetch inbox notifications',
        error: e,
        stackTrace: st,
        tag: 'NotificationRepo',
      );
      return [];
    }
  }

  /// Watch unread notifications count as a stream
  Stream<int> watchUnreadCount() {
    final client = _supabase;
    final userId = _currentUserId;
    if (client == null || userId == null) return Stream.value(0);

    return client
        .from('inbox_notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map(
          (items) =>
              items
                  .where((item) => (item['is_read'] as bool? ?? false) == false)
                  .length,
        );
  }

  /// Mark a specific notification as read
  Future<void> markAsRead(String notificationId) async {
    final client = _supabase;
    if (client == null) return;

    try {
      await client
          .from('inbox_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e, st) {
      AppLogger.error(
        'Failed to mark notification as read',
        error: e,
        stackTrace: st,
        tag: 'NotificationRepo',
      );
    }
  }

  /// Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    final client = _supabase;
    final userId = _currentUserId;
    if (client == null || userId == null) return;

    try {
      await client
          .from('inbox_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e, st) {
      AppLogger.error(
        'Failed to mark all as read',
        error: e,
        stackTrace: st,
        tag: 'NotificationRepo',
      );
    }
  }

  /// Fetch all active/configured boarding reminders for user
  Future<List<BoardingReminder>> fetchBoardingReminders() async {
    final client = _supabase;
    final userId = _currentUserId;
    if (client == null || userId == null) return [];

    try {
      final response = await client
          .from('boarding_reminders')
          .select('*, stops(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = response as List<dynamic>;
      return list
          .map((e) => BoardingReminder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'Failed to fetch boarding reminders',
        error: e,
        stackTrace: st,
        tag: 'NotificationRepo',
      );
      return [];
    }
  }

  /// Create a new boarding reminder
  Future<BoardingReminder?> createBoardingReminder({
    required String stopId,
    required String intendedLeaveTime, // "HH:MM:SS"
    List<int> recurrenceDays = const [1, 2, 3, 4, 5],
  }) async {
    final client = _supabase;
    final userId = _currentUserId;
    if (client == null || userId == null) return null;

    try {
      final response =
          await client
              .from('boarding_reminders')
              .insert({
                'user_id': userId,
                'stop_id': stopId,
                'intended_leave_time': intendedLeaveTime,
                'recurrence_days': recurrenceDays,
                'timezone': 'Asia/Kolkata',
                'is_enabled': true,
              })
              .select('*, stops(name)')
              .single();

      return BoardingReminder.fromJson(response);
    } catch (e, st) {
      AppLogger.error(
        'Failed to create boarding reminder',
        error: e,
        stackTrace: st,
        tag: 'NotificationRepo',
      );
      return null;
    }
  }

  /// Toggle reminder enabled status
  Future<void> toggleReminder(String reminderId, bool isEnabled) async {
    final client = _supabase;
    if (client == null) return;

    try {
      await client
          .from('boarding_reminders')
          .update({'is_enabled': isEnabled})
          .eq('id', reminderId);
    } catch (e, st) {
      AppLogger.error(
        'Failed to toggle reminder',
        error: e,
        stackTrace: st,
        tag: 'NotificationRepo',
      );
    }
  }

  /// Delete a boarding reminder
  Future<void> deleteReminder(String reminderId) async {
    final client = _supabase;
    if (client == null) return;

    try {
      await client.from('boarding_reminders').delete().eq('id', reminderId);
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete reminder',
        error: e,
        stackTrace: st,
        tag: 'NotificationRepo',
      );
    }
  }

  /// Register or update push subscription with OneSignal details
  Future<void> updateSubscription({
    required String platform,
    String? oneSignalSubId,
    List<String>? routes,
    List<String>? stops,
  }) async {
    final client = _supabase;
    final userId = _currentUserId;
    if (client == null || userId == null) return;

    try {
      await client.from('notification_subscriptions').upsert({
        'user_id': userId,
        'onesignal_subscription_id': oneSignalSubId,
        'platform': platform,
        'subscribed_route_ids': routes ?? [],
        'subscribed_stop_ids': stops ?? [],
        'is_enabled': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e, st) {
      AppLogger.error(
        'Failed to update push subscription',
        error: e,
        stackTrace: st,
        tag: 'NotificationRepo',
      );
    }
  }

  /// Send general announcement or route-targeted disruption (Admin Edge Function invocation)
  Future<Map<String, dynamic>> sendAdminAnnouncement({
    required String title,
    required String body,
    String type = 'general',
    String? targetRouteId,
    String priority = 'normal',
    DateTime? expiresAt,
  }) async {
    final client = _supabase;
    if (client == null) {
      return {'success': false, 'error': 'Database client is not available.'};
    }

    try {
      final response = await client.functions.invoke(
        'send-announcement',
        body: {
          'title': title,
          'body': body,
          'type': type,
          'target_route_id': targetRouteId,
          'priority': priority,
          'expires_at': expiresAt?.toIso8601String(),
        },
      );

      final data = response.data is Map ? response.data as Map : null;
      if (response.status != 200) {
        return {'success': false, 'error': data?['error'] ?? 'Server error'};
      }

      return {'success': true, 'data': response.data};
    } catch (e, st) {
      AppLogger.error(
        'Failed to invoke send-announcement',
        error: e,
        stackTrace: st,
        tag: 'NotificationRepo',
      );
      return {'success': false, 'error': e.toString()};
    }
  }
}
