import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/core/dates/date_only.dart';
import 'package:hotel_booking_app/src/core/formatting/date_formatter.dart';

void main() {
  final oct12 = DateTime(2026, 10, 12, 15, 30);
  final oct14 = DateTime(2026, 10, 14);

  test('short, medium and long formats', () {
    expect(formatShortDate(oct12), '12 Oct');
    expect(formatMediumDate(oct12), '12 Oct 2026');
    expect(formatLongDate(oct12), 'Mon, 12 Oct 2026');
  });

  test('ranges collapse the month when shared', () {
    expect(formatDateRange(oct12, oct14), '12 – 14 Oct');
    expect(
      formatDateRange(DateTime(2026, 9, 30), DateTime(2026, 10, 2)),
      '30 Sep – 2 Oct',
    );
    expect(
      formatDateRange(DateTime(2026, 12, 30), DateTime(2027, 1, 2)),
      '30 Dec 2026 – 2 Jan 2027',
    );
  });

  test('pluralises nights and guests', () {
    expect(formatNights(1), '1 night');
    expect(formatNights(3), '3 nights');
    expect(formatGuests(1), '1 guest');
    expect(formatGuests(2), '2 guests');
  });

  group('date helpers', () {
    test('dateOnly strips the time component', () {
      expect(dateOnly(oct12), DateTime(2026, 10, 12));
    });

    test('nightsBetween counts calendar nights and never goes negative', () {
      expect(nightsBetween(oct12, oct14), 2);
      expect(
        nightsBetween(DateTime(2026, 10, 12, 23), DateTime(2026, 10, 13, 1)),
        1,
      );
      expect(nightsBetween(oct14, oct12), 0);
    });

    test('isSameDay ignores time', () {
      expect(isSameDay(oct12, DateTime(2026, 10, 12, 2)), isTrue);
      expect(isSameDay(oct12, oct14), isFalse);
    });
  });
}
