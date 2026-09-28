import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/features/booking/domain/booking.dart';
import 'package:hotel_booking_app/src/features/booking/domain/guest_details.dart';
import 'package:hotel_booking_app/src/features/hotels/data/sample_hotels.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/stay_quote.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/stay_search.dart';

void main() {
  final today = DateTime(2026, 10, 1);
  final hotel = sampleHotels.first; // sleeps 3
  final guest = GuestDetails.sanitized(
    fullName: 'Priya Sharma',
    email: 'priya@example.com',
    phone: '9876543210',
  );
  final stay = StaySearch.initial(today: today);

  test('a valid request passes', () {
    final request = BookingRequest(hotel: hotel, stay: stay, guest: guest);
    expect(BookingPolicy.check(request, today: today), isNull);
    expect(request.quote, StayQuote.forStay(hotel, stay));
  });

  test('invalid stays are rejected with the stay message', () {
    final request = BookingRequest(
      hotel: hotel,
      stay: stay.copyWith(
        checkIn: DateTime(2026, 9, 1),
        checkOut: DateTime(2026, 9, 3),
      ),
      guest: guest,
    );
    final error = BookingPolicy.check(request, today: today);
    expect(error?.error, BookingError.invalidStay);
    expect(error?.message, StaySearchError.checkInInPast.message);
  });

  test('parties larger than the hotel allows are rejected', () {
    final request = BookingRequest(
      hotel: hotel,
      stay: stay.withGuests(4),
      guest: guest,
    );
    final error = BookingPolicy.check(request, today: today);
    expect(error?.error, BookingError.partyTooLarge);
    expect(error?.message, contains('3 guests'));
  });

  test('guest details are re-validated by the domain', () {
    final bad = GuestDetails.sanitized(
      fullName: 'P',
      email: 'priya@example.com',
      phone: '9876543210',
    );
    final request = BookingRequest(hotel: hotel, stay: stay, guest: bad);
    expect(
      BookingPolicy.check(request, today: today)?.error,
      BookingError.invalidGuestDetails,
    );
  });

  test('staysOverlap is exclusive of the check-out day', () {
    final a = StaySearch(
      destination: '',
      checkIn: DateTime(2026, 10, 3),
      checkOut: DateTime(2026, 10, 5),
      guests: 1,
    );
    final b = StaySearch(
      destination: '',
      checkIn: DateTime(2026, 10, 5),
      checkOut: DateTime(2026, 10, 7),
      guests: 1,
    );
    final c = StaySearch(
      destination: '',
      checkIn: DateTime(2026, 10, 4),
      checkOut: DateTime(2026, 10, 6),
      guests: 1,
    );
    expect(BookingPolicy.staysOverlap(a, b), isFalse);
    expect(BookingPolicy.staysOverlap(a, c), isTrue);
    expect(BookingPolicy.staysOverlap(c, a), isTrue);
  });

  test('Booking helpers', () {
    final booking = Booking(
      confirmationCode: 'HB-AAAA-BBBB',
      hotel: hotel,
      stay: stay,
      guest: guest,
      quote: StayQuote.forStay(hotel, stay),
      createdAt: today,
    );
    expect(booking.isConfirmed, isTrue);
    expect(booking.isUpcoming(today: today), isTrue);
    expect(booking.canCancel(today: today), isTrue);
    expect(booking.canCancel(today: stay.checkIn), isFalse);
    expect(
      booking.isUpcoming(today: stay.checkOut.add(const Duration(days: 1))),
      isFalse,
    );

    final cancelled = booking.copyWith(status: BookingStatus.cancelled);
    expect(cancelled.isCancelled, isTrue);
    expect(cancelled.isUpcoming(today: today), isFalse);
    expect(cancelled, isNot(booking));
    expect(cancelled.toString(), contains('cancelled'));
    expect(
      const BookingException(BookingError.notFound, 'x').toString(),
      contains('notFound'),
    );
  });
}
