import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/settings/screens/manage_notifications_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ManageNotificationsScreen Widget Tests', () {
    testWidgets('renders all notification categories and switches', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const ManageNotificationsScreen());
      await tester.pumpAndSettle();

      expect(find.text('Manage Notifications'), findsOneWidget);
      expect(find.text('Transit Notifications & Alerts'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Live Bus & Arrival Alerts'), findsOneWidget);
      expect(find.text('Bus Arrival Alerts'), findsOneWidget);
      expect(find.text('Alert Lead Time'), findsOneWidget);
      expect(find.text('Service Disruptions & Schedules'), findsOneWidget);
      expect(find.text('Service Disruptions'), findsOneWidget);
      expect(find.text('Schedule Revisions'), findsOneWidget);
      expect(find.text('Campus Transit Notices'), findsOneWidget);
      expect(find.text('Do Not Disturb'), findsOneWidget);
      expect(find.text('Quiet Hours (10 PM – 6 AM)'), findsOneWidget);
    });

    testWidgets('toggles master push notifications switch', (tester) async {
      await tester.pumpTrackletWidget(const ManageNotificationsScreen());
      await tester.pumpAndSettle();

      // Find first switch (Master Push Notifications)
      final masterSwitch = find.byType(Switch).first;
      expect(tester.widget<Switch>(masterSwitch).value, isTrue);

      await tester.tap(masterSwitch);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(masterSwitch).value, isFalse);
    });
  });
}
