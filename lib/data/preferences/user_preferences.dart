import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage/storage_service.dart';

/// Supported display time formats for transit schedules.
enum TransitTimeFormat {
  twelveHour,
  twentyFourHour;

  String get displayName => switch (this) {
    TransitTimeFormat.twelveHour => '12 Hour Format',
    TransitTimeFormat.twentyFourHour => '24 Hour Format',
  };

  static TransitTimeFormat fromString(String? value) {
    if (value == '24 Hour Format' || value == 'twentyFourHour') {
      return TransitTimeFormat.twentyFourHour;
    }
    return TransitTimeFormat.twelveHour;
  }
}

/// Persistent user settings model for Tracklet campus transit.
class UserPreferences {
  const UserPreferences({
    this.preferredStopId = '444f8f96-e747-4382-a80f-a283539f0fec', // Main Gate
    this.preferredStopName = 'Main Gate',
    this.preferredRouteId = '10000000-0000-4000-8000-000000000001', // R1
    this.preferredRouteName = 'R1 (East ↔ MBH)',
    this.timeFormat = TransitTimeFormat.twelveHour,
    this.alertLeadTimeMinutes = 5,
    this.notificationsEnabled = true,
    this.busArrivalAlerts = true,
    this.disruptionAlerts = true,
    this.scheduleChangeAlerts = true,
    this.campusTransportationNotices = true,
    this.quietHoursEnabled = false,
    this.themeMode = 'Light',
    this.hapticFeedbackEnabled = true,
    this.map3DBuildingsEnabled = true,
  });

  final String preferredStopId;
  final String preferredStopName;
  final String preferredRouteId;
  final String preferredRouteName;
  final TransitTimeFormat timeFormat;
  final int alertLeadTimeMinutes;
  final bool notificationsEnabled;
  final bool busArrivalAlerts;
  final bool disruptionAlerts;
  final bool scheduleChangeAlerts;
  final bool campusTransportationNotices;
  final bool quietHoursEnabled;
  final String themeMode;
  final bool hapticFeedbackEnabled;
  final bool map3DBuildingsEnabled;

  UserPreferences copyWith({
    String? preferredStopId,
    String? preferredStopName,
    String? preferredRouteId,
    String? preferredRouteName,
    TransitTimeFormat? timeFormat,
    int? alertLeadTimeMinutes,
    bool? notificationsEnabled,
    bool? busArrivalAlerts,
    bool? disruptionAlerts,
    bool? scheduleChangeAlerts,
    bool? campusTransportationNotices,
    bool? quietHoursEnabled,
    String? themeMode,
    bool? hapticFeedbackEnabled,
    bool? map3DBuildingsEnabled,
  }) {
    return UserPreferences(
      preferredStopId: preferredStopId ?? this.preferredStopId,
      preferredStopName: preferredStopName ?? this.preferredStopName,
      preferredRouteId: preferredRouteId ?? this.preferredRouteId,
      preferredRouteName: preferredRouteName ?? this.preferredRouteName,
      timeFormat: timeFormat ?? this.timeFormat,
      alertLeadTimeMinutes: alertLeadTimeMinutes ?? this.alertLeadTimeMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      busArrivalAlerts: busArrivalAlerts ?? this.busArrivalAlerts,
      disruptionAlerts: disruptionAlerts ?? this.disruptionAlerts,
      scheduleChangeAlerts: scheduleChangeAlerts ?? this.scheduleChangeAlerts,
      campusTransportationNotices:
          campusTransportationNotices ?? this.campusTransportationNotices,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      themeMode: themeMode ?? this.themeMode,
      hapticFeedbackEnabled:
          hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      map3DBuildingsEnabled:
          map3DBuildingsEnabled ?? this.map3DBuildingsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'preferred_stop_id': preferredStopId,
    'preferred_stop_name': preferredStopName,
    'preferred_route_id': preferredRouteId,
    'preferred_route_name': preferredRouteName,
    'time_format': timeFormat.name,
    'alert_lead_time_minutes': alertLeadTimeMinutes,
    'notifications_enabled': notificationsEnabled,
    'bus_arrival_alerts': busArrivalAlerts,
    'disruption_alerts': disruptionAlerts,
    'schedule_change_alerts': scheduleChangeAlerts,
    'campus_transportation_notices': campusTransportationNotices,
    'quiet_hours_enabled': quietHoursEnabled,
    'theme_mode': themeMode,
    'haptic_feedback_enabled': hapticFeedbackEnabled,
    'map_3d_buildings_enabled': map3DBuildingsEnabled,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    // Validate and clamp alert lead time between 1 and 30 minutes
    final rawLeadTime = (json['alert_lead_time_minutes'] as num?)?.toInt();
    final clampedLeadTime = rawLeadTime != null ? rawLeadTime.clamp(1, 30) : 5;

    // Validate theme mode
    final rawTheme = json['theme_mode'] as String?;
    final validTheme = switch (rawTheme) {
      'Dark' => 'Dark',
      'System' => 'System',
      _ => 'Light',
    };

    return UserPreferences(
      preferredStopId:
          json['preferred_stop_id'] as String? ??
          '444f8f96-e747-4382-a80f-a283539f0fec',
      preferredStopName: json['preferred_stop_name'] as String? ?? 'Main Gate',
      preferredRouteId:
          json['preferred_route_id'] as String? ??
          '10000000-0000-4000-8000-000000000001',
      preferredRouteName:
          json['preferred_route_name'] as String? ?? 'R1 (East ↔ MBH)',
      timeFormat: TransitTimeFormat.fromString(json['time_format'] as String?),
      alertLeadTimeMinutes: clampedLeadTime,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      busArrivalAlerts: json['bus_arrival_alerts'] as bool? ?? true,
      disruptionAlerts: json['disruption_alerts'] as bool? ?? true,
      scheduleChangeAlerts: json['schedule_change_alerts'] as bool? ?? true,
      campusTransportationNotices:
          json['campus_transportation_notices'] as bool? ?? true,
      quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? false,
      themeMode: validTheme,
      hapticFeedbackEnabled: json['haptic_feedback_enabled'] as bool? ?? true,
      map3DBuildingsEnabled: json['map_3d_buildings_enabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          preferredStopId == other.preferredStopId &&
          preferredRouteId == other.preferredRouteId &&
          timeFormat == other.timeFormat &&
          alertLeadTimeMinutes == other.alertLeadTimeMinutes &&
          notificationsEnabled == other.notificationsEnabled &&
          busArrivalAlerts == other.busArrivalAlerts &&
          disruptionAlerts == other.disruptionAlerts &&
          scheduleChangeAlerts == other.scheduleChangeAlerts &&
          campusTransportationNotices == other.campusTransportationNotices &&
          quietHoursEnabled == other.quietHoursEnabled &&
          themeMode == other.themeMode &&
          hapticFeedbackEnabled == other.hapticFeedbackEnabled &&
          map3DBuildingsEnabled == other.map3DBuildingsEnabled;

  @override
  int get hashCode => Object.hash(
    preferredStopId,
    preferredRouteId,
    timeFormat,
    alertLeadTimeMinutes,
    notificationsEnabled,
    busArrivalAlerts,
    disruptionAlerts,
    scheduleChangeAlerts,
    campusTransportationNotices,
    quietHoursEnabled,
    themeMode,
    hapticFeedbackEnabled,
    map3DBuildingsEnabled,
  );
}

const String _kUserPreferencesStorageKey = 'tracklet_user_preferences_v1';

/// Provider for user preferences with automatic local persistence.
class UserPreferencesNotifier extends Notifier<UserPreferences> {
  @override
  UserPreferences build() {
    final storage = ref.watch(storageServiceProvider);
    final rawJson = storage.getString(_kUserPreferencesStorageKey);
    if (rawJson != null) {
      try {
        final Map<String, dynamic> decoded =
            jsonDecode(rawJson) as Map<String, dynamic>;
        return UserPreferences.fromJson(decoded);
      } catch (_) {
        return const UserPreferences();
      }
    }
    return const UserPreferences();
  }

  Future<void> _persist(UserPreferences updated) async {
    state = updated;
    final storage = ref.read(storageServiceProvider);
    await storage.setString(
      _kUserPreferencesStorageKey,
      jsonEncode(updated.toJson()),
    );
  }

  Future<void> setPreferredStop(String stopId, String stopName) async {
    await _persist(
      state.copyWith(preferredStopId: stopId, preferredStopName: stopName),
    );
  }

  Future<void> setPreferredRoute(String routeId, String routeName) async {
    await _persist(
      state.copyWith(preferredRouteId: routeId, preferredRouteName: routeName),
    );
  }

  Future<void> setTimeFormat(TransitTimeFormat format) async {
    await _persist(state.copyWith(timeFormat: format));
  }

  Future<void> setAlertLeadTime(int minutes) async {
    final clamped = minutes.clamp(1, 30);
    await _persist(state.copyWith(alertLeadTimeMinutes: clamped));
  }

  Future<void> toggleNotifications(bool enabled) async {
    await _persist(state.copyWith(notificationsEnabled: enabled));
  }

  Future<void> toggleBusArrivalAlerts(bool enabled) async {
    await _persist(state.copyWith(busArrivalAlerts: enabled));
  }

  Future<void> toggleDisruptionAlerts(bool enabled) async {
    await _persist(state.copyWith(disruptionAlerts: enabled));
  }

  Future<void> toggleScheduleChangeAlerts(bool enabled) async {
    await _persist(state.copyWith(scheduleChangeAlerts: enabled));
  }

  Future<void> setCampusTransportationNotices(bool enabled) async {
    await _persist(state.copyWith(campusTransportationNotices: enabled));
  }

  Future<void> toggleQuietHours(bool enabled) async {
    await _persist(state.copyWith(quietHoursEnabled: enabled));
  }

  Future<void> setThemeMode(String mode) async {
    final validTheme = switch (mode) {
      'Dark' => 'Dark',
      'System' => 'System',
      _ => 'Light',
    };
    await _persist(state.copyWith(themeMode: validTheme));
  }

  Future<void> toggleHapticFeedback(bool enabled) async {
    await _persist(state.copyWith(hapticFeedbackEnabled: enabled));
  }

  Future<void> toggleMap3DBuildings(bool enabled) async {
    await _persist(state.copyWith(map3DBuildingsEnabled: enabled));
  }

  Future<void> resetPreferences() async {
    await _persist(const UserPreferences());
  }
}

final userPreferencesProvider =
    NotifierProvider<UserPreferencesNotifier, UserPreferences>(() {
      return UserPreferencesNotifier();
    });
