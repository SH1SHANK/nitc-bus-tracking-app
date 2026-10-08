import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/onboarding/onboarding_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('OnboardingScreen Widget Tests', () {
    testWidgets('renders step 0 Welcome screen initially', (tester) async {
      await tester.pumpTrackletWidget(const OnboardingScreen());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Tracklet'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Continue with NITC Google Account'), findsOneWidget);
    });

    testWidgets('navigates from Welcome to Name step on tapping Get Started', (
      tester,
    ) async {
      await tester.pumpTrackletWidget(const OnboardingScreen());
      await tester.pumpAndSettle();

      final getStartedButton = find.text('Get Started');
      expect(getStartedButton, findsOneWidget);

      await tester.tap(getStartedButton);
      await tester.pumpAndSettle();

      expect(find.text("Let's Set Up Your Academic Profile"), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('typing name enables Continue button', (tester) async {
      await tester.pumpTrackletWidget(const OnboardingScreen());
      await tester.pumpAndSettle();

      // Go to Step 1 (Name)
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.byType(TextField), 'John Doe');
      await tester.pumpAndSettle();

      expect(find.text('Continue'), findsOneWidget);
    });
  });
}
