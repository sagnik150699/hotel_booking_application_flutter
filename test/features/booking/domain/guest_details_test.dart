import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/features/booking/domain/guest_details.dart';

void main() {
  group('GuestDetailsValidator.fullName', () {
    test('accepts realistic names in any script', () {
      for (final name in <String>[
        'Priya Sharma',
        "Zoë O'Brien-Müller",
        'प्रिया शर्मा',
        'Jean-Luc Picard',
        'A. R. Rahman',
      ]) {
        expect(GuestDetailsValidator.fullName(name), isNull, reason: name);
      }
    });

    test('rejects empty, short, long and unsafe values', () {
      expect(GuestDetailsValidator.fullName(null), isNotNull);
      expect(GuestDetailsValidator.fullName('   '), isNotNull);
      expect(GuestDetailsValidator.fullName('A'), isNotNull);
      expect(GuestDetailsValidator.fullName('a' * 61), isNotNull);
      expect(
        GuestDetailsValidator.fullName('<script>alert(1)</script>'),
        isNotNull,
      );
      expect(
        GuestDetailsValidator.fullName('Robert; DROP TABLE guests'),
        isNotNull,
      );
      expect(GuestDetailsValidator.fullName('1234'), isNotNull);
      expect(GuestDetailsValidator.fullName('-Dash'), isNotNull);
    });
  });

  group('GuestDetailsValidator.email', () {
    test('accepts well-formed addresses', () {
      for (final email in <String>[
        'priya@example.com',
        'first.last+tag@sub.example.co.in',
        'x@y.io',
      ]) {
        expect(GuestDetailsValidator.email(email), isNull, reason: email);
      }
    });

    test('rejects malformed addresses', () {
      for (final email in <String>[
        '',
        'plainaddress',
        '@example.com',
        'priya@',
        'priya@localhost',
        'priya @example.com',
        'priya@exa mple.com',
        'priya@example..com',
        '${'a' * 250}@example.com',
      ]) {
        expect(GuestDetailsValidator.email(email), isNotNull, reason: email);
      }
    });
  });

  group('GuestDetailsValidator.phone', () {
    test('accepts local and international formats', () {
      for (final phone in <String>[
        '9876543210',
        '+91 98765 43210',
        '+1 (415) 555-2671',
        '020-1234-5678',
      ]) {
        expect(GuestDetailsValidator.phone(phone), isNull, reason: phone);
      }
    });

    test('rejects letters, too few or too many digits', () {
      expect(GuestDetailsValidator.phone(''), isNotNull);
      expect(GuestDetailsValidator.phone('call me'), isNotNull);
      expect(GuestDetailsValidator.phone('1234567'), isNotNull);
      expect(GuestDetailsValidator.phone('1234567890123456'), isNotNull);
      expect(GuestDetailsValidator.phone('98765+43210'), isNotNull);
    });

    test('normalizePhone keeps digits and a leading plus only', () {
      expect(
        GuestDetailsValidator.normalizePhone('+91 (98765) 43-210'),
        '+919876543210',
      );
      expect(
        GuestDetailsValidator.normalizePhone('020 1234 5678'),
        '02012345678',
      );
    });
  });

  group('GuestDetails.sanitized', () {
    test('cleans every field and never leaks data through toString', () {
      final zeroWidth = String.fromCharCode(0x200B);
      final details = GuestDetails.sanitized(
        fullName: '  Priya$zeroWidth   Sharma ',
        email: ' Priya@Example.COM ',
        phone: '+91 98765-43210',
      );
      expect(details.fullName, 'Priya Sharma');
      expect(details.email, 'priya@example.com');
      expect(details.phone, '+919876543210');
      expect(details.firstName, 'Priya');
      expect(details.maskedEmail, 'p***a@example.com');
      expect(details.toString(), isNot(contains('Priya')));
      expect(details.toString(), isNot(contains('example')));
      expect(GuestDetailsValidator.isValid(details), isTrue);
    });

    test('maskedEmail handles short local parts', () {
      expect(
        GuestDetails.sanitized(
          fullName: 'A B',
          email: 'ab@x.io',
          phone: '12345678',
        ).maskedEmail,
        'a*@x.io',
      );
      expect(
        GuestDetails.sanitized(
          fullName: 'A B',
          email: 'a@x.io',
          phone: '12345678',
        ).maskedEmail,
        'a@x.io',
      );
    });

    test('firstError reports the first invalid field', () {
      final bad = GuestDetails.sanitized(
        fullName: 'Priya Sharma',
        email: 'nope',
        phone: '12345678',
      );
      expect(GuestDetailsValidator.firstError(bad), contains('e-mail'));
      final good = GuestDetails.sanitized(
        fullName: 'Priya Sharma',
        email: 'p@x.io',
        phone: '12345678',
      );
      expect(GuestDetailsValidator.firstError(good), isNull);
      expect(
        good,
        GuestDetails.sanitized(
          fullName: 'Priya Sharma',
          email: 'p@x.io',
          phone: '12345678',
        ),
      );
    });
  });
}
