import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/core/formatting/currency_formatter.dart';

void main() {
  group('formatInr', () {
    test('leaves amounts under a thousand ungrouped', () {
      expect(formatInr(0), '₹0');
      expect(formatInr(950), '₹950');
    });

    test('groups the last three digits then pairs', () {
      expect(formatInr(6400), '₹6,400');
      expect(formatInr(12345), '₹12,345');
      expect(formatInr(123456), '₹1,23,456');
      expect(formatInr(1234567), '₹12,34,567');
      expect(formatInr(123456789), '₹12,34,56,789');
    });

    test('handles negatives and custom symbols', () {
      expect(formatInr(-1200), '-₹1,200');
      expect(formatInr(1200, symbol: 'INR '), 'INR 1,200');
    });
  });

  test('groupIndianDigits ignores non-numeric input', () {
    expect(groupIndianDigits('12a4'), '12a4');
    expect(groupIndianDigits(''), '');
  });
}
