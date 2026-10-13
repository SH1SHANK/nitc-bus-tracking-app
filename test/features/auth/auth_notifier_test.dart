import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:tracklet/data/auth/auth_repository.dart';
import 'package:tracklet/data/auth/auth_result.dart';
import 'package:tracklet/data/auth/auth_state.dart';
import 'package:tracklet/features/auth/providers/auth_provider.dart';

class MockAuthRepository implements AuthRepository {
  final _stateController = StreamController<AuthState>.broadcast();
  AuthState _current = const AuthState(status: AuthStatus.unauthenticated);
  User? _mockUser;
  Session? _mockSession;

  bool shouldFail = false;

  void emit(AuthState state) {
    _current = state;
    _stateController.add(state);
  }

  @override
  Stream<AuthState> get authStateChanges async* {
    yield _current;
    yield* _stateController.stream;
  }

  @override
  AuthState get currentAuthState => _current;

  @override
  User? get currentUser => _mockUser;

  @override
  Session? get currentSession => _mockSession;

  @override
  bool get isAuthenticated => _mockUser != null;

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    if (shouldFail) {
      return AuthResult.failure('Incorrect email or password.');
    }
    _mockUser = User(
      id: 'test-user-id',
      appMetadata: {},
      userMetadata: {'full_name': 'Test Student'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
    _mockSession = Session(
      accessToken: 'test-token',
      tokenType: 'bearer',
      user: _mockUser!,
    );
    emit(
      AuthState(
        status: AuthStatus.authenticated,
        user: _mockUser,
        session: _mockSession,
        email: email,
      ),
    );
    return AuthResult.success(user: _mockUser, session: _mockSession);
  }

  @override
  Future<AuthResult> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
  }) async {
    if (shouldFail) {
      return AuthResult.failure('An account with this email already exists.');
    }
    _mockUser = User(
      id: 'test-user-id',
      appMetadata: {},
      userMetadata: {'full_name': fullName ?? 'Student'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
    return AuthResult.success(user: _mockUser, requiresVerification: true);
  }

  @override
  Future<AuthResult> resetPasswordForEmail(
    String email, {
    String? redirectTo,
  }) async {
    if (shouldFail) {
      return AuthResult.failure('Too many requests. Please wait.');
    }
    emit(AuthState(status: AuthStatus.passwordRecoverySent, email: email));
    return AuthResult.success();
  }

  @override
  Future<AuthResult> updatePassword(String newPassword) async {
    if (shouldFail) {
      return AuthResult.failure('Failed to update password.');
    }
    return AuthResult.success(user: _mockUser);
  }

  @override
  Future<AuthResult> resendVerificationEmail(String email) async {
    if (shouldFail) {
      return AuthResult.failure('Failed to resend email.');
    }
    return AuthResult.success();
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    if (shouldFail) {
      return AuthResult.failure('Google sign in failed.');
    }
    return AuthResult.success();
  }

  @override
  Future<void> signOut() async {
    _mockUser = null;
    _mockSession = null;
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  @override
  void dispose() {
    _stateController.close();
  }
}

void main() {
  group('AuthNotifier Unit Tests', () {
    late MockAuthRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockAuthRepository();
      container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() {
      container.dispose();
      mockRepo.dispose();
    });

    test('initial state initializes to unauthenticated', () {
      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.isAuthenticated, isFalse);
    });

    test('signIn updates state to authenticated with email', () async {
      final notifier = container.read(authNotifierProvider.notifier);

      final result = await notifier.signIn('student@nitc.ac.in', 'password123');

      expect(result.isSuccess, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.email, 'student@nitc.ac.in');
      expect(state.isAuthenticated, isTrue);
    });

    test(
      'signIn failure surfaces error and leaves user unauthenticated',
      () async {
        mockRepo.shouldFail = true;
        final notifier = container.read(authNotifierProvider.notifier);

        final result = await notifier.signIn(
          'student@nitc.ac.in',
          'wrongpassword',
        );

        expect(result.isSuccess, isFalse);
        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.unauthenticated);
        expect(state.errorMessage, contains('Incorrect email or password'));
        expect(state.isAuthenticated, isFalse);
      },
    );

    test('signUp updates state to verificationRequired', () async {
      final notifier = container.read(authNotifierProvider.notifier);

      final result = await notifier.signUp(
        'student2@nitc.ac.in',
        'securePass123',
        fullName: 'Test Student',
      );

      expect(result.isSuccess, isTrue);
      expect(result.requiresVerification, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.verificationRequired);
      expect(state.email, 'student2@nitc.ac.in');
    });

    test(
      'sendPasswordRecovery transitions state to passwordRecoverySent',
      () async {
        final notifier = container.read(authNotifierProvider.notifier);

        final result = await notifier.sendPasswordRecovery(
          'student@nitc.ac.in',
        );

        expect(result.isSuccess, isTrue);
        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.passwordRecoverySent);
        expect(state.email, 'student@nitc.ac.in');
      },
    );

    test('updatePassword updates password and transitions state', () async {
      final notifier = container.read(authNotifierProvider.notifier);

      final result = await notifier.updatePassword('brandNewPassword');

      expect(result.isSuccess, isTrue);
      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.authenticated);
    });

    test('setRecoveryInProgress sets recovery state', () {
      final notifier = container.read(authNotifierProvider.notifier);

      notifier.setRecoveryInProgress(email: 'recovery@nitc.ac.in');

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.passwordRecoveryInProgress);
      expect(state.email, 'recovery@nitc.ac.in');
      expect(state.isRecoveryFlow, isTrue);
    });

    test('signOut transitions state to unauthenticated', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn('student@nitc.ac.in', 'password123');
      expect(container.read(authNotifierProvider).isAuthenticated, isTrue);

      await notifier.signOut();
      expect(
        container.read(authNotifierProvider).status,
        AuthStatus.unauthenticated,
      );
      expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
    });

    test('clearError removes error message from state', () {
      final notifier = container.read(authNotifierProvider.notifier);
      notifier.setRecoveryInProgress(email: 'test@nitc.ac.in');
      notifier.clearError();

      expect(container.read(authNotifierProvider).errorMessage, isNull);
    });
  });
}
