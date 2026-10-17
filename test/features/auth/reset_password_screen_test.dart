import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/design_system/components/icons/tracklet_icons.dart';
import 'package:tracklet/features/auth/reset_password_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ResetPasswordScreen Widget Tests', () {
    testWidgets('renders Attendrix elements, inputs, and buttons', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const ResetPasswordScreen());
      await tester.pumpAndSettle();

      // Title & Subtitle
      expect(find.text('Reset Your Password!'), findsOneWidget);
      expect(
        find.textContaining('We’ve got you covered, no stress!'),
        findsOneWidget,
      );

      // Form Fields
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Button & Navigation Link
      expect(find.text('Set New Password'), findsOneWidget);
      expect(find.text('Head Back To Login Page'), findsOneWidget);
    });

    testWidgets('validates required passwords and minimum length', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const ResetPasswordScreen());
      await tester.pumpAndSettle();

      final setPasswordButton = find.widgetWithText(
        ElevatedButton,
        'Set New Password',
      );
      await tester.ensureVisible(setPasswordButton);
      await tester.tap(setPasswordButton);
      await tester.pumpAndSettle();

      expect(find.text('Enter a new password.'), findsOneWidget);

      // Enter short password
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '123');
      await tester.tap(setPasswordButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 6 characters long.'),
        findsOneWidget,
      );
    });

    testWidgets('rejects mismatched passwords with snackbar feedback', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const ResetPasswordScreen());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'password123');
      await tester.enterText(fields.last, 'password456');

      final setPasswordButton = find.widgetWithText(
        ElevatedButton,
        'Set New Password',
      );
      await tester.ensureVisible(setPasswordButton);
      await tester.tap(setPasswordButton);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('toggling visibility updates obscured text state', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const ResetPasswordScreen());
      await tester.pumpAndSettle();

      final visibilityIcons = find.byIcon(TrackletIcons.eyeOff);
      expect(visibilityIcons, findsNWidgets(2));

      await tester.tap(visibilityIcons.first);
      await tester.pumpAndSettle();

      expect(find.byIcon(TrackletIcons.eye), findsOneWidget);
    });
  });
}
