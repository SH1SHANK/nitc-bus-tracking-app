import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/data/academic/department.dart';
import 'package:tracklet/data/academic/department_repository.dart';
import 'package:tracklet/data/campus/hostel.dart';
import 'package:tracklet/data/campus/hostel_repository.dart';
import 'package:tracklet/data/profile/profile.dart';
import 'package:tracklet/data/profile/profile_repository.dart';
import 'package:tracklet/features/onboarding/onboarding_screen.dart';
import 'package:tracklet/features/onboarding/providers/onboarding_provider.dart';
import 'package:tracklet/features/onboarding/widgets/onboarding_progress_bar.dart';
import 'package:tracklet/features/onboarding/widgets/onboarding_step_loading.dart';

import '../../helpers/pump_app.dart';

class TestDepartmentRepo implements DepartmentRepository {
  @override
  Future<List<Department>> getDepartments() async {
    return const [
      Department(id: 'AR', name: 'Architecture & Planning'),
      Department(id: 'CS', name: 'Computer Science & Engineering'),
      Department(id: 'EC', name: 'Electronics & Communication Engineering'),
    ];
  }
}

class TestHostelRepo implements HostelRepository {
  @override
  Future<List<Hostel>> getHostels() async {
    return const [
      Hostel(id: 'A', name: 'A Hostel', shortCode: 'A', gender: 'boys'),
      Hostel(
        id: 'MBH_1',
        name: 'Mega Hostel (MBH - Phase 1)',
        shortCode: 'MBH-1',
        gender: 'boys',
      ),
      Hostel(
        id: 'LH_MAIN',
        name: 'Ladies Hostel (LH - Main Block)',
        shortCode: 'LH-Main',
        gender: 'girls',
      ),
    ];
  }
}

class TestProfileRepo implements ProfileRepository {
  Profile? savedProfile;
  bool onboardingCompleted = false;

  @override
  Future<Profile> getProfile() async =>
      savedProfile ??
      const Profile(id: '1', name: 'Student', email: 'student@nitc.ac.in');

  @override
  Future<void> saveProfile(Profile profile) async {
    savedProfile = profile;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    onboardingCompleted = completed;
  }

  @override
  Future<bool> isUsernameAvailable(String username) async => true;

  @override
  Future<Profile> changeUsername(String newUsername) async {
    final updated = (savedProfile ??
            const Profile(id: '1', name: 'Student', email: 'student@nitc.ac.in'))
        .copyWith(username: newUsername);
    savedProfile = updated;
    return updated;
  }
}

void main() {
  group('OnboardingScreen Widget Tests', () {
    testWidgets('welcome state shows BusTracker copy and setup progress', (
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

      expect(find.text('Welcome to BusTracker'), findsOneWidget);
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

    testWidgets('renders Step 1 Username screen initially', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpTrackletWidget(
        const OnboardingScreen(),
        overrides: [
          departmentRepositoryProvider.overrideWithValue(TestDepartmentRepo()),
          hostelRepositoryProvider.overrideWithValue(TestHostelRepo()),
          profileRepositoryProvider.overrideWithValue(TestProfileRepo()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(find.text('Choose Your Username'), findsOneWidget);
      expect(find.text("Let's Set Up Your Academic Profile"), findsNothing);
      expect(find.byType(OnboardingProgressBar), findsOneWidget);
      expect(find.byTooltip('Generate a username'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('starts on the provider current step', (tester) async {
      final container = ProviderContainer(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(TestDepartmentRepo()),
          hostelRepositoryProvider.overrideWithValue(TestHostelRepo()),
          profileRepositoryProvider.overrideWithValue(TestProfileRepo()),
        ],
      );
      addTearDown(container.dispose);
      container.read(onboardingProvider.notifier).setStep(1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to BusTracker'), findsOneWidget);
      expect(find.text('Choose Your Username'), findsNothing);
    });

    testWidgets(
      'generates username with magic wand and navigates to Welcome page on Continue',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final profileRepo = TestProfileRepo();

        await tester.pumpTrackletWidget(
          const OnboardingScreen(),
          overrides: [
            departmentRepositoryProvider.overrideWithValue(
              TestDepartmentRepo(),
            ),
            hostelRepositoryProvider.overrideWithValue(TestHostelRepo()),
            profileRepositoryProvider.overrideWithValue(profileRepo),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.text('Choose Your Username'), findsOneWidget);

        // Tap magic wand to generate a valid username
        await tester.tap(find.byTooltip('Generate a username'));
        await tester.pumpAndSettle();

        // Tap Continue
        final continueButton = find.text('Continue');
        expect(continueButton, findsOneWidget);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        // Should now be on Welcome / Loading screen
        expect(find.text('Welcome to BusTracker'), findsOneWidget);
        expect(find.text('Campus transit, made simple.', findRichText: true), findsOneWidget);
      },
    );
  });
}
