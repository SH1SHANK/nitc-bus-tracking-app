import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/auth/forgot_password_screen.dart';

void main() {
  testWidgets(
    'ForgotPasswordScreen renders Attendrix layout with inputs and actions',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));

      // Verify Title & Subtitle
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(
        find.textContaining('We’ve got you covered, no stress!'),
        findsOneWidget,
      );

      // Verify Email Form Field
      expect(find.text('Your Email Address:'), findsOneWidget);
      expect(find.text('joedoe@email.com'), findsOneWidget);

      // Verify Action Buttons
      expect(find.text('Send Magic Link'), findsOneWidget);
      expect(find.text('Head Back To Login Page'), findsOneWidget);

      // Test entering empty email shows validation snackbar
      await tester.tap(find.text('Send Magic Link'));
      await tester.pumpAndSettle();

      expect(
        find.text('We’ll need your email to help you reset your password.'),
        findsOneWidget,
      );
    },
  );
}
