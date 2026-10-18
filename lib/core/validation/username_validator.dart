/// Result of validating a username against Tracklet rules.
class UsernameValidationResult {
  const UsernameValidationResult({required this.isValid, this.errorMessage});

  final bool isValid;
  final String? errorMessage;

  static const valid = UsernameValidationResult(isValid: true);
}

/// Centralized validator for Tracklet usernames.
///
/// Baseline format requirements:
/// - Length: 3–20 characters.
/// - Allowed characters: ASCII letters, digits, and underscores.
/// - First character must be a letter.
/// - No spaces.
/// - Cannot start or end with an underscore.
/// - Canonical form is trimmed lowercase.
class UsernameValidator {
  UsernameValidator._();

  static const int minLength = 3;
  static const int maxLength = 20;

  static final RegExp _allowedCharactersRegex = RegExp(r'^[a-zA-Z0-9_]+$');
  static final RegExp _startsWithLetterRegex = RegExp(r'^[a-zA-Z]');

  /// Cleans and canonicalizes a username to lowercase.
  static String canonicalize(String value) => value.trim().toLowerCase();

  /// Validates a username string and returns a detailed [UsernameValidationResult].
  static UsernameValidationResult validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const UsernameValidationResult(
        isValid: false,
        errorMessage: 'Username is required.',
      );
    }

    final trimmed = value.trim();

    if (trimmed.contains(' ')) {
      return const UsernameValidationResult(
        isValid: false,
        errorMessage: 'Username cannot contain spaces.',
      );
    }

    if (trimmed.length < minLength || trimmed.length > maxLength) {
      return const UsernameValidationResult(
        isValid: false,
        errorMessage: 'Username must be between 3 and 20 characters.',
      );
    }

    if (!_startsWithLetterRegex.hasMatch(trimmed)) {
      return const UsernameValidationResult(
        isValid: false,
        errorMessage: 'Username must start with a letter.',
      );
    }

    if (trimmed.startsWith('_') || trimmed.endsWith('_')) {
      return const UsernameValidationResult(
        isValid: false,
        errorMessage: 'Username cannot start or end with an underscore.',
      );
    }

    if (!_allowedCharactersRegex.hasMatch(trimmed)) {
      return const UsernameValidationResult(
        isValid: false,
        errorMessage:
            'Username can only contain letters, numbers, and underscores.',
      );
    }

    return UsernameValidationResult.valid;
  }
}
