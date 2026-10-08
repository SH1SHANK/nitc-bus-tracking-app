import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/onboarding/onboarding_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('OnboardingScreen Widget Tests', () {
    testWidgets('renders step 1 Academic Profile screen initially', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpTrackletWidget(const OnboardingScreen());
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text("Let's Set Up Your Academic Profile"), findsOneWidget);
      expect(find.text('What is your full name?'), findsOneWidget);
      expect(find.text('Which branch do you belong to?'), findsOneWidget);
      expect(find.text('Which batch do you belong to?'), findsOneWidget);
      expect(
        find.text('Which hostel or mess do you belong to?'),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets(
      'navigates from Academic Profile to Username step on Continue',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpTrackletWidget(const OnboardingScreen());
        await tester.pumpAndSettle();

        final continueButton = find.text('Continue');
        expect(continueButton, findsOneWidget);

        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        expect(find.text('Step 2 of 3'), findsOneWidget);
        expect(find.text('Choose Your Username'), findsOneWidget);
      },
    );

    testWidgets(
      'navigates from Username to Permissions step on tapping Continue',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpTrackletWidget(const OnboardingScreen());
        await tester.pumpAndSettle();

        // Step 1 -> Step 2
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Step 2 -> Step 3
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(find.text('Step 3 of 3'), findsOneWidget);
        expect(find.text('Permissions & Access'), findsOneWidget);
        expect(find.text('Campus Live Location'), findsOneWidget);
        expect(find.text('Transit & Arrival Alerts'), findsOneWidget);
      },
    );
  });
}
