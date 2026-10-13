import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../core/logging/app_logger.dart';
import 'auth_result.dart';
import 'auth_state.dart';
import '../supabase/supabase_client_provider.dart';

/// Abstract contract for Tracklet authentication operations.
abstract class AuthRepository {
  /// Stream emitting changes in authentication state (always emits current state first).
  Stream<AuthState> get authStateChanges;

  /// Current authentication state snapshot.
  AuthState get currentAuthState;

  /// Current authenticated Supabase user or null.
  User? get currentUser;

  /// Current active Supabase session or null.
  Session? get currentSession;

  /// True if a user is currently authenticated.
  bool get isAuthenticated;

  /// Sign in with student email and password.
  Future<AuthResult> signInWithEmail(String email, String password);

  /// Register a new student account.
  Future<AuthResult> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
  });

  /// Request a password recovery email.
  Future<AuthResult> resetPasswordForEmail(String email, {String? redirectTo});

  /// Update password for the currently authenticated recovery or active session.
  Future<AuthResult> updatePassword(String newPassword);

  /// Resend confirmation / verification email.
  Future<AuthResult> resendVerificationEmail(String email);

  /// Sign in using Google OAuth.
  Future<AuthResult> signInWithGoogle();

  /// Sign out the current user session and invalidate tokens.
  Future<void> signOut();

  /// Clean up streams and resources.
  void dispose();
}

/// Supabase Auth implementation of [AuthRepository] with resilient fallback for local tests.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._supabase) {
    _initAuthStream();
  }

  final SupabaseClient? _supabase;
  final _stateController = StreamController<AuthState>.broadcast();
  StreamSubscription<dynamic>? _supabaseSub;
  AuthState _currentState = const AuthState(status: AuthStatus.uninitialized);

  void _emitState(AuthState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  void _initAuthStream() {
    final client = _supabase;
    if (client != null) {
      // Determine initial state
      final currentSession = client.auth.currentSession;
      final currentUser = client.auth.currentUser;

      if (currentSession != null && currentUser != null) {
        _emitState(
          AuthState(
            status: AuthStatus.authenticated,
            user: currentUser,
            session: currentSession,
            email: currentUser.email,
          ),
        );
      } else {
        _emitState(const AuthState(status: AuthStatus.unauthenticated));
      }

      // Listen to live Supabase Auth state transitions
      _supabaseSub = client.auth.onAuthStateChange.listen(
        (data) {
          final event = data.event;
          final session = data.session;
          final user = session?.user ?? client.auth.currentUser;

          AppLogger.info('Supabase Auth state changed: $event');

          switch (event) {
            case AuthChangeEvent.signedIn:
              _emitState(
                AuthState(
                  status: AuthStatus.authenticated,
                  user: user,
                  session: session,
                  email: user?.email,
                ),
              );
              break;
            case AuthChangeEvent.signedOut:
              _emitState(const AuthState(status: AuthStatus.unauthenticated));
              break;
            case AuthChangeEvent.passwordRecovery:
              _emitState(
                AuthState(
                  status: AuthStatus.passwordRecoveryInProgress,
                  user: user,
                  session: session,
                  email: user?.email,
                ),
              );
              break;
            case AuthChangeEvent.tokenRefreshed:
            case AuthChangeEvent.userUpdated:
              if (user != null) {
                _emitState(
                  AuthState(
                    status: AuthStatus.authenticated,
                    user: user,
                    session: session,
                    email: user.email,
                  ),
                );
              }
              break;
            case AuthChangeEvent.mfaChallengeVerified:
            case AuthChangeEvent.initialSession:
            default:
              break;
          }
        },
        onError: (Object error) {
          AppLogger.error('Auth state stream error', error: error);
          _emitState(
            AuthState(
              status: AuthStatus.error,
              errorMessage: _mapAuthError(error),
            ),
          );
        },
      );
    } else {
      _emitState(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  @override
  Stream<AuthState> get authStateChanges async* {
    yield _currentState;
    yield* _stateController.stream;
  }

  @override
  AuthState get currentAuthState => _currentState;

  @override
  User? get currentUser => _supabase?.auth.currentUser;

  @override
  Session? get currentSession => _supabase?.auth.currentSession;

  @override
  bool get isAuthenticated => currentUser != null;

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    final client = _supabase;

    if (client == null) {
      return AuthResult.failure(
        'Authentication service is unavailable. Please check your configuration.',
      );
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      final user = response.user;
      final session = response.session;

      if (user != null) {
        _emitState(
          AuthState(
            status: AuthStatus.authenticated,
            user: user,
            session: session,
            email: user.email,
          ),
        );
        return AuthResult.success(user: user, session: session);
      } else {
        return AuthResult.failure('Authentication failed. Please try again.');
      }
    } catch (e) {
      final message = _mapAuthError(e);
      AppLogger.warning('Sign in error: $message');
      return AuthResult.failure(message);
    }
  }

  @override
  Future<AuthResult> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
  }) async {
    final cleanEmail = email.trim();
    final client = _supabase;

    if (client == null) {
      return AuthResult.failure(
        'Authentication service is unavailable. Please check your configuration.',
      );
    }

    try {
      final data = <String, dynamic>{};
      if (fullName != null && fullName.trim().isNotEmpty) {
        data['full_name'] = fullName.trim();
      }

      final response = await client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: data.isNotEmpty ? data : null,
      );

      final user = response.user;
      final session = response.session;

      // In Supabase, if email confirmation is enabled, session will be null upon signUp
      final bool requiresVerification = session == null && user != null;

      if (requiresVerification) {
        _emitState(
          AuthState(
            status: AuthStatus.verificationRequired,
            user: user,
            email: cleanEmail,
          ),
        );
        return AuthResult.success(user: user, requiresVerification: true);
      }

      if (user != null && session != null) {
        _emitState(
          AuthState(
            status: AuthStatus.authenticated,
            user: user,
            session: session,
            email: cleanEmail,
          ),
        );
        return AuthResult.success(user: user, session: session);
      }

      return AuthResult.failure('Registration failed. Please try again.');
    } catch (e) {
      final message = _mapAuthError(e);
      AppLogger.warning('Sign up error: $message');
      return AuthResult.failure(message);
    }
  }

  @override
  Future<AuthResult> resetPasswordForEmail(
    String email, {
    String? redirectTo,
  }) async {
    final cleanEmail = email.trim();
    final client = _supabase;

    if (client == null) {
      return AuthResult.failure(
        'Authentication service is unavailable. Please check your configuration.',
      );
    }

    try {
      await client.auth.resetPasswordForEmail(
        cleanEmail,
        redirectTo: redirectTo ?? 'nitcbus://auth-callback/reset-password',
      );

      _emitState(
        AuthState(
          status: AuthStatus.passwordRecoverySent,
          email: cleanEmail,
          lastActionTime: DateTime.now(),
        ),
      );

      return AuthResult.success();
    } catch (e) {
      final message = _mapAuthError(e);
      AppLogger.warning('Password reset error: $message');
      return AuthResult.failure(message);
    }
  }

  @override
  Future<AuthResult> updatePassword(String newPassword) async {
    final client = _supabase;

    if (client == null) {
      return AuthResult.failure(
        'Authentication service is unavailable. Please check your configuration.',
      );
    }

    try {
      final response = await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      final user = response.user;
      if (user != null) {
        _emitState(
          AuthState(
            status: AuthStatus.authenticated,
            user: user,
            session: client.auth.currentSession,
            email: user.email,
          ),
        );
        return AuthResult.success(user: user);
      }

      return AuthResult.failure('Failed to update password.');
    } catch (e) {
      final message = _mapAuthError(e);
      AppLogger.warning('Update password error: $message');
      return AuthResult.failure(message);
    }
  }

  @override
  Future<AuthResult> resendVerificationEmail(String email) async {
    final cleanEmail = email.trim();
    final client = _supabase;

    if (client == null) {
      return AuthResult.failure(
        'Authentication service is unavailable. Please check your configuration.',
      );
    }

    try {
      await client.auth.resend(type: OtpType.signup, email: cleanEmail);
      return AuthResult.success();
    } catch (e) {
      final message = _mapAuthError(e);
      AppLogger.warning('Resend verification error: $message');
      return AuthResult.failure(message);
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    final client = _supabase;

    if (client == null) {
      return AuthResult.failure(
        'Authentication service is unavailable. Please check your configuration.',
      );
    }

    try {
      final redirectTo =
          kIsWeb
              ? Uri.base.resolve('/auth/callback').toString()
              : 'nitcbus://auth-callback';
      final success = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );
      if (success) {
        return AuthResult.success();
      }
      return AuthResult.failure('Google sign-in was cancelled or failed.');
    } catch (e) {
      final message = _mapAuthError(e);
      AppLogger.warning('Google sign in error: $message');
      return AuthResult.failure(message);
    }
  }

  @override
  Future<void> signOut() async {
    final client = _supabase;

    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (e) {
        AppLogger.warning('Sign out error: $e');
      }
    }

    _emitState(const AuthState(status: AuthStatus.unauthenticated));
  }

  @override
  void dispose() {
    _supabaseSub?.cancel();
    _stateController.close();
  }

  /// Maps Supabase [AuthException] and network errors to clean user-facing messages.
  String _mapAuthError(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      final statusCode = error.statusCode;

      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid credentials') ||
          msg.contains('invalid username or password')) {
        return 'Incorrect email or password. Please check your credentials and try again.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Your email address has not been confirmed yet. Please check your inbox for the confirmation link.';
      }
      if (msg.contains('user already registered') ||
          msg.contains('already registered') ||
          msg.contains('already exists')) {
        return 'An account with this NITC email already exists. Please sign in instead.';
      }
      if (msg.contains('password should be at least') ||
          msg.contains('weak password')) {
        return 'Password must be at least 6 characters long.';
      }
      if (msg.contains('over_email_send_rate_limit') ||
          msg.contains('rate limit') ||
          statusCode == '429') {
        return 'Too many requests. Please wait a moment before trying again.';
      }
      if (msg.contains('network') || msg.contains('socket')) {
        return 'Network connection issue. Please check your internet connection.';
      }
      return 'Authentication could not be completed. Please try again.';
    }

    final str = error.toString().toLowerCase();
    if (str.contains('socketexception') || str.contains('timeout')) {
      return 'Could not connect to the campus authentication server. Please check your internet connection.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}

/// Riverpod provider for [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final repo = SupabaseAuthRepository(supabase);
  ref.onDispose(repo.dispose);
  return repo;
});
