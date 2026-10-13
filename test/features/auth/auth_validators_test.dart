import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/auth/auth_validators.dart';

void main() {
  group('auth validators', () {
    test('accepts only the exact NITC domain for registration', () {
      expect(validateNitcEmail('student@nitc.ac.in'), isNull);
      expect(validateNitcEmail('student@NITC.AC.IN'), isNull);
      expect(validateNitcEmail('student@nitc.ac.in.example.com'), isNotNull);
      expect(validateNitcEmail('student@notnitc.ac.in'), isNotNull);
    });

    test('distinguishes empty and matching password confirmation', () {
      expect(
        validatePasswordConfirmation('', 'secret'),
        'Confirm your password.',
      );
      expect(validatePasswordConfirmation('secret', 'secret'), isNull);
      expect(
        validatePasswordConfirmation('different', 'secret'),
        'Passwords do not match.',
      );
    });
  });
}
