import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/settings/widgets/settings_notifications_section.dart';
import 'package:tracklet/services/notifications/notification_push_state.dart';

void main() {
  testWidgets('push toggle reflects readiness and emits explicit changes', (
    tester,
  ) async {
    bool? requestedValue;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsNotificationsSection(
            pushState: PushNotificationState.disabled,
            onPushChanged: (value) => requestedValue = value,
          ),
        ),
      ),
    );

    expect(find.text('Push notifications'), findsOneWidget);
    expect(find.text('Off on this device'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('push-notifications-toggle-row')),
        matching: find.byType(Switch),
      ),
    );
    expect(requestedValue, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsNotificationsSection(
            pushState: PushNotificationState.enabled,
            onPushChanged: (value) => requestedValue = value,
          ),
        ),
      ),
    );
    expect(find.text('Enabled on this device'), findsOneWidget);
  });

  testWidgets('live notifications control stays disabled and inert', (
    tester,
  ) async {
    var pushChangeCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsNotificationsSection(
            pushState: PushNotificationState.disabled,
            onPushChanged: (_) => pushChangeCount++,
          ),
        ),
      ),
    );

    expect(find.text('Live notifications'), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
    final liveSwitch = tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const Key('live-notifications-toggle-row')),
        matching: find.byType(Switch),
      ),
    );
    expect(liveSwitch.onChanged, isNull);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('live-notifications-toggle-row')),
        matching: find.byType(Switch),
      ),
    );
    expect(pushChangeCount, 0);
  });

  testWidgets('registration failure remains off and offers a retry', (
    tester,
  ) async {
    var requestedRetry = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsNotificationsSection(
            pushState: PushNotificationState.registrationFailed,
            onPushChanged: (value) => requestedRetry = value,
          ),
        ),
      ),
    );

    expect(
      find.text('This device could not register. Tap to retry.'),
      findsOneWidget,
    );
    final pushSwitch = tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const Key('push-notifications-toggle-row')),
        matching: find.byType(Switch),
      ),
    );
    expect(pushSwitch.value, isFalse);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('push-notifications-toggle-row')),
        matching: find.byType(Switch),
      ),
    );
    expect(requestedRetry, isTrue);
  });
}
