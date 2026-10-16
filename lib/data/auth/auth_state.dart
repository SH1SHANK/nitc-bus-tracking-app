import 'package:supabase_flutter/supabase_flutter.dart';

/// Distinct authentication statuses for Tracklet.
enum AuthStatus {
  /// Session is being resolved from local storage / Supabase client on startup.
  uninitialized,

  /// No authenticated session active.
  unauthenticated,

  /// An asynchronous authentication operation is currently in flight.
  authenticating,

  /// User is successfully authenticated with a valid session.
  authenticated,

  /// Account created but email confirmation is pending in Supabase.
  verificationRequired,

  /// Password recovery / magic link has been sent.
  passwordRecoverySent,

  /// User opened a password recovery callback and is resetting their password.
  passwordRecoveryInProgress,

  /// An error occurred during an authentication operation.
  error,
}

/// Immutable state representation for the authentication lifecycle.
class AuthState {
  const AuthState({
    this.status = AuthStatus.uninitialized,
    this.user,
    this.session,
    this.errorMessage,
    this.email,
    this.lastActionTime,
  });

  final AuthStatus status;
  final User? user;
  final Session? session;
  final String? errorMessage;
  final String? email;
  final DateTime? lastActionTime;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isGuest => isAuthenticated && (user?.isAnonymous ?? false);
  bool get isAuthenticating => status == AuthStatus.authenticating;
  bool get isRecoveryFlow => status == AuthStatus.passwordRecoveryInProgress;
  bool get isGoogleUser =>
      user?.appMetadata['provider'] == 'google' ||
      (user?.identities?.any((i) => i.provider == 'google') ?? false);

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Session? session,
    String? errorMessage,
    String? email,
    DateTime? lastActionTime,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      session: session ?? this.session,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      email: email ?? this.email,
      lastActionTime: lastActionTime ?? this.lastActionTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          user?.id == other.user?.id &&
          errorMessage == other.errorMessage &&
          email == other.email;

  @override
  int get hashCode => Object.hash(status, user?.id, errorMessage, email);

  @override
  String toString() =>
      'AuthState(status: $status, userId: ${user?.id}, email: $email, error: $errorMessage)';
}
