import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:tracklet/data/auth/auth_result.dart';
import 'package:tracklet/data/auth/auth_state.dart';

void main() {
  group('AuthState Model Tests', () {
    test('default constructor initializes to uninitialized state', () {
      const state = AuthState();
      expect(state.status, AuthStatus.uninitialized);
      expect(state.user, isNull);
      expect(state.session, isNull);
      expect(state.errorMessage, isNull);
      expect(state.email, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.isAuthenticating, isFalse);
      expect(state.isRecoveryFlow, isFalse);
    });

    test('isAuthenticated returns true only when authenticated with user', () {
      final user = User(
        id: 'test-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      final stateAuth = AuthState(status: AuthStatus.authenticated, user: user);
      expect(stateAuth.isAuthenticated, isTrue);

      const stateNoUser = AuthState(status: AuthStatus.authenticated);
      expect(stateNoUser.isAuthenticated, isFalse);
    });

    test('isAuthenticating and isRecoveryFlow flags compute correctly', () {
      const stateAuth = AuthState(status: AuthStatus.authenticating);
      expect(stateAuth.isAuthenticating, isTrue);

      const stateRecovery = AuthState(
        status: AuthStatus.passwordRecoveryInProgress,
      );
      expect(stateRecovery.isRecoveryFlow, isTrue);
    });

    test('copyWith updates fields properly', () {
      const initial = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Initial error',
      );

      final updated = initial.copyWith(
        status: AuthStatus.authenticated,
        email: 'student@nitc.ac.in',
        clearError: true,
      );

      expect(updated.status, AuthStatus.authenticated);
      expect(updated.email, 'student@nitc.ac.in');
      expect(updated.errorMessage, isNull);
    });

    test('equality and hashCode work as expected', () {
      const state1 = AuthState(
        status: AuthStatus.unauthenticated,
        email: 'test@nitc.ac.in',
      );
      const state2 = AuthState(
        status: AuthStatus.unauthenticated,
        email: 'test@nitc.ac.in',
      );
      const state3 = AuthState(
        status: AuthStatus.authenticated,
        email: 'test@nitc.ac.in',
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1, isNot(equals(state3)));
    });
  });

  group('AuthResult Model Tests', () {
    test('AuthResult.success creates successful result', () {
      final user = User(
        id: 'test-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      final result = AuthResult.success(user: user);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.user?.id, 'test-user-id');
      expect(result.requiresVerification, isFalse);
      expect(result.errorMessage, isNull);
    });

    test('AuthResult.failure creates failed result with message', () {
      final result = AuthResult.failure('Invalid credentials');

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.errorMessage, 'Invalid credentials');
    });

    test('AuthResult with requiresVerification flag', () {
      final result = AuthResult.success(requiresVerification: true);

      expect(result.isSuccess, isTrue);
      expect(result.requiresVerification, isTrue);
    });
  });
}
