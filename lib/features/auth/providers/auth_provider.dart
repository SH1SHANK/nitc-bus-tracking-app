import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth/auth_repository.dart';
import '../../../data/auth/auth_result.dart';
import '../../../data/auth/auth_state.dart';
import '../../../services/notifications/onesignal_service.dart';

/// Riverpod Notifier managing authentication states and operations.
class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription<AuthState>? _authSub;
  String? _oneSignalUserId;
  bool _hasSyncedOneSignalIdentity = false;

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    final repo = ref.watch(authRepositoryProvider);
    _init(repo);
    ref.onDispose(() {
      _authSub?.cancel();
    });
    return repo.currentAuthState;
  }

  void _init(AuthRepository repo) {
    _authSub?.cancel();
    _authSub = repo.authStateChanges.listen((newState) {
      _syncOneSignalIdentity(newState);
      state = newState;
    });

    _syncOneSignalIdentity(repo.currentAuthState);

    // Check immediate status
    if (repo.isAuthenticated) {
      final user = repo.currentUser;
      final session = repo.currentSession;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        session: session,
        email: user?.email,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void _syncOneSignalIdentity(AuthState authState) {
    if (!OneSignalService.isAvailable) return;

    final userId =
        authState.isAuthenticated && !authState.isGuest
            ? authState.user!.id
            : null;
    if (_hasSyncedOneSignalIdentity && userId == _oneSignalUserId) return;

    _hasSyncedOneSignalIdentity = true;
    _oneSignalUserId = userId;
    unawaited(
      userId == null
          ? OneSignalService.logout()
          : OneSignalService.login(userId),
    );
  }

  /// Sign in with student email and password.
  Future<AuthResult> signIn(
    String email,
    String password, {
    String? captchaToken,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);

    final result = await _authRepository.signInWithEmail(
      email,
      password,
      captchaToken: captchaToken,
    );

    if (result.isSuccess) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
        session: result.session,
        email: result.user?.email ?? email.trim(),
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: result.errorMessage,
      );
    }

    return result;
  }

  /// Register a new student account.
  Future<AuthResult> signUp(
    String email,
    String password, {
    String? fullName,
    String? captchaToken,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);

    final result = await _authRepository.signUpWithEmail(
      email,
      password,
      fullName: fullName,
      captchaToken: captchaToken,
    );

    if (result.isSuccess) {
      if (result.requiresVerification) {
        state = AuthState(
          status: AuthStatus.verificationRequired,
          user: result.user,
          email: email.trim(),
        );
      } else {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: result.user,
          session: result.session,
          email: email.trim(),
        );
      }
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: result.errorMessage,
      );
    }

    return result;
  }

  /// Send password recovery magic link to email.
  Future<AuthResult> sendPasswordRecovery(
    String email, {
    String? captchaToken,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);

    final result = await _authRepository.resetPasswordForEmail(
      email,
      captchaToken: captchaToken,
    );

    if (result.isSuccess) {
      state = AuthState(
        status: AuthStatus.passwordRecoverySent,
        email: email.trim(),
        lastActionTime: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: result.errorMessage,
      );
    }

    return result;
  }

  /// Update password during recovery or session.
  Future<AuthResult> updatePassword(String newPassword) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);

    final result = await _authRepository.updatePassword(newPassword);

    if (result.isSuccess) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user ?? _authRepository.currentUser,
        session: _authRepository.currentSession,
        email: result.user?.email ?? _authRepository.currentUser?.email,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.passwordRecoveryInProgress,
        errorMessage: result.errorMessage,
      );
    }

    return result;
  }

  /// Resend email verification.
  Future<AuthResult> resendVerification(
    String email, {
    String? captchaToken,
  }) async {
    return _authRepository.resendVerificationEmail(
      email,
      captchaToken: captchaToken,
    );
  }

  /// Sign in with Google OAuth.
  Future<AuthResult> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);

    final result = await _authRepository.signInWithGoogle();
    if (!result.isSuccess) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: result.errorMessage,
      );
    }
    return result;
  }

  /// Sign in anonymously as a guest.
  Future<AuthResult> signInAnonymously({String? captchaToken}) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);

    final result = await _authRepository.signInAnonymously(
      captchaToken: captchaToken,
    );
    if (result.isSuccess) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
        session: result.session,
        email: result.user?.email,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: result.errorMessage,
      );
    }
    return result;
  }

  /// Explicitly enter password recovery mode (e.g. from deep link callback).
  void setRecoveryInProgress({String? email}) {
    state = AuthState(
      status: AuthStatus.passwordRecoveryInProgress,
      email: email,
    );
  }

  /// Sign out current student session.
  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Permanently delete student account and associated data.
  Future<void> deleteAccount() async {
    await _authRepository.deleteAccount();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Clear any transient error messages.
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

/// Main Riverpod provider for Authentication state.
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
