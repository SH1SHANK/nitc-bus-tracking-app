import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/auth/reset_password_sent_screen.dart';

void main() {
  testWidgets(
    'ResetPasswordSentScreen renders Attendrix instructions and CTA',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordSentScreen(email: 'student@nitc.ac.in'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Title & Instructional copy inside RichText
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('Password reset link sent'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('Didn’t receive the email? Resend'),
        ),
        findsOneWidget,
      );
      expect(find.text('Back to login'), findsOneWidget);
    },
  );
}
