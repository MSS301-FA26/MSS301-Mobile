import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/auth/presentation/widgets/registration_validation.dart';

void main() {
  test('name follows Web nonblank and 100 character rules', () {
    expect(RegistrationValidation.name(' A '), isNull);
    expect(RegistrationValidation.name(' '), isNotNull);
    expect(
      RegistrationValidation.name(List.filled(101, 'a').join()),
      isNotNull,
    );
  });
  test('phone follows the existing Web Vietnamese phone rule', () {
    for (final phone in [
      '0312345678',
      '0512345678',
      '0812345678',
      '0912345678',
    ]) {
      expect(RegistrationValidation.phone(phone), isNull);
    }
    for (final phone in [
      '',
      '0712345678',
      '091234567',
      '+84912345678',
      '09123a5678',
    ]) {
      expect(RegistrationValidation.phone(phone), isNotNull);
    }
  });
  test('username is explicit, nonblank, whitespace free and at most 255', () {
    expect(RegistrationValidation.username(' customer '), isNull);
    for (final username in [
      '',
      'customer name',
      'user\tname',
      List.filled(256, 'x').join(),
    ]) {
      expect(RegistrationValidation.username(username), isNotNull);
    }
  });
  test(
    'citizen identity accepts only 9 or 12 digits including leading zeros',
    () {
      expect(RegistrationValidation.identity('001234567'), isNull);
      expect(RegistrationValidation.identity('012345678901'), isNull);
      for (final identity in [
        '',
        '12345678',
        '1234567890',
        '1234567890123',
        '01234567890A',
      ]) {
        expect(RegistrationValidation.identity(identity), isNotNull);
      }
    },
  );
  test('password validates the raw value against Backend strength', () {
    expect(RegistrationValidation.password('Password1!'), isNull);
    expect(RegistrationValidation.password('Password1 '), isNull);
    for (final password in [
      '',
      'Aa1!',
      'password1!',
      'PASSWORD1!',
      'Password!!',
      'Password11',
    ]) {
      expect(RegistrationValidation.password(password), isNotNull);
    }
  });
  test('confirmation must match raw password, not its trimmed value', () {
    expect(
      RegistrationValidation.confirm(' Password1! ', ' Password1! '),
      isNull,
    );
    expect(
      RegistrationValidation.confirm('Password1!', ' Password1! '),
      isNotNull,
    );
    expect(RegistrationValidation.confirm('', ''), isNotNull);
  });
  test('email rejects blank, whitespace and malformed at signs without case mutation', () {
    expect(RegistrationValidation.email(' Customer@Example.test '), isNull);
    expect(RegistrationValidation.email('customer@localhost'), isNull);
    for (final email in [
      '',
      'invalid',
      '@domain.test',
      'customer@',
      'a@@b.test',
      'a b@test',
    ]) {
      expect(RegistrationValidation.email(email), isNotNull);
    }
  });
}
