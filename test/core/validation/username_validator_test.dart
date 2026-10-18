import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/core/validation/username_validator.dart';

void main() {
  group('UsernameValidator Unit Tests', () {
    test('valid usernames pass validation', () {
      const validNames = [
        'srinand',
        'srinand_ek',
        'srinand123',
        'nitc_rider42',
        'a_b_c',
        'abc',
        'abcdefghijklmnopqrst', // 20 chars
        'john_doe_2026',
      ];

      for (final name in validNames) {
        final result = UsernameValidator.validate(name);
        expect(
          result.isValid,
          isTrue,
          reason:
              'Expected "$name" to be valid, but got: ${result.errorMessage}',
        );
        expect(result.errorMessage, isNull);
      }
    });

    test('rejects empty or null username', () {
      expect(UsernameValidator.validate(null).isValid, isFalse);
      expect(UsernameValidator.validate('').isValid, isFalse);
      expect(UsernameValidator.validate('   ').isValid, isFalse);
    });

    test('rejects usernames that are too short or too long', () {
      expect(UsernameValidator.validate('ab').isValid, isFalse);
      expect(
        UsernameValidator.validate('abcdefghijklmnopqrstu').isValid, // 21 chars
        isFalse,
      );
    });

    test('rejects usernames starting with non-letter', () {
      expect(UsernameValidator.validate('1srinand').isValid, isFalse);
      expect(UsernameValidator.validate('_srinand').isValid, isFalse);
    });

    test('rejects usernames ending with underscore', () {
      expect(UsernameValidator.validate('srinand_').isValid, isFalse);
    });

    test('permits consecutive underscores', () {
      expect(UsernameValidator.validate('srinand__ek').isValid, isTrue);
      expect(UsernameValidator.validate('john___doe').isValid, isTrue);
      expect(UsernameValidator.validate('a__b').isValid, isTrue);
    });

    test('rejects spaces and special characters', () {
      expect(UsernameValidator.validate('srinand ek').isValid, isFalse);
      expect(UsernameValidator.validate('srinand-ek').isValid, isFalse);
      expect(UsernameValidator.validate('srinand.ek').isValid, isFalse);
      expect(UsernameValidator.validate('srinand@ek').isValid, isFalse);
    });

    test('canonicalize trims and lowercases', () {
      expect(UsernameValidator.canonicalize('  Srinand_EK  '), 'srinand_ek');
    });
  });
}
