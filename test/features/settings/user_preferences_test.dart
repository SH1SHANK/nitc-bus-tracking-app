import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/data/preferences/user_preferences.dart';

void main() {
  group('UserPreferences Model & Notifier Tests', () {
    test('default preferences have sensible defaults', () {
      const prefs = UserPreferences();
      expect(prefs.preferredStopName, 'Main Gate');
      expect(prefs.preferredRouteName, 'R1 (East ↔ MBH)');
      expect(prefs.timeFormat, TransitTimeFormat.twelveHour);
      expect(prefs.alertLeadTimeMinutes, 5);
      expect(prefs.notificationsEnabled, isTrue);
      expect(prefs.busArrivalAlerts, isTrue);
      expect(prefs.disruptionAlerts, isTrue);
      expect(prefs.quietHoursEnabled, isFalse);
      expect(prefs.themeMode, 'Light');
      expect(prefs.hapticFeedbackEnabled, isTrue);
      expect(prefs.map3DBuildingsEnabled, isTrue);
    });

    test('serializes to and from JSON correctly', () {
      const prefs = UserPreferences(
        preferredStopId: 'stop-123',
        preferredStopName: 'East Campus',
        preferredRouteId: 'route-456',
        preferredRouteName: 'R2 (East ↔ LH)',
        timeFormat: TransitTimeFormat.twentyFourHour,
        alertLeadTimeMinutes: 10,
        notificationsEnabled: false,
        busArrivalAlerts: false,
        disruptionAlerts: true,
        quietHoursEnabled: true,
        themeMode: 'Dark',
        hapticFeedbackEnabled: false,
        map3DBuildingsEnabled: false,
      );

      final json = prefs.toJson();
      final restored = UserPreferences.fromJson(json);

      expect(restored.preferredStopId, 'stop-123');
      expect(restored.preferredStopName, 'East Campus');
      expect(restored.preferredRouteId, 'route-456');
      expect(restored.preferredRouteName, 'R2 (East ↔ LH)');
      expect(restored.timeFormat, TransitTimeFormat.twentyFourHour);
      expect(restored.alertLeadTimeMinutes, 10);
      expect(restored.notificationsEnabled, isFalse);
      expect(restored.busArrivalAlerts, isFalse);
      expect(restored.disruptionAlerts, isTrue);
      expect(restored.quietHoursEnabled, isTrue);
      expect(restored.themeMode, 'Dark');
      expect(restored.hapticFeedbackEnabled, isFalse);
      expect(restored.map3DBuildingsEnabled, isFalse);
    });

    test('handles malformed, corrupt, or out-of-range JSON gracefully', () {
      final corruptJson = <String, dynamic>{
        'alert_lead_time_minutes': 999, // Should clamp to 30
        'theme_mode': 'NeonPurple', // Invalid theme, should fallback to Light
        'time_format':
            'invalid_format', // Invalid time format, should fallback to twelveHour
        'preferred_stop_name': null,
      };

      final restored = UserPreferences.fromJson(corruptJson);

      expect(restored.alertLeadTimeMinutes, 30);
      expect(restored.themeMode, 'Light');
      expect(restored.timeFormat, TransitTimeFormat.twelveHour);
      expect(restored.preferredStopName, 'Main Gate');
    });

    test('clamps negative lead time to minimum of 1 minute', () {
      final json = <String, dynamic>{'alert_lead_time_minutes': -10};

      final restored = UserPreferences.fromJson(json);
      expect(restored.alertLeadTimeMinutes, 1);
    });

    test(
      'UserPreferencesNotifier clamps lead time and validates theme mode',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(userPreferencesProvider.notifier);

        await notifier.setAlertLeadTime(100);
        expect(
          container.read(userPreferencesProvider).alertLeadTimeMinutes,
          30,
        );

        await notifier.setAlertLeadTime(-5);
        expect(container.read(userPreferencesProvider).alertLeadTimeMinutes, 1);

        await notifier.setThemeMode('InvalidCustomTheme');
        expect(container.read(userPreferencesProvider).themeMode, 'Light');

        await notifier.setThemeMode('Dark');
        expect(container.read(userPreferencesProvider).themeMode, 'Dark');
      },
    );

    test('UserPreferencesNotifier updates state correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userPreferencesProvider.notifier);

      expect(
        container.read(userPreferencesProvider).timeFormat,
        TransitTimeFormat.twelveHour,
      );

      await notifier.setTimeFormat(TransitTimeFormat.twentyFourHour);
      expect(
        container.read(userPreferencesProvider).timeFormat,
        TransitTimeFormat.twentyFourHour,
      );

      await notifier.setAlertLeadTime(8);
      expect(container.read(userPreferencesProvider).alertLeadTimeMinutes, 8);

      await notifier.setPreferredStop('stop-test', 'Mega Hostel Boys');
      expect(
        container.read(userPreferencesProvider).preferredStopName,
        'Mega Hostel Boys',
      );

      await notifier.setPreferredRoute('route-test', 'R3 (Architecture ↔ LH)');
      expect(
        container.read(userPreferencesProvider).preferredRouteName,
        'R3 (Architecture ↔ LH)',
      );

      await notifier.setThemeMode('Dark');
      expect(container.read(userPreferencesProvider).themeMode, 'Dark');

      await notifier.toggleNotifications(false);
      expect(
        container.read(userPreferencesProvider).notificationsEnabled,
        isFalse,
      );

      await notifier.resetPreferences();
      expect(
        container.read(userPreferencesProvider).timeFormat,
        TransitTimeFormat.twelveHour,
      );
      expect(
        container.read(userPreferencesProvider).preferredStopName,
        'Main Gate',
      );
    });
  });
}
