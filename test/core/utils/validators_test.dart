import 'package:flutter_test/flutter_test.dart';
import 'package:sellstory/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('isValidIdentity', () {
      test('should return true when identity length is 5 or more', () {
        expect(Validators.isValidIdentity('test@'), true);
        expect(Validators.isValidIdentity('12345'), true);
        expect(Validators.isValidIdentity('valid@email.com'), true);
      });

      test('should return false when identity length is less than 5', () {
        expect(Validators.isValidIdentity(''), false);
        expect(Validators.isValidIdentity('test'), false);
        expect(Validators.isValidIdentity('1234'), false);
      });

      test('should handle whitespace correctly', () {
        expect(Validators.isValidIdentity('  test@  '), true);
        expect(Validators.isValidIdentity('  12345  '), true);
      });
    });

    group('isValidPassword', () {
      test('should return true when password length is 6 or more', () {
        expect(Validators.isValidPassword('123456'), true);
        expect(Validators.isValidPassword('password'), true);
        expect(Validators.isValidPassword('123456789'), true);
      });

      test('should return false when password length is less than 6', () {
        expect(Validators.isValidPassword(''), false);
        expect(Validators.isValidPassword('12345'), false);
        expect(Validators.isValidPassword('pass'), false);
      });
    });

    group('isValidEmail', () {
      test('should return true for valid email formats', () {
        expect(Validators.isValidEmail('test@example.com'), true);
        expect(Validators.isValidEmail('user.name@domain.co.uk'), true);
        expect(Validators.isValidEmail('test123@test.org'), true);
      });

      test('should return false for invalid email formats', () {
        expect(Validators.isValidEmail(''), false);
        expect(Validators.isValidEmail('invalid-email'), false);
        expect(Validators.isValidEmail('test@'), false);
        expect(Validators.isValidEmail('@example.com'), false);
      });
    });

    group('isValidPhone', () {
      test('should return true for valid Thai phone formats', () {
        expect(Validators.isValidPhone('0812345678'), true);
        expect(Validators.isValidPhone('+66812345678'), true);
        expect(Validators.isValidPhone('66812345678'), true);
        expect(Validators.isValidPhone('081 234 5678'), true);
      });

      test('should return false for invalid phone formats', () {
        expect(Validators.isValidPhone(''), false);
        expect(Validators.isValidPhone('123'), false);
        expect(Validators.isValidPhone('123456789'), false); // doesn't start with valid prefix
        expect(Validators.isValidPhone('08123456789'), false); // too long after prefix (10 digits after 0)
        expect(Validators.isValidPhone('081234567890'), false); // too long after prefix (11 digits after 0)
        expect(Validators.isValidPhone('1234567890'), false); // doesn't start with valid prefix
      });
    });

    group('isValidIdentityFormat', () {
      test('should return true for valid email or phone', () {
        expect(Validators.isValidIdentityFormat('test@example.com'), true);
        expect(Validators.isValidIdentityFormat('0812345678'), true);
        expect(Validators.isValidIdentityFormat('+66812345678'), true);
      });

      test('should return false for invalid formats', () {
        expect(Validators.isValidIdentityFormat(''), false);
        expect(Validators.isValidIdentityFormat('invalid'), false);
        expect(Validators.isValidIdentityFormat('123'), false);
      });
    });
  });
}
