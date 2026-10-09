import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/onboarding/onboarding_screen.dart';
import 'package:tracklet/features/onboarding/providers/onboarding_provider.dart';
import 'package:tracklet/features/onboarding/widgets/onboarding_progress_bar.dart';
import 'package:tracklet/features/onboarding/widgets/onboarding_step_loading.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('OnboardingScreen Widget Tests', () {
    testWidgets('welcome state shows Tracklet copy and setup progress', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpTrackletWidget(
        const Scaffold(
          body: OnboardingStepLoading(
            progress: 0.55,
            statusText: 'Saving your profile and preferences...',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Tracklet'), findsOneWidget);
      expect(
        find.text('Campus transit, made simple.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text('Saving your profile and preferences...'),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
    testWidgets('renders step 1 Academic Profile screen initially', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpTrackletWidget(const OnboardingScreen());
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text("Let's Set Up Your Academic Profile"), findsOneWidget);
      expect(find.text('Shashank Mergu'), findsNothing);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      final agreementRow = tester.widget<Row>(
        find
            .ancestor(of: find.byType(Checkbox), matching: find.byType(Row))
            .first,
      );
      expect(agreementRow.crossAxisAlignment, CrossAxisAlignment.center);
      expect(
        find.text('I agree to the Terms of Service and Privacy Policy.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Continue'),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('What is your full name?'), findsOneWidget);
      expect(find.text('Which branch do you belong to?'), findsOneWidget);
      expect(find.text('Which batch do you belong to?'), findsOneWidget);
      expect(find.textContaining('semester'), findsNothing);
      expect(find.text('Which hostel do you belong to?'), findsOneWidget);
      expect(find.text('Select Hostel'), findsOneWidget);
      expect(find.text('Select Hostel / Residence'), findsNothing);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('starts on the provider current step', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(onboardingProvider.notifier).setStep(1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Username'), findsOneWidget);
      expect(find.text("Let's Set Up Your Academic Profile"), findsNothing);
    });

    testWidgets(
      'keeps Continue disabled until all profile fields and agreement are complete',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpTrackletWidget(const OnboardingScreen());
        await tester.pumpAndSettle();
        await _completeAcademicProfile(tester, agreeToTerms: false);

        var continueButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Continue'),
        );
        expect(continueButton.onPressed, isNull);

        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        continueButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Continue'),
        );
        expect(continueButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'navigates from Academic Profile to Username step on Continue',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpTrackletWidget(const OnboardingScreen());
        await tester.pumpAndSettle();

        await _completeAcademicProfile(tester);
        final continueButton = find.text('Continue');
        expect(continueButton, findsOneWidget);

        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingProgressBar), findsOneWidget);
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
        await _completeAcademicProfile(tester);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Step 2 -> Step 3
        await tester.tap(find.byTooltip('Generate a username'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(find.text('Step 3 of 4'), findsOneWidget);
        expect(find.text('Permissions & Access'), findsOneWidget);
        expect(find.text('Campus Live Location'), findsOneWidget);
        expect(find.text('Transit & Arrival Alerts'), findsOneWidget);
        expect(find.text('Continue without permissions'), findsOneWidget);
      },
    );
  });
}

Future<void> _completeAcademicProfile(
  WidgetTester tester, {
  bool agreeToTerms = true,
}) async {
  await tester.enterText(find.byType(TextFormField).first, 'Taylor Student');

  await tester.tap(find.text('Select Branch'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(kNitcBranches.first).last);
  await tester.pumpAndSettle();

  await tester.tap(find.text('Select Batch'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(kNitcBatches.first).last);
  await tester.pumpAndSettle();

  await tester.tap(find.text('Select Hostel'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Mega Hostel (MBH - Phase 1)').last);
  await tester.pumpAndSettle();

  if (agreeToTerms) {
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
  }
}
