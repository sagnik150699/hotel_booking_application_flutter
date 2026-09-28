import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/core/validation/input_sanitizer.dart';

void main() {
  group('InputSanitizer.clean', () {
    test('trims and collapses whitespace', () {
      expect(InputSanitizer.clean('  Priya   Sharma \n'), 'Priya Sharma');
    });

    test('strips control and invisible formatting characters', () {
      final zeroWidth = String.fromCharCode(0x200B);
      final bidiOverride = String.fromCharCode(0x202E);
      final bom = String.fromCharCode(0xFEFF);
      final nul = String.fromCharCode(0);
      final input = '${bom}Pri${zeroWidth}ya$bidiOverride Sharma$nul';
      expect(InputSanitizer.clean(input), 'Priya Sharma');
      expect(InputSanitizer.containsDisallowedCharacters(input), isTrue);
      expect(InputSanitizer.containsDisallowedCharacters('Priya'), isFalse);
    });

    test('keeps letters from any script and common punctuation', () {
      expect(InputSanitizer.clean("Zoë O'Brien-Müller"), "Zoë O'Brien-Müller");
      expect(InputSanitizer.clean('प्रिया शर्मा'), 'प्रिया शर्मा');
    });

    test('caps the length without throwing', () {
      final long = 'a' * 500;
      expect(InputSanitizer.clean(long, maxLength: 10).length, 10);
      expect(InputSanitizer.clean('abc def', maxLength: 4), 'abc');
    });
  });
}
