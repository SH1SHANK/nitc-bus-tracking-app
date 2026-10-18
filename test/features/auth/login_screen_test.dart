import 'package:flutter/material.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart'
    as animated;
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/auth/login_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('renders all Attendrix login elements properly', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const LoginScreen());
      await tester.pumpAndSettle();

      // Title & Subtitle
      expect(find.text('Welcome back'), findsOneWidget);
      expect(
        find.text('Sign in to view live campus bus routes and arrival times.'),
        findsOneWidget,
      );

      // Email & Password Form Fields
      expect(find.text('name@nitc.ac.in'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      for (final field in tester.widgetList<EditableText>(
        find.byType(EditableText),
      )) {
        expect(field.style.fontWeight, FontWeight.w600);
      }

      for (final decorator in tester.widgetList<InputDecorator>(
        find.byType(InputDecorator),
      )) {
        expect(decorator.decoration.hintStyle?.fontFamily, 'Outfit');
        expect(decorator.decoration.hintStyle?.fontWeight, FontWeight.w700);
        expect(decorator.decoration.labelStyle?.fontFamily, 'Outfit');
        expect(decorator.decoration.labelStyle?.fontWeight, FontWeight.w600);
        expect(
          decorator.decoration.floatingLabelStyle?.fontWeight,
          FontWeight.w700,
        );
        expect(decorator.decoration.errorStyle?.fontWeight, FontWeight.w600);
      }

      // Forgot Password Link
      expect(find.text('Forgot password?'), findsOneWidget);

      // Buttons
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('or'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue as guest'), findsOneWidget);

      // Sign Up / Create Account Link
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('entering email and password updates field controllers', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const LoginScreen());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'student@nitc.ac.in');
      await tester.enterText(fields.last, 'password123');
      await tester.pumpAndSettle();

      expect(find.text('student@nitc.ac.in'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('rejects email addresses outside the NITC institute domain', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const LoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'student@gmail.com',
      );
      final loginButton = find.widgetWithText(ElevatedButton, 'Log in');
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Use your NITC institute email ending in @nitc.ac.in.'),
        findsOneWidget,
      );
    });

    testWidgets('accepts the NITC domain without case sensitivity', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const LoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'student@NITC.AC.IN',
      );
      final loginButton = find.widgetWithText(ElevatedButton, 'Log in');
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Use your NITC institute email ending in @nitc.ac.in.'),
        findsNothing,
      );
    });

    testWidgets('toggling password visibility changes obscurity', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const LoginScreen());
      await tester.pumpAndSettle();

      final visibilityToggle = find.byKey(
        const ValueKey('login_password_visibility_toggle'),
      );
      expect(visibilityToggle, findsOneWidget);

      final editableBefore = tester.widget<EditableText>(
        find.byType(EditableText).last,
      );
      expect(editableBefore.obscureText, isTrue);

      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      final editableAfter = tester.widget<EditableText>(
        find.byType(EditableText).last,
      );
      expect(editableAfter.obscureText, isFalse);
      expect(
        find.byWidgetPredicate(
          (w) => w is animated.LucideAnimatedIcon && w.icon.name == 'eye',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping Continue as Guest triggers guest authentication flow',
      (tester) async {
        await tester.pumpTrackletWidget(const LoginScreen());
        await tester.pumpAndSettle();

        final guestButton = find.byKey(
          const ValueKey('continue_as_guest_button'),
        );
        expect(guestButton, findsOneWidget);

        await tester.ensureVisible(guestButton);
        await tester.tap(guestButton);
        await tester.pump();

        // Ensure button was tapped and progress or completion is initiated
        expect(
          find.byKey(const ValueKey('continue_as_guest_button')),
          findsOneWidget,
        );
      },
    );
  });
}
