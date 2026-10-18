import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../core/logging/app_logger.dart';
import 'nitc_email_validator.dart';
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
  Future<AuthResult> signInWithEmail(
    String email,
    String password, {
    String? captchaToken,
  });

  /// Register a new student account.
  Future<AuthResult> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
    String? captchaToken,
  });

  /// Request a password recovery email.
  Future<AuthResult> resetPasswordForEmail(
    String email, {
    String? redirectTo,
    String? captchaToken,
  });

  /// Update password for the currently authenticated recovery or active session.
  Future<AuthResult> updatePassword(String newPassword);

  /// Resend confirmation / verification email.
  Future<AuthResult> resendVerificationEmail(
    String email, {
    String? captchaToken,
  });

  /// Sign in using Google OAuth.
  Future<AuthResult> signInWithGoogle();

  /// Sign in anonymously as a guest.
  Future<AuthResult> signInAnonymously({String? captchaToken});

  /// Sign out the current user session and invalidate tokens.
  Future<void> signOut();

  /// Permanently delete the currently authenticated user account and associated profile data.
  Future<void> deleteAccount();

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
        if (!currentUser.isAnonymous && !isNitcEmail(currentUser.email)) {
          AppLogger.warning(
            'Active session rejected for unauthorized email: ${currentUser.email}',
          );
          unawaited(client.auth.signOut());
          _emitState(
            const AuthState(
              status: AuthStatus.unauthenticated,
              errorMessage:
                  'Please sign in using your @nitc.ac.in institute email address.',
            ),
          );
        } else {
          _emitState(
            AuthState(
              status: AuthStatus.authenticated,
              user: currentUser,
              session: currentSession,
              email: currentUser.email,
            ),
          );
        }
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
              if (user != null &&
                  !user.isAnonymous &&
                  !isNitcEmail(user.email)) {
                AppLogger.warning(
                  'Signed-in user rejected for unauthorized email: ${user.email}',
                );
                unawaited(client.auth.signOut());
                _emitState(
                  const AuthState(
                    status: AuthStatus.unauthenticated,
                    errorMessage:
                        'Please sign in using your @nitc.ac.in institute email address.',
                  ),
                );
                break;
              }
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
                if (!user.isAnonymous && !isNitcEmail(user.email)) {
                  AppLogger.warning(
                    'Token refresh/update rejected for unauthorized email: ${user.email}',
                  );
                  unawaited(client.auth.signOut());
                  _emitState(
                    const AuthState(
                      status: AuthStatus.unauthenticated,
                      errorMessage:
                          'Please sign in using your @nitc.ac.in institute email address.',
                    ),
                  );
                  break;
                }
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
            case AuthChangeEvent.initialSession:
              if (user != null) {
                if (!user.isAnonymous && !isNitcEmail(user.email)) {
                  AppLogger.warning(
                    'Initial session rejected for unauthorized email: ${user.email}',
                  );
                  unawaited(client.auth.signOut());
                  _emitState(
                    const AuthState(
                      status: AuthStatus.unauthenticated,
                      errorMessage:
                          'Please sign in using your @nitc.ac.in institute email address.',
                    ),
                  );
                } else {
                  _emitState(
                    AuthState(
                      status: AuthStatus.authenticated,
                      user: user,
                      session: session,
                      email: user.email,
                    ),
                  );
                }
              } else {
                _emitState(const AuthState(status: AuthStatus.unauthenticated));
              }
              break;
            case AuthChangeEvent.mfaChallengeVerified:
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
  Future<AuthResult> signInWithEmail(
    String email,
    String password, {
    String? captchaToken,
  }) async {
    final cleanEmail = email.trim();
    if (!isNitcEmail(cleanEmail)) {
      return AuthResult.failure(
        'Please sign in using your @nitc.ac.in institute email address.',
      );
    }
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
        captchaToken: captchaToken,
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
    String? captchaToken,
  }) async {
    final cleanEmail = email.trim();
    if (!isNitcEmail(cleanEmail)) {
      return AuthResult.failure(
        'Please sign in using your @nitc.ac.in institute email address.',
      );
    }
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
        captchaToken: captchaToken,
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
    String? captchaToken,
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
        captchaToken: captchaToken,
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
  Future<AuthResult> resendVerificationEmail(
    String email, {
    String? captchaToken,
  }) async {
    final cleanEmail = email.trim();
    final client = _supabase;

    if (client == null) {
      return AuthResult.failure(
        'Authentication service is unavailable. Please check your configuration.',
      );
    }

    try {
      await client.auth.resend(
        type: OtpType.signup,
        email: cleanEmail,
        captchaToken: captchaToken,
      );
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
        queryParams: const {'hd': 'nitc.ac.in'},
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
  Future<AuthResult> signInAnonymously({String? captchaToken}) async {
    final client = _supabase;

    if (client == null) {
      return AuthResult.failure(
        'Authentication service is unavailable. Please check your configuration.',
      );
    }

    try {
      final response = await client.auth.signInAnonymously(
        captchaToken: captchaToken,
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
      }

      return AuthResult.failure('Failed to initialize guest session.');
    } catch (e) {
      final message = _mapAuthError(e);
      AppLogger.warning('Guest sign in error: $message');
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
  Future<void> deleteAccount() async {
    final client = _supabase;
    if (client != null && client.auth.currentUser != null) {
      final user = client.auth.currentUser!;
      if (!user.isAnonymous) {
        try {
          await client.rpc<dynamic>('delete_user_account');
        } catch (e) {
          AppLogger.error('Error invoking delete_user_account RPC: $e');
          rethrow;
        }
      }
      await signOut();
    }
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

      if (msg.contains('nitc.ac.in') ||
          msg.contains('institute email') ||
          msg.contains('signups from this email domain') ||
          msg.contains('signups are restricted') ||
          msg.contains('access restricted') ||
          msg.contains('domain')) {
        return 'Please sign in using your @nitc.ac.in institute email address.';
      }
      if (msg.contains('google account email is not verified') ||
          msg.contains('email is not verified')) {
        return 'Google account email is not verified.';
      }
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
      if (msg.contains('captcha')) {
        return 'CAPTCHA verification challenge failed or required. Please complete the verification challenge and try again.';
      }
      if (msg.contains('anonymous sign-ins are disabled') ||
          msg.contains('anonymous sign-in is disabled') ||
          msg.contains('anonymous_provider_disabled')) {
        return 'Guest sign-in is currently disabled. Please sign in with your NITC account.';
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
    if (str.contains('nitc.ac.in') ||
        str.contains('institute email') ||
        str.contains('signups are restricted') ||
        str.contains('access restricted') ||
        str.contains('domain')) {
      return 'Please sign in using your @nitc.ac.in institute email address.';
    }
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
