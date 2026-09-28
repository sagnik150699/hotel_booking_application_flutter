import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/features/booking/data/booking_repository.dart';
import 'package:hotel_booking_app/src/features/booking/domain/booking.dart';
import 'package:hotel_booking_app/src/features/booking/domain/confirmation_code.dart';
import 'package:hotel_booking_app/src/features/booking/domain/guest_details.dart';
import 'package:hotel_booking_app/src/features/hotels/data/sample_hotels.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/stay_search.dart';

void main() {
  final today = DateTime(2026, 10, 1, 9, 30);
  final hotel = sampleHotels.first;
  final guest = GuestDetails.sanitized(
    fullName: 'Priya Sharma',
    email: 'priya@example.com',
    phone: '9876543210',
  );
  final stay = StaySearch.initial(today: today);

  InMemoryBookingRepository repository() => InMemoryBookingRepository(
    latency: Duration.zero,
    clock: () => today,
    codeGenerator: ConfirmationCodeGenerator(random: Random(1)),
  );

  test('creates a booking with a valid code and the request quote', () async {
    final repo = repository();
    final booking = await repo.create(
      BookingRequest(hotel: hotel, stay: stay, guest: guest),
    );
    expect(ConfirmationCodeGenerator.isValid(booking.confirmationCode), isTrue);
    expect(booking.quote.total, greaterThan(0));
    expect(booking.createdAt, today);
    expect(booking.status, BookingStatus.confirmed);
    expect(await repo.fetchAll(), <Booking>[booking]);
  });

  test('enforces the booking policy', () async {
    final repo = repository();
    expect(
      () => repo.create(
        BookingRequest(hotel: hotel, stay: stay.withGuests(8), guest: guest),
      ),
      throwsA(
        isA<BookingException>().having(
          (e) => e.error,
          'error',
          BookingError.partyTooLarge,
        ),
      ),
    );
  });

  test('refuses overlapping stays at the same hotel', () async {
    final repo = repository();
    await repo.create(BookingRequest(hotel: hotel, stay: stay, guest: guest));
    final overlapping = stay.copyWith(
      checkIn: stay.checkIn.add(const Duration(days: 1)),
      checkOut: stay.checkOut.add(const Duration(days: 2)),
    );
    expect(
      () => repo.create(
        BookingRequest(hotel: hotel, stay: overlapping, guest: guest),
      ),
      throwsA(
        isA<BookingException>().having(
          (e) => e.error,
          'error',
          BookingError.overlappingBooking,
        ),
      ),
    );

    // A different hotel on the same dates is fine.
    final other = await repo.create(
      BookingRequest(hotel: sampleHotels[1], stay: stay, guest: guest),
    );
    expect(other.hotel, sampleHotels[1]);

    // Back-to-back stays at the same hotel are fine too.
    final adjacent = stay.copyWith(
      checkIn: stay.checkOut,
      checkOut: stay.checkOut.add(const Duration(days: 2)),
    );
    await repo.create(
      BookingRequest(hotel: hotel, stay: adjacent, guest: guest),
    );
    expect((await repo.fetchAll()).length, 3);
  });

  test('cancel flips status once and rejects unknown codes', () async {
    final repo = repository();
    final booking = await repo.create(
      BookingRequest(hotel: hotel, stay: stay, guest: guest),
    );

    final cancelled = await repo.cancel(booking.confirmationCode);
    expect(cancelled.isCancelled, isTrue);
    expect((await repo.fetchAll()).single.isCancelled, isTrue);

    expect(
      () => repo.cancel(booking.confirmationCode),
      throwsA(
        isA<BookingException>().having(
          (e) => e.error,
          'error',
          BookingError.alreadyCancelled,
        ),
      ),
    );
    expect(
      () => repo.cancel('HB-ZZZZ-ZZZZ'),
      throwsA(
        isA<BookingException>().having(
          (e) => e.error,
          'error',
          BookingError.notFound,
        ),
      ),
    );

    // Cancelled bookings no longer block the dates.
    await repo.create(BookingRequest(hotel: hotel, stay: stay, guest: guest));
  });

  test('fetchAll returns an unmodifiable snapshot', () async {
    final repo = repository();
    final list = await repo.fetchAll();
    expect(list.clear, throwsUnsupportedError);
  });

  test('simulated latency is honoured', () async {
    final repo = InMemoryBookingRepository(
      latency: const Duration(milliseconds: 20),
      clock: () => today,
    );
    final watch = Stopwatch()..start();
    await repo.fetchAll();
    expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(15));
  });
}
