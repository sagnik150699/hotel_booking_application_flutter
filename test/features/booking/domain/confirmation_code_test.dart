import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/features/booking/domain/confirmation_code.dart';

void main() {
  test('codes match the documented shape', () {
    final generator = ConfirmationCodeGenerator();
    for (var i = 0; i < 200; i++) {
      final code = generator.next();
      expect(ConfirmationCodeGenerator.isValid(code), isTrue, reason: code);
      expect(code, isNot(matches(RegExp('[01IO]'))));
    }
  });

  test('is deterministic for a seeded random and varies otherwise', () {
    final a = ConfirmationCodeGenerator(random: Random(42)).next();
    final b = ConfirmationCodeGenerator(random: Random(42)).next();
    expect(a, b);

    final secure = ConfirmationCodeGenerator();
    final codes = <String>{for (var i = 0; i < 100; i++) secure.next()};
    expect(codes.length, 100);
  });

  test('isValid rejects lookalikes and wrong lengths', () {
    expect(ConfirmationCodeGenerator.isValid('HB-7KQ2-M9XT'), isTrue);
    expect(ConfirmationCodeGenerator.isValid('HB-7KQ2-M9X'), isFalse);
    expect(ConfirmationCodeGenerator.isValid('HB-0KQ2-M9XT'), isFalse);
    expect(ConfirmationCodeGenerator.isValid('hb-7kq2-m9xt'), isFalse);
    expect(ConfirmationCodeGenerator.isValid('XX-7KQ2-M9XT'), isFalse);
  });
}
