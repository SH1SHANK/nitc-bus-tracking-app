import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/data/auth/auth_repository.dart';
import 'package:tracklet/data/auth/auth_state.dart';

void main() {
  group('SupabaseAuthRepository Hardening & Mock-Prevention Tests', () {
    late SupabaseAuthRepository repository;

    setUp(() {
      repository = SupabaseAuthRepository(null);
    });

    tearDown(() {
      repository.dispose();
    });

    test(
      'initial state emits unauthenticated when no credentials exist',
      () async {
        final state = await repository.authStateChanges.first;
        expect(state.status, AuthStatus.unauthenticated);
        expect(repository.isAuthenticated, isFalse);
        expect(repository.currentUser, isNull);
        expect(repository.currentSession, isNull);
      },
    );

    test(
      'signInWithEmail fails cleanly without fabricating user session',
      () async {
        final result = await repository.signInWithEmail(
          'student@nitc.ac.in',
          'password123',
        );

        expect(result.isSuccess, isFalse);
        expect(
          result.errorMessage,
          contains('Authentication service is unavailable'),
        );
        expect(result.user, isNull);
        expect(repository.isAuthenticated, isFalse);
        expect(repository.currentUser, isNull);
        expect(repository.currentSession, isNull);
      },
    );

    test(
      'signUpWithEmail fails cleanly without creating fake student',
      () async {
        final result = await repository.signUpWithEmail(
          'newstudent@nitc.ac.in',
          'securePass123',
          fullName: 'New NITC Student',
        );

        expect(result.isSuccess, isFalse);
        expect(
          result.errorMessage,
          contains('Authentication service is unavailable'),
        );
        expect(result.user, isNull);
        expect(repository.isAuthenticated, isFalse);
        expect(repository.currentUser, isNull);
      },
    );

    test('resetPasswordForEmail fails cleanly when uninitialized', () async {
      final result = await repository.resetPasswordForEmail(
        'student@nitc.ac.in',
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.errorMessage,
        contains('Authentication service is unavailable'),
      );
    });

    test('updatePassword fails cleanly when uninitialized', () async {
      final result = await repository.updatePassword('newPassword123');

      expect(result.isSuccess, isFalse);
      expect(
        result.errorMessage,
        contains('Authentication service is unavailable'),
      );
    });

    test('resendVerificationEmail fails cleanly when uninitialized', () async {
      final result = await repository.resendVerificationEmail(
        'student@nitc.ac.in',
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.errorMessage,
        contains('Authentication service is unavailable'),
      );
    });

    test('signInWithGoogle fails cleanly when uninitialized', () async {
      final result = await repository.signInWithGoogle();

      expect(result.isSuccess, isFalse);
      expect(
        result.errorMessage,
        contains('Authentication service is unavailable'),
      );
    });

    test(
      'signInWithEmail rejects unauthorized domain with exact message',
      () async {
        final result = await repository.signInWithEmail(
          'user@gmail.com',
          'password123',
        );

        expect(result.isSuccess, isFalse);
        expect(
          result.errorMessage,
          'Please sign in using your @nitc.ac.in institute email address.',
        );
      },
    );

    test('signUpWithEmail rejects spoofed domain with exact message', () async {
      final result = await repository.signUpWithEmail(
        'user@fake-nitc.ac.in',
        'password123',
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.errorMessage,
        'Please sign in using your @nitc.ac.in institute email address.',
      );
    });

    test('signOut clears authenticated state', () async {
      await repository.signOut();
      expect(repository.isAuthenticated, isFalse);
      expect(repository.currentUser, isNull);
      expect(repository.currentSession, isNull);
    });
  });
}
