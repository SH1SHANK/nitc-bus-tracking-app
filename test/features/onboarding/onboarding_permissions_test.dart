import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/onboarding/widgets/onboarding_step_permissions.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('OnboardingStepPermissions Widget Tests', () {
    testWidgets('renders permissions cards and default checked states', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool? enabledLocation;
      bool? enabledNotifications;
      bool skipCalled = false;

      await tester.pumpTrackletWidget(
        Scaffold(
          body: OnboardingStepPermissions(
            locationGranted: false,
            notificationsGranted: false,
            onEnablePermissions: ({
              required bool enableLocation,
              required bool enableNotifications,
            }) async {
              enabledLocation = enableLocation;
              enabledNotifications = enableNotifications;
            },
            onSkip: () {
              skipCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Permissions & Access'), findsOneWidget);
      expect(find.text('Campus Live Location'), findsOneWidget);
      expect(find.text('Transit & Arrival Alerts'), findsOneWidget);
      expect(find.text('Continue without permissions'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);

      // Tap location card to select it
      await tester.tap(find.text('Campus Live Location'));
      await tester.pumpAndSettle();

      expect(find.text('Continue with selected'), findsOneWidget);

      // Tap continue
      await tester.tap(find.text('Continue with selected'));
      await tester.pumpAndSettle();

      expect(enabledLocation, isTrue);
      expect(enabledNotifications, isFalse);
      expect(skipCalled, isFalse);
    });

    testWidgets('allows skipping directly without enabling any permissions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool skipCalled = false;

      await tester.pumpTrackletWidget(
        Scaffold(
          body: OnboardingStepPermissions(
            locationGranted: false,
            notificationsGranted: false,
            onEnablePermissions:
                ({
                  required bool enableLocation,
                  required bool enableNotifications,
                }) async {},
            onSkip: () {
              skipCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      expect(skipCalled, isTrue);
    });

    testWidgets('displays Granted badge when location is already granted', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpTrackletWidget(
        Scaffold(
          body: OnboardingStepPermissions(
            locationGranted: true,
            notificationsGranted: false,
            onEnablePermissions:
                ({
                  required bool enableLocation,
                  required bool enableNotifications,
                }) async {},
            onSkip: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Granted'), findsOneWidget);
    });
  });
}
