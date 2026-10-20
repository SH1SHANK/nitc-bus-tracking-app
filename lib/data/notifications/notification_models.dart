import 'package:flutter/foundation.dart';

@immutable
class NotificationItem {
  final String id;
  final String? userId;
  final String? guestDeviceId;
  final String? announcementId;
  final String title;
  final String body;
  final String
  notificationType; // 'announcement', 'disruption', 'reminder', 'arrival'
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;

  const NotificationItem({
    required this.id,
    this.userId,
    this.guestDeviceId,
    this.announcementId,
    required this.title,
    required this.body,
    required this.notificationType,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.expiresAt,
  });

  /// Alias for UI backwards-compatibility
  String get type => notificationType;

  /// Alias for UI backwards-compatibility
  Map<String, dynamic>? get metadata => data;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      guestDeviceId: json['guest_device_id'] as String?,
      announcementId: json['announcement_id'] as String?,
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      notificationType:
          (json['notification_type'] ?? json['type'] ?? 'announcement')
              as String,
      data: (json['data'] ?? json['metadata']) as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      readAt:
          json['read_at'] != null
              ? DateTime.tryParse(json['read_at'] as String)
              : null,
      expiresAt:
          json['expires_at'] != null
              ? DateTime.tryParse(json['expires_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'guest_device_id': guestDeviceId,
      'announcement_id': announcementId,
      'title': title,
      'body': body,
      'notification_type': notificationType,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? guestDeviceId,
    String? announcementId,
    String? title,
    String? body,
    String? notificationType,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? expiresAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      guestDeviceId: guestDeviceId ?? this.guestDeviceId,
      announcementId: announcementId ?? this.announcementId,
      title: title ?? this.title,
      body: body ?? this.body,
      notificationType: notificationType ?? this.notificationType,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

@immutable
class BoardingReminder {
  final String id;
  final String? userId;
  final String? guestDeviceId;
  final String stopId;
  final String? stopName;
  final String intendedLeaveTime; // "HH:MM:SS"
  final String timezone;
  final List<int> recurrenceDays; // [1, 2, 3, 4, 5]
  final bool isEnabled;
  final String? lastProcessedDate;
  final String lastProcessedStatus;
  final String? suppressionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BoardingReminder({
    required this.id,
    this.userId,
    this.guestDeviceId,
    required this.stopId,
    this.stopName,
    required this.intendedLeaveTime,
    this.timezone = 'Asia/Kolkata',
    this.recurrenceDays = const [1, 2, 3, 4, 5],
    this.isEnabled = true,
    this.lastProcessedDate,
    this.lastProcessedStatus = 'idle',
    this.suppressionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Alias for backward compatibility
  bool get isActive => isEnabled;

  /// Human-readable recurrence summary
  String get recurrencePattern {
    if (listEquals(recurrenceDays, [1, 2, 3, 4, 5])) return 'MON_FRI';
    if (recurrenceDays.length == 7) return 'DAILY';
    return recurrenceDays
        .map((d) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1])
        .join(', ');
  }

  /// The scheduled reminder notification time is 30 minutes before intended leave time.
  String get reminderNoticeTimeFormatted {
    final parts = intendedLeaveTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final totalMinutes = hour * 60 + minute - 30;
    final noticeMinute =
        totalMinutes < 0 ? (totalMinutes + 1440) : totalMinutes;
    final nh = (noticeMinute ~/ 60).toString().padLeft(2, '0');
    final nm = (noticeMinute % 60).toString().padLeft(2, '0');
    return '$nh:$nm';
  }

  factory BoardingReminder.fromJson(Map<String, dynamic> json) {
    String? stopName;
    if (json['stops'] != null && json['stops'] is Map<String, dynamic>) {
      stopName = (json['stops'] as Map<String, dynamic>)['name'] as String?;
    }

    List<int> parseRecurrence(dynamic val) {
      if (val is List) {
        return val.map((e) => (e as num).toInt()).toList();
      }
      if (val == 'MON_FRI') return [1, 2, 3, 4, 5];
      if (val == 'DAILY') return [1, 2, 3, 4, 5, 6, 7];
      return [1, 2, 3, 4, 5];
    }

    return BoardingReminder(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      guestDeviceId: json['guest_device_id'] as String?,
      stopId: json['stop_id'] as String,
      stopName: stopName,
      intendedLeaveTime: json['intended_leave_time'] as String? ?? '08:30:00',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      recurrenceDays: parseRecurrence(
        json['recurrence_days'] ?? json['recurrence_pattern'],
      ),
      isEnabled: (json['is_enabled'] ?? json['is_active']) as bool? ?? true,
      lastProcessedDate: json['last_processed_date'] as String?,
      lastProcessedStatus:
          (json['last_processed_status'] ?? json['last_status']) as String? ??
          'idle',
      suppressionReason: json['suppression_reason'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'guest_device_id': guestDeviceId,
      'stop_id': stopId,
      'intended_leave_time': intendedLeaveTime,
      'timezone': timezone,
      'recurrence_days': recurrenceDays,
      'recurrence_pattern': recurrencePattern,
      'is_enabled': isEnabled,
      'is_active': isEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

@immutable
class NotificationAnnouncement {
  final String id;
  final String title;
  final String body;
  final String type; // 'general' or 'disruption'
  final String? routeId;
  final String priority;
  final DateTime? expiresAt;
  final String status;
  final DateTime createdAt;

  const NotificationAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.routeId,
    this.priority = 'normal',
    this.expiresAt,
    required this.status,
    required this.createdAt,
  });

  /// Alias for UI backwards-compatibility
  String? get targetRouteId => routeId;

  factory NotificationAnnouncement.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>?;
    return NotificationAnnouncement(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      routeId: (json['route_id'] ?? json['target_route_id']) as String?,
      priority: (meta?['priority'] ?? json['priority'] ?? 'normal') as String,
      expiresAt:
          json['expires_at'] != null
              ? DateTime.tryParse(json['expires_at'] as String)
              : null,
      status: json['status'] as String? ?? 'published',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

@immutable
class NotificationSubscription {
  final String id;
  final String? userId;
  final String? guestDeviceId;
  final String? onesignalSubscriptionId;
  final List<String> subscribedRouteIds;
  final List<String> subscribedStopIds;
  final bool isEnabled;
  final String platform;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationSubscription({
    required this.id,
    this.userId,
    this.guestDeviceId,
    this.onesignalSubscriptionId,
    this.subscribedRouteIds = const [],
    this.subscribedStopIds = const [],
    this.isEnabled = true,
    this.platform = 'android',
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationSubscription.fromJson(Map<String, dynamic> json) {
    return NotificationSubscription(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      guestDeviceId: json['guest_device_id'] as String?,
      onesignalSubscriptionId: json['onesignal_subscription_id'] as String?,
      subscribedRouteIds:
          (json['subscribed_route_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['subscribed_routes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      subscribedStopIds:
          (json['subscribed_stop_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['subscribed_stops'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isEnabled: (json['is_enabled'] ?? json['is_active']) as bool? ?? true,
      platform: json['platform'] as String? ?? 'android',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
