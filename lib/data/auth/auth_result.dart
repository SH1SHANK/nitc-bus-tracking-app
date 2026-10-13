import 'package:supabase_flutter/supabase_flutter.dart';

/// Result envelope for authentication operations.
class AuthResult {
  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.session,
    this.errorMessage,
    this.requiresVerification = false,
  });

  factory AuthResult.success({
    User? user,
    Session? session,
    bool requiresVerification = false,
  }) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      session: session,
      requiresVerification: requiresVerification,
    );
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      requiresVerification: false,
    );
  }

  final bool isSuccess;
  final User? user;
  final Session? session;
  final String? errorMessage;
  final bool requiresVerification;

  bool get isFailure => !isSuccess;
}
