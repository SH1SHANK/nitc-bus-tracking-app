import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/design_system/components/tracklet_snack_bar.dart';
import 'package:tracklet/features/feedback/bug_report_screen.dart';
import 'package:tracklet/features/feedback/feature_suggestion_screen.dart';
import 'package:tracklet/features/feedback/general_feedback_screen.dart';

void main() {
  group('Feedback & Bug Report screens widget tests', () {
    testWidgets('BugReportScreen validates input and submits successfully', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: BugReportScreen()));

      expect(find.text('Report a Bug'), findsOneWidget);
      expect(find.text('Issue Summary *'), findsOneWidget);
      expect(find.text('Steps to Reproduce *'), findsOneWidget);
      expect(find.text('Expected Behavior *'), findsOneWidget);
      expect(find.text('Actual Behavior *'), findsOneWidget);

      // Attempt submit without filling
      await tester.tap(find.text('Submit Bug Report'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter a summary of at least 5 characters.'),
        findsOneWidget,
      );

      // Fill in valid data
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'e.g. Map bus marker glides when panning',
        ),
        'Bus marker glides during pan',
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          '1. Open the Map tab\n2. Pan diagonally across campus\n3. Observe bus position',
        ),
        'Step 1: Open map. Step 2: Pan camera. Step 3: Observe marker.',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'What did you expect to happen?'),
        'Bus marker stays anchored to lat/lng.',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'What actually happened?'),
        'Bus marker floats with the pan gesture.',
      );

      // Submit
      await tester.tap(find.text('Submit Bug Report'));
      await tester.pump(const Duration(milliseconds: 100));

      // Wait for async submission
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('Bug Report Submitted'), findsOneWidget);
      expect(find.text('Back to Settings'), findsOneWidget);
    });

    testWidgets('GeneralFeedbackScreen updates star rating and submits', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: GeneralFeedbackScreen()));

      expect(find.text('App Feedback'), findsOneWidget);
      expect(find.text('Excellent'), findsOneWidget);

      // Change rating to 3 stars
      final starButtons = find.byType(IconButton);
      await tester.tap(starButtons.at(2)); // 3rd star
      await tester.pumpAndSettle();

      expect(find.text('Good'), findsOneWidget);

      // Validate comments required
      await tester.tap(find.text('Submit Feedback'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please provide comments of at least 8 characters.'),
        findsOneWidget,
      );

      // Fill comments
      await tester.enterText(
        find.byType(TextFormField),
        'Great bus tracking app for NIT Calicut campus students!',
      );

      await tester.tap(find.text('Submit Feedback'));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('Feedback Received!'), findsOneWidget);
    });

    testWidgets('FeatureSuggestionScreen validates and submits', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: FeatureSuggestionScreen()),
      );

      expect(find.text('Suggest a Feature'), findsOneWidget);
      expect(find.text('Feature Title *'), findsOneWidget);
      expect(find.text('Target Audience / Use Case *'), findsOneWidget);
      expect(find.text('Problem It Solves *'), findsOneWidget);

      // Attempt submit without filling
      await tester.tap(find.text('Submit Feature Idea'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter a feature title of at least 5 characters.'),
        findsOneWidget,
      );

      // Fill valid inputs
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'e.g. Push notification 5 minutes before bus arrives',
        ),
        'Live notification alarm',
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'e.g. Mega Hostel residents during morning rush hour',
        ),
        'Hostel students commuting to morning lectures',
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'What challenge or inconvenience does this feature address?',
        ),
        'Prevents students from missing the morning bus at Mega Hostel stop.',
      );

      await tester.tap(find.text('Submit Feature Idea'));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('Idea Submitted!'), findsOneWidget);
    });

    testWidgets(
      'TrackletSnackBar displays semantic types and floating behavior',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed:
                            () => TrackletSnackBar.showSuccess(
                              context,
                              'Success message',
                            ),
                        child: const Text('Show Success'),
                      ),
                      ElevatedButton(
                        onPressed:
                            () => TrackletSnackBar.showError(
                              context,
                              'Error message',
                            ),
                        child: const Text('Show Error'),
                      ),
                      ElevatedButton(
                        onPressed:
                            () => TrackletSnackBar.showWarning(
                              context,
                              'Warning message',
                            ),
                        child: const Text('Show Warning'),
                      ),
                      ElevatedButton(
                        onPressed:
                            () => TrackletSnackBar.showInfo(
                              context,
                              'Info message',
                            ),
                        child: const Text('Show Info'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Success'));
        await tester.pump();

        expect(find.text('Success message'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.behavior, SnackBarBehavior.floating);

        // Showing another snackbar should replace immediately
        await tester.tap(find.text('Show Error'));
        await tester.pump();

        expect(find.text('Error message'), findsOneWidget);
      },
    );
  });
}
