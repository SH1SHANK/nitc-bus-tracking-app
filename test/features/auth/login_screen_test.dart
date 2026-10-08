import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/auth/login_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('renders all Attendrix login elements properly', (tester) async {
      await tester.pumpTrackletWidget(const LoginScreen());
      await tester.pumpAndSettle();

      // Title & Subtitle
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(
        find.text("Log in and pick up right where you left off. We've been saving your seat. "),
        findsOneWidget,
      );

      // Email & Password Form Fields
      expect(find.text('Email '), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Forgot Password Link
      expect(find.text('perhaps, forgot your password?'), findsOneWidget);

      // Buttons
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('-- OR --'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      // Sign Up / Create Account Link
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('entering email and password updates field controllers', (tester) async {
      await tester.pumpTrackletWidget(const LoginScreen());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'student@nitc.ac.in');
      await tester.enterText(fields.last, 'password123');
      await tester.pumpAndSettle();

      expect(find.text('student@nitc.ac.in'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('toggling password visibility changes obscurity', (tester) async {
      await tester.pumpTrackletWidget(const LoginScreen());
      await tester.pumpAndSettle();

      final visibilityIcon = find.byIcon(Icons.visibility_off_outlined);
      expect(visibilityIcon, findsOneWidget);

      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });
}
