import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/onboarding/widgets/onboarding_step_username.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('uses the animated campus mascot GIF', (tester) async {
    await tester.pumpTrackletWidget(
      const Scaffold(
        body: OnboardingStepUsername(
          initialUsername: '',
          isAvailable: null,
          onUsernameChanged: _ignoreText,
          onMagicWandPressed: _ignore,
          onContinue: _ignore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mascot = tester.widget<Image>(find.byType(Image));
    expect(
      (mascot.image as AssetImage).assetName,
      'assets/images/Research_New_Pin_Crop.gif',
    );
  });

  testWidgets('shows one accurate username status at a time', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpTrackletWidget(
      const Scaffold(
        body: OnboardingStepUsername(
          initialUsername: 'taken_name',
          isAvailable: false,
          onUsernameChanged: _ignoreText,
          onMagicWandPressed: _ignore,
          onContinue: _ignore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Username is already taken'), findsOneWidget);
    expect(find.text('Username available'), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );

    await tester.pumpTrackletWidget(
      const Scaffold(
        body: OnboardingStepUsername(
          initialUsername: 'campus_rider',
          isAvailable: true,
          onUsernameChanged: _ignoreText,
          onMagicWandPressed: _ignore,
          onContinue: _ignore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Username available'), findsOneWidget);
    expect(find.text('Username is already taken'), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('magic wand and available continue actions are interactive', (
    tester,
  ) async {
    var generated = false;
    var continued = false;

    await tester.pumpTrackletWidget(
      Scaffold(
        body: OnboardingStepUsername(
          initialUsername: 'campus_rider',
          isAvailable: true,
          onUsernameChanged: _ignoreText,
          onMagicWandPressed: () => generated = true,
          onContinue: () => continued = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Generate a username'));
    await tester.pump();
    expect(generated, isTrue);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(continued, isTrue);
  });
}

void _ignore() {}
void _ignoreText(String _) {}
