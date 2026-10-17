import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:tracklet/app/router.dart';
import 'package:tracklet/data/auth/auth_repository.dart';
import 'package:tracklet/data/profile/profile.dart';
import 'package:tracklet/data/auth/auth_result.dart';
import 'package:tracklet/data/auth/auth_state.dart';
import 'package:tracklet/features/admin/providers/admin_provider.dart';
import 'package:tracklet/features/profile/providers/profile_provider.dart';

void main() {
  group('Router Route Guard Tests', () {
    testWidgets(
      'unauthenticated user is redirected to /login when visiting /',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(
                const AuthState(status: AuthStatus.unauthenticated),
              ),
            ),
          ],
        );

        final router = container.read(routerProvider);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, '/login');
      },
    );

    testWidgets(
      'authenticated user with incomplete onboarding is redirected to /onboarding',
      (tester) async {
        final mockUser = User(
          id: 'test-student',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: 'test@nitc.ac.in',
        );

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(
                AuthState(
                  status: AuthStatus.authenticated,
                  user: mockUser,
                  email: 'test@nitc.ac.in',
                ),
              ),
            ),
            profileStateProvider.overrideWith(
              () => _FixedProfileNotifier(
                const Profile(
                  id: 'test-student',
                  name: 'Student',
                  email: 'test@nitc.ac.in',
                  hasCompletedOnboarding: false,
                ),
              ),
            ),
          ],
        );

        final router = container.read(routerProvider);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, '/onboarding');
      },
    );

    testWidgets(
      'authenticated user waits for profile before choosing onboarding',
      (tester) async {
        final mockUser = User(
          id: 'test-student',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: 'test@nitc.ac.in',
        );

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(
                AuthState(status: AuthStatus.authenticated, user: mockUser),
              ),
            ),
            profileStateProvider.overrideWith(_LoadingProfileNotifier.new),
          ],
        );

        final router = container.read(routerProvider);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, '/login');
      },
    );

    testWidgets(
      'authenticated user with completed onboarding is redirected to /',
      (tester) async {
        final mockUser = User(
          id: 'test-student',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: 'test@nitc.ac.in',
        );

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(
                AuthState(
                  status: AuthStatus.authenticated,
                  user: mockUser,
                  email: 'test@nitc.ac.in',
                ),
              ),
            ),
            profileStateProvider.overrideWith(
              () => _FixedProfileNotifier(
                const Profile(
                  id: 'test-student',
                  name: 'Student',
                  email: 'test@nitc.ac.in',
                  hasCompletedOnboarding: true,
                ),
              ),
            ),
          ],
        );

        final router = container.read(routerProvider);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, '/');
      },
    );

    testWidgets('password recovery state redirects to /reset-password', (
      tester,
    ) async {
      final mockUser = User(
        id: 'test-student',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'test@nitc.ac.in',
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              AuthState(
                status: AuthStatus.passwordRecoveryInProgress,
                user: mockUser,
                email: 'test@nitc.ac.in',
              ),
            ),
          ),
        ],
      );

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/reset-password');
    });

    testWidgets(
      'authenticated anonymous guest is routed to / without requiring onboarding',
      (tester) async {
        final mockGuestUser = User(
          id: 'test-guest-uuid',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          isAnonymous: true,
        );

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(
                AuthState(
                  status: AuthStatus.authenticated,
                  user: mockGuestUser,
                ),
              ),
            ),
            profileStateProvider.overrideWith(
              () => _FixedProfileNotifier(
                const Profile(
                  id: 'test-guest-uuid',
                  name: 'Guest Rider',
                  email: '',
                  role: 'Guest',
                  hasCompletedOnboarding: true,
                ),
              ),
            ),
          ],
        );

        final router = container.read(routerProvider);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, '/');
      },
    );

    testWidgets(
      'unauthenticated user visiting /admin is redirected to /login',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(
                const AuthState(status: AuthStatus.unauthenticated),
              ),
            ),
          ],
        );

        final router = container.read(routerProvider);
        router.go('/admin');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, '/login');
      },
    );

    testWidgets('authenticated guest user visiting /admin is redirected to /', (
      tester,
    ) async {
      final mockGuestUser = User(
        id: 'test-guest-uuid',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        isAnonymous: true,
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              AuthState(status: AuthStatus.authenticated, user: mockGuestUser),
            ),
          ),
        ],
      );

      final router = container.read(routerProvider);
      router.go('/admin');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/');
    });

    testWidgets(
      'authenticated non-admin user visiting /admin is redirected to /',
      (tester) async {
        final mockUser = User(
          id: 'student-uuid',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: 'student@nitc.ac.in',
        );

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(
                AuthState(
                  status: AuthStatus.authenticated,
                  user: mockUser,
                  email: 'student@nitc.ac.in',
                ),
              ),
            ),
            profileStateProvider.overrideWith(
              () => _FixedProfileNotifier(
                const Profile(
                  id: 'student-uuid',
                  name: 'Student',
                  email: 'student@nitc.ac.in',
                  hasCompletedOnboarding: true,
                ),
              ),
            ),
            isAdminProvider.overrideWith((ref) => Future.value(false)),
          ],
        );

        final router = container.read(routerProvider);
        router.go('/admin');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, '/');
      },
    );
  });
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._state);
  final AuthState _state;

  @override
  Stream<AuthState> get authStateChanges => Stream.value(_state);

  @override
  AuthState get currentAuthState => _state;

  @override
  User? get currentUser => _state.user;

  @override
  Session? get currentSession => _state.session;

  @override
  bool get isAuthenticated => _state.isAuthenticated;

  @override
  Future<AuthResult> signInWithEmail(
    String email,
    String password, {
    String? captchaToken,
  }) async => AuthResult.success(user: _state.user);

  @override
  Future<AuthResult> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
    String? captchaToken,
  }) async => AuthResult.success(user: _state.user);

  @override
  Future<AuthResult> resetPasswordForEmail(
    String email, {
    String? redirectTo,
    String? captchaToken,
  }) async => AuthResult.success();

  @override
  Future<AuthResult> updatePassword(String newPassword) async =>
      AuthResult.success(user: _state.user);

  @override
  Future<AuthResult> resendVerificationEmail(
    String email, {
    String? captchaToken,
  }) async => AuthResult.success();

  @override
  Future<AuthResult> signInWithGoogle() async =>
      AuthResult.success(user: _state.user);

  @override
  Future<AuthResult> signInAnonymously({String? captchaToken}) async =>
      AuthResult.success(user: _state.user);

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  void dispose() {}
}

class _FixedProfileNotifier extends ProfileNotifier {
  _FixedProfileNotifier(this._profile);
  final Profile _profile;

  @override
  Future<Profile> build() async {
    return _profile;
  }
}

class _LoadingProfileNotifier extends ProfileNotifier {
  @override
  Future<Profile> build() => Completer<Profile>().future;
}
