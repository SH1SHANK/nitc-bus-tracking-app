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

      // Verify Title & Instructional copy inside RichText
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains(
                'Your reset request is on its way!',
              ),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('Didn’t show up? Resend Mail'),
        ),
        findsOneWidget,
      );
      expect(find.text('Back to Login'), findsOneWidget);
    },
  );
}
