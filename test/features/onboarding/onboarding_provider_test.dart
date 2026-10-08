import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/onboarding/providers/onboarding_provider.dart';

void main() {
  group('OnboardingNotifier Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has correct defaults', () {
      final state = container.read(onboardingProvider);
      expect(state.currentStep, 0);
      expect(state.name, isNotEmpty);
      expect(state.branch, isNotEmpty);
      expect(state.batch, isNotEmpty);
      expect(state.semester, isNotEmpty);
      expect(state.username, isNotEmpty);
      expect(state.locationPermissionGranted, isFalse);
      expect(state.notificationPermissionGranted, isFalse);
      expect(state.agreedToTerms, isTrue);
      expect(state.loadingProgress, 0.0);
    });

    test('step progression works forwards and backwards', () {
      final notifier = container.read(onboardingProvider.notifier);

      expect(container.read(onboardingProvider).currentStep, 0);

      notifier.nextStep();
      expect(container.read(onboardingProvider).currentStep, 1);

      notifier.setBranch('Electronics & Communication Engineering');
      expect(
        container.read(onboardingProvider).branch,
        'Electronics & Communication Engineering',
      );

      notifier.setBatch('Batch of 2027 (3rd Year)');
      expect(
        container.read(onboardingProvider).batch,
        'Batch of 2027 (3rd Year)',
      );

      notifier.setSemester('Semester 4 (Winter)');
      expect(
        container.read(onboardingProvider).semester,
        'Semester 4 (Winter)',
      );

      notifier.previousStep();
      expect(container.read(onboardingProvider).currentStep, 0);

      // Should not go below 0
      notifier.previousStep();
      expect(container.read(onboardingProvider).currentStep, 0);
    });

    test('updateUsername filters invalid names and handles availability', () {
      final notifier = container.read(onboardingProvider.notifier);

      notifier.updateUsername('@admin');
      expect(container.read(onboardingProvider).username, 'admin');
      expect(container.read(onboardingProvider).isUsernameAvailable, isFalse);

      notifier.updateUsername('@cool_student');
      expect(container.read(onboardingProvider).username, 'cool_student');
      expect(container.read(onboardingProvider).isUsernameAvailable, isTrue);
    });

    test('generateRandomUsername assigns valid username', () {
      final notifier = container.read(onboardingProvider.notifier);

      notifier.generateRandomUsername();
      final username = container.read(onboardingProvider).username;
      expect(username, isNotEmpty);
      expect(container.read(onboardingProvider).isUsernameAvailable, isTrue);
    });

    test('preferences and permissions update correctly', () {
      final notifier = container.read(onboardingProvider.notifier);

      notifier.setHostel('Ladies Hostel Complex (LH)');
      expect(
        container.read(onboardingProvider).hostel,
        'Ladies Hostel Complex (LH)',
      );

      notifier.setPrimaryStop('ELHC & NLHC Lecture Halls');
      expect(
        container.read(onboardingProvider).primaryStop,
        'ELHC & NLHC Lecture Halls',
      );

      notifier.setLocationPermission(true);
      expect(
        container.read(onboardingProvider).locationPermissionGranted,
        isTrue,
      );

      notifier.setNotificationPermission(true);
      expect(
        container.read(onboardingProvider).notificationPermissionGranted,
        isTrue,
      );

      notifier.toggleTerms(false);
      expect(container.read(onboardingProvider).agreedToTerms, isFalse);
    });
  });
}
