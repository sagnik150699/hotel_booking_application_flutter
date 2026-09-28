import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/stay_search.dart';

void main() {
  final today = DateTime(2026, 10, 1);

  group('StaySearch', () {
    test('initial search is two nights from the day after tomorrow', () {
      final stay = StaySearch.initial(today: today);
      expect(stay.destination, isEmpty);
      expect(stay.checkIn, DateTime(2026, 10, 3));
      expect(stay.checkOut, DateTime(2026, 10, 5));
      expect(stay.nights, 2);
      expect(stay.guests, 2);
      expect(stay.validate(today: today), isNull);
    });

    test('normalises dates to midnight and trims the destination', () {
      final stay = StaySearch(
        destination: '  Goa ',
        checkIn: DateTime(2026, 10, 3, 14),
        checkOut: DateTime(2026, 10, 5, 9),
        guests: 2,
      );
      expect(stay.destination, 'Goa');
      expect(stay.checkIn, DateTime(2026, 10, 3));
      expect(stay.nights, 2);
      expect(stay.hasDestination, isTrue);
    });

    test('validation catches every rule', () {
      final base = StaySearch.initial(today: today);
      expect(
        base.copyWith(checkIn: DateTime(2026, 9, 30)).validate(today: today),
        StaySearchError.checkInInPast,
      );
      expect(
        base.copyWith(checkOut: base.checkIn).validate(today: today),
        StaySearchError.checkOutNotAfterCheckIn,
      );
      expect(
        base
            .copyWith(checkOut: base.checkIn.add(const Duration(days: 31)))
            .validate(today: today),
        StaySearchError.stayTooLong,
      );
      expect(
        base.copyWith(guests: 0).validate(today: today),
        StaySearchError.tooFewGuests,
      );
      expect(
        base.copyWith(guests: 9).validate(today: today),
        StaySearchError.tooManyGuests,
      );
      expect(StaySearchError.stayTooLong.message, contains('30'));
    });

    test('withDates keeps check-out after check-in', () {
      final stay = StaySearch.initial(
        today: today,
      ).withDates(DateTime(2026, 10, 10), DateTime(2026, 10, 10));
      expect(stay.checkIn, DateTime(2026, 10, 10));
      expect(stay.checkOut, DateTime(2026, 10, 11));
    });

    test('withGuests clamps to the supported range', () {
      final stay = StaySearch.initial(today: today);
      expect(stay.withGuests(0).guests, StaySearch.minGuests);
      expect(stay.withGuests(50).guests, StaySearch.maxGuests);
      expect(stay.withGuests(4).guests, 4);
    });

    test('value equality', () {
      final a = StaySearch.initial(today: today);
      final b = StaySearch.initial(today: today);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.copyWith(guests: 3), isNot(b));
    });
  });
}
