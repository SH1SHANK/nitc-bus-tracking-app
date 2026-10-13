String? validateNitcEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email address.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Enter a valid email address.';
  }
  if (email.toLowerCase().split('@').last != 'nitc.ac.in') {
    return 'Use your NITC institute email ending in @nitc.ac.in.';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Enter a password.';
  if (value.length < 6) return 'Password must be at least 6 characters.';
  return null;
}

String? validatePasswordConfirmation(String? value, String password) {
  if (value == null || value.isEmpty) return 'Confirm your password.';
  if (value != password) return 'Passwords do not match.';
  return null;
}
