import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/app/router.dart';
import 'package:tracklet/data/auth/auth_repository.dart';
import 'package:tracklet/data/profile/profile.dart';
import 'package:tracklet/data/profile/profile_repository.dart';
import 'package:tracklet/features/auth/forgot_password_screen.dart';
import 'package:tracklet/features/auth/login_screen.dart';
import 'package:tracklet/data/auth/auth_state.dart';
import 'package:tracklet/features/auth/providers/auth_provider.dart';
import 'package:tracklet/features/auth/reset_password_screen.dart';

import 'auth_notifier_test.dart';

class TestMockProfileRepo implements ProfileRepository {
  Profile? mockProfile;
  bool shouldThrow = false;

  @override
  Future<Profile> getProfile() async {
    if (shouldThrow) throw Exception('Profile fetch failed');
    return mockProfile ??
        const Profile(
          id: 'test-user',
          name: 'Student',
          email: 'student@nitc.ac.in',
          hasCompletedOnboarding: false,
        );
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    if (shouldThrow) throw Exception('Profile save failed');
    mockProfile = profile;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    if (shouldThrow) throw Exception('Complete onboarding failed');
    mockProfile = (mockProfile ??
            const Profile(
              id: 'test-user',
              name: 'Student',
              email: 'student@nitc.ac.in',
            ))
        .copyWith(hasCompletedOnboarding: completed);
  }

  @override
  Future<bool> isUsernameAvailable(String username) async => true;

  @override
  Future<Profile> changeUsername(String newUsername) async {
    final updated = (mockProfile ??
            const Profile(
              id: 'test-user',
              name: 'Student',
              email: 'student@nitc.ac.in',
            ))
        .copyWith(username: newUsername);
    mockProfile = updated;
    return updated;
  }
}

void main() {
  group('Authentication Production Hardening Tests', () {
    test(
      'SupabaseAuthRepository(null) strictly rejects all auth operations',
      () async {
        final repo = SupabaseAuthRepository(null);
        addTearDown(repo.dispose);

        expect(repo.isAuthenticated, isFalse);
        expect(repo.currentUser, isNull);
        expect(repo.currentSession, isNull);

        final signInResult = await repo.signInWithEmail(
          'student@nitc.ac.in',
          'pw',
        );
        expect(signInResult.isSuccess, isFalse);
        expect(signInResult.errorMessage, contains('unavailable'));

        final signUpResult = await repo.signUpWithEmail(
          'student@nitc.ac.in',
          'pw',
        );
        expect(signUpResult.isSuccess, isFalse);
        expect(signUpResult.errorMessage, contains('unavailable'));

        final resetResult = await repo.resetPasswordForEmail(
          'student@nitc.ac.in',
        );
        expect(resetResult.isSuccess, isFalse);

        final updateResult = await repo.updatePassword('newPassword');
        expect(updateResult.isSuccess, isFalse);

        final googleResult = await repo.signInWithGoogle();
        expect(googleResult.isSuccess, isFalse);
      },
    );

    test(
      'LocalOrSupabaseProfileRepository(null) returns safe unauthenticated guest profile without mock data',
      () async {
        final repo = LocalOrSupabaseProfileRepository(null);

        final profile = await repo.getProfile();
        expect(profile.id, 'guest');
        expect(profile.name, 'Student');
        expect(profile.email, 'student@nitc.ac.in');
        expect(profile.hasCompletedOnboarding, isFalse);
        expect(profile.department, isEmpty);
        expect(profile.hostel, isEmpty);
        expect(profile.batch, isEmpty);
      },
    );

    testWidgets(
      'Router redirect blocks unauthorized access to /reset-password',
      (tester) async {
        final mockAuth = MockAuthRepository();
        final mockProfile = TestMockProfileRepo();

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            profileRepositoryProvider.overrideWithValue(mockProfile),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: Consumer(
              builder: (context, ref, _) {
                final router = ref.watch(routerProvider);
                return MaterialApp.router(routerConfig: router);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Attempting to navigate directly to /reset-password
        container.read(routerProvider).go('/reset-password');
        await tester.pumpAndSettle();

        // Must be redirected to /forgot-password since no recovery is active
        expect(find.byType(ResetPasswordScreen), findsNothing);
        expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      },
    );

    testWidgets('Router permits /reset-password when recovery is in progress', (
      tester,
    ) async {
      final mockAuth = MockAuthRepository();
      final mockProfile = TestMockProfileRepo();

      mockAuth.emit(
        const AuthState(
          status: AuthStatus.passwordRecoveryInProgress,
          email: 'student@nitc.ac.in',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          profileRepositoryProvider.overrideWithValue(mockProfile),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(authNotifierProvider.notifier)
          .setRecoveryInProgress(email: 'student@nitc.ac.in');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      expect(find.text('Reset password'), findsOneWidget);
    });

    testWidgets(
      'Router redirects unauthenticated users to /login on root access',
      (tester) async {
        final mockAuth = MockAuthRepository();
        final mockProfile = TestMockProfileRepo();

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            profileRepositoryProvider.overrideWithValue(mockProfile),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: Consumer(
              builder: (context, ref, _) {
                final router = ref.watch(routerProvider);
                return MaterialApp.router(routerConfig: router);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Welcome back'), findsOneWidget);
      },
    );

    test(
      'Sign out invalidates profile and resets to unauthenticated',
      () async {
        final mockAuth = MockAuthRepository();
        final mockProfile = TestMockProfileRepo();

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            profileRepositoryProvider.overrideWithValue(mockProfile),
          ],
        );
        addTearDown(container.dispose);

        final authNotifier = container.read(authNotifierProvider.notifier);
        await authNotifier.signIn('student@nitc.ac.in', 'password123');

        expect(container.read(authNotifierProvider).isAuthenticated, isTrue);

        await authNotifier.signOut();

        expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
        expect(container.read(authNotifierProvider).user, isNull);
        expect(container.read(authNotifierProvider).session, isNull);
      },
    );
  });
}
