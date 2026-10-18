import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/auth/forgot_password_screen.dart';

void main() {
  testWidgets(
    'ForgotPasswordScreen renders Attendrix layout with inputs and actions',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));

      // Verify Title & Subtitle
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(
        find.textContaining(
          'Enter your email address to receive a password reset link.',
        ),
        findsOneWidget,
      );

      // Verify Email Form Field
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('name@nitc.ac.in'), findsOneWidget);

      // Verify Action Buttons
      expect(find.text('Send reset link'), findsOneWidget);
      expect(find.text('Back to login'), findsOneWidget);

      // Test entering empty email shows validation snackbar
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email address.'), findsOneWidget);
    },
  );
}
