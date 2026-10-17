import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:tracklet/app/router.dart';
import 'package:tracklet/data/auth/auth_repository.dart';
import 'package:tracklet/data/auth/auth_result.dart';
import 'package:tracklet/data/auth/auth_state.dart';
import 'package:tracklet/data/profile/profile.dart';
import 'package:tracklet/features/profile/providers/profile_provider.dart';
import 'package:tracklet/features/splash/splash_screen.dart';

class _FakeAuthRepo implements AuthRepository {
  _FakeAuthRepo(this._state);
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
  Future<Profile> build() async => _profile;
}

void main() {
  group('BusTrackerSplashScreen Tests', () {
    testWidgets('renders bus icon and wordmark assets', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepo(const AuthState(status: AuthStatus.unauthenticated)),
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

      // Verify that BusTrackerSplashScreen is rendered initially
      expect(find.byType(BusTrackerSplashScreen), findsOneWidget);

      // Verify branding image assets are in tree
      final images = tester.widgetList<Image>(find.byType(Image));
      final assetPaths =
          images.map((img) => (img.image as AssetImage).assetName).toSet();

      expect(assetPaths, contains('assets/branding/bustracker_bus_icon.png'));
      expect(assetPaths, contains('assets/branding/bustracker_wordmark.png'));

      await tester.pumpAndSettle();
    });

    testWidgets(
      'unauthenticated user navigates to /login after splash completes',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _FakeAuthRepo(
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

        expect(router.routeInformationProvider.value.uri.path, '/splash');

        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, '/login');
      },
    );

    testWidgets('guest user navigates to / without requiring onboarding', (
      tester,
    ) async {
      final mockGuest = User(
        id: 'guest-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        isAnonymous: true,
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepo(
              AuthState(status: AuthStatus.authenticated, user: mockGuest),
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
    });

    testWidgets(
      'student user with incomplete onboarding navigates to /onboarding',
      (tester) async {
        final mockStudent = User(
          id: 'student-123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: 'student@nitc.ac.in',
        );

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _FakeAuthRepo(
                AuthState(
                  status: AuthStatus.authenticated,
                  user: mockStudent,
                  email: 'student@nitc.ac.in',
                ),
              ),
            ),
            profileStateProvider.overrideWith(
              () => _FixedProfileNotifier(
                const Profile(
                  id: 'student-123',
                  name: 'NITC Student',
                  email: 'student@nitc.ac.in',
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

    testWidgets('student user with completed onboarding navigates to /', (
      tester,
    ) async {
      final mockStudent = User(
        id: 'student-456',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'student@nitc.ac.in',
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepo(
              AuthState(
                status: AuthStatus.authenticated,
                user: mockStudent,
                email: 'student@nitc.ac.in',
              ),
            ),
          ),
          profileStateProvider.overrideWith(
            () => _FixedProfileNotifier(
              const Profile(
                id: 'student-456',
                name: 'NITC Student',
                email: 'student@nitc.ac.in',
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
    });
  });
}
