import 'package:flutter/material.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart'
    as animated;
import 'package:flutter_test/flutter_test.dart';
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
      expect(find.text('Reset password'), findsOneWidget);
      expect(
        find.text('Enter a new password for your account.'),
        findsOneWidget,
      );

      // Form Fields
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('New password'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);

      // Button & Navigation Link
      expect(find.text('Set new password'), findsOneWidget);
      expect(find.text('Back to login'), findsOneWidget);
    });

    testWidgets('validates required passwords and minimum length', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const ResetPasswordScreen());
      await tester.pumpAndSettle();

      final setPasswordButton = find.widgetWithText(
        ElevatedButton,
        'Set new password',
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
        'Set new password',
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

      final toggle = find.byKey(
        const ValueKey('reset_password_visibility_toggle'),
      );
      expect(toggle, findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is animated.LucideAnimatedIcon && w.icon.name == 'eye',
        ),
        findsOneWidget,
      );
    });
  });
}
