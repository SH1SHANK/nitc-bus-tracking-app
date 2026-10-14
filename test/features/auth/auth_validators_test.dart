import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/features/auth/auth_validators.dart';

void main() {
  group('isNitcEmail', () {
    test('ALLOW: accepts canonical student email', () {
      expect(isNitcEmail('student@nitc.ac.in'), isTrue);
    });

    test('ALLOW: accepts faculty email', () {
      expect(isNitcEmail('faculty@nitc.ac.in'), isTrue);
    });

    test(
      'ALLOW: normalizes uppercase email for case-insensitive comparison',
      () {
        expect(isNitcEmail('Student@NITC.AC.IN'), isTrue);
        expect(isNitcEmail('FACULTY@NITC.AC.IN'), isTrue);
        expect(isNitcEmail('Dean_Acad@nitc.ac.in'), isTrue);
      },
    );

    test('ALLOW: trims surrounding whitespace', () {
      expect(isNitcEmail('   student@nitc.ac.in   '), isTrue);
    });

    test('REJECT: rejects public email domains like gmail.com', () {
      expect(isNitcEmail('user@gmail.com'), isFalse);
      expect(isNitcEmail('shashankmergu@gmail.com'), isFalse);
    });

    test('REJECT: rejects prefix spoofing like fake-nitc.ac.in', () {
      expect(isNitcEmail('user@fake-nitc.ac.in'), isFalse);
      expect(isNitcEmail('attacker@evil-nitc.ac.in'), isFalse);
    });

    test('REJECT: rejects suffix spoofing like nitc.ac.in.example.com', () {
      expect(isNitcEmail('user@nitc.ac.in.example.com'), isFalse);
      expect(isNitcEmail('user@nitc.ac.in.attacker.org'), isFalse);
    });

    test('REJECT: rejects subdomains like user@sub.nitc.ac.in', () {
      expect(isNitcEmail('user@sub.nitc.ac.in'), isFalse);
      expect(isNitcEmail('user@cse.nitc.ac.in'), isFalse);
    });

    test('REJECT: rejects missing or empty email', () {
      expect(isNitcEmail(null), isFalse);
      expect(isNitcEmail(''), isFalse);
      expect(isNitcEmail('   '), isFalse);
    });

    test(
      'REJECT: rejects malformed emails with multiple @ or missing local part',
      () {
        expect(isNitcEmail('@nitc.ac.in'), isFalse);
        expect(isNitcEmail('user@@nitc.ac.in'), isFalse);
        expect(isNitcEmail('user@domain@nitc.ac.in'), isFalse);
        expect(isNitcEmail('nitc.ac.in'), isFalse);
      },
    );
  });

  group('validateNitcEmail', () {
    test('returns null for valid NITC emails', () {
      expect(validateNitcEmail('student@nitc.ac.in'), isNull);
      expect(validateNitcEmail('faculty@nitc.ac.in'), isNull);
      expect(validateNitcEmail('Student@NITC.AC.IN'), isNull);
    });

    test('returns clear rejection message for non-NITC domain', () {
      expect(
        validateNitcEmail('user@gmail.com'),
        'Use your NITC institute email ending in @nitc.ac.in.',
      );
      expect(
        validateNitcEmail('user@fake-nitc.ac.in'),
        'Use your NITC institute email ending in @nitc.ac.in.',
      );
      expect(
        validateNitcEmail('user@nitc.ac.in.example.com'),
        'Use your NITC institute email ending in @nitc.ac.in.',
      );
    });

    test('validates empty and malformed emails', () {
      expect(validateNitcEmail(''), 'Enter your email address.');
      expect(validateNitcEmail(null), 'Enter your email address.');
      expect(
        validateNitcEmail('invalid-format'),
        'Enter a valid email address.',
      );
    });
  });

  group('password validators', () {
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

    test('validatePassword checks minimum length', () {
      expect(validatePassword(''), 'Enter a password.');
      expect(
        validatePassword('12345'),
        'Password must be at least 6 characters.',
      );
      expect(validatePassword('123456'), isNull);
    });
  });
}
