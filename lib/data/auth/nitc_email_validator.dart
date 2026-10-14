/// Validates whether an email address strictly belongs to the '@nitc.ac.in' domain.
/// Normalizes case and whitespace, ensures exactly one '@' character,
/// non-empty local-part, and exact match on the 'nitc.ac.in' domain part.
bool isNitcEmail(String? value) {
  final email = value?.trim().toLowerCase() ?? '';
  if (email.isEmpty) return false;

  final parts = email.split('@');
  if (parts.length != 2) return false;
  if (parts[0].isEmpty) return false;

  return parts[1] == 'nitc.ac.in';
}
