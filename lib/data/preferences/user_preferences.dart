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
    this.themeMode = 'Light',
    this.hapticFeedbackEnabled = true,
    this.map3DBuildingsEnabled = true,
    this.pushNotificationsEnabled,
  });

  final String preferredStopId;
  final String preferredStopName;
  final String preferredRouteId;
  final String preferredRouteName;
  final TransitTimeFormat timeFormat;
  final String themeMode;
  final bool hapticFeedbackEnabled;
  final bool map3DBuildingsEnabled;
  final bool? pushNotificationsEnabled;

  UserPreferences copyWith({
    String? preferredStopId,
    String? preferredStopName,
    String? preferredRouteId,
    String? preferredRouteName,
    TransitTimeFormat? timeFormat,
    String? themeMode,
    bool? hapticFeedbackEnabled,
    bool? map3DBuildingsEnabled,
    bool? pushNotificationsEnabled,
  }) {
    return UserPreferences(
      preferredStopId: preferredStopId ?? this.preferredStopId,
      preferredStopName: preferredStopName ?? this.preferredStopName,
      preferredRouteId: preferredRouteId ?? this.preferredRouteId,
      preferredRouteName: preferredRouteName ?? this.preferredRouteName,
      timeFormat: timeFormat ?? this.timeFormat,
      themeMode: themeMode ?? this.themeMode,
      hapticFeedbackEnabled:
          hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      map3DBuildingsEnabled:
          map3DBuildingsEnabled ?? this.map3DBuildingsEnabled,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'preferred_stop_id': preferredStopId,
    'preferred_stop_name': preferredStopName,
    'preferred_route_id': preferredRouteId,
    'preferred_route_name': preferredRouteName,
    'time_format': timeFormat.name,
    'theme_mode': themeMode,
    'haptic_feedback_enabled': hapticFeedbackEnabled,
    'map_3d_buildings_enabled': map3DBuildingsEnabled,
    'push_notifications_enabled': pushNotificationsEnabled,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
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
      themeMode: validTheme,
      hapticFeedbackEnabled: json['haptic_feedback_enabled'] as bool? ?? true,
      map3DBuildingsEnabled: json['map_3d_buildings_enabled'] as bool? ?? true,
      pushNotificationsEnabled: json['push_notifications_enabled'] as bool?,
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
          themeMode == other.themeMode &&
          hapticFeedbackEnabled == other.hapticFeedbackEnabled &&
          map3DBuildingsEnabled == other.map3DBuildingsEnabled &&
          pushNotificationsEnabled == other.pushNotificationsEnabled;

  @override
  int get hashCode => Object.hash(
    preferredStopId,
    preferredRouteId,
    timeFormat,
    themeMode,
    hapticFeedbackEnabled,
    map3DBuildingsEnabled,
    pushNotificationsEnabled,
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

  Future<void> setPushNotificationsEnabled(bool enabled) async {
    await _persist(state.copyWith(pushNotificationsEnabled: enabled));
  }

  Future<void> resetPreferences() async {
    await _persist(const UserPreferences());
  }
}

final userPreferencesProvider =
    NotifierProvider<UserPreferencesNotifier, UserPreferences>(() {
      return UserPreferencesNotifier();
    });
