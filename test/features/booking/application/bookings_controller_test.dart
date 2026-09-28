import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/core/load_status.dart';
import 'package:hotel_booking_app/src/features/booking/application/bookings_controller.dart';
import 'package:hotel_booking_app/src/features/booking/data/booking_repository.dart';
import 'package:hotel_booking_app/src/features/booking/domain/booking.dart';
import 'package:hotel_booking_app/src/features/booking/domain/guest_details.dart';
import 'package:hotel_booking_app/src/features/hotels/data/sample_hotels.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/stay_search.dart';

import '../../../helpers/pump_app.dart';

void main() {
  final guest = GuestDetails.sanitized(
    fullName: 'Priya Sharma',
    email: 'priya@example.com',
    phone: '9876543210',
  );
  final stay = StaySearch.initial(today: testToday);

  late BookingsController controller;

  setUp(() {
    controller = BookingsController(
      repository: InMemoryBookingRepository(
        latency: Duration.zero,
        clock: testClock,
      ),
      clock: testClock,
    );
  });

  tearDown(() => controller.dispose());

  test('load starts empty', () async {
    await controller.load();
    expect(controller.status, LoadStatus.ready);
    expect(controller.isEmpty, isTrue);
    expect(controller.upcoming, isEmpty);
  });

  test(
    'book adds to upcoming, sorted by check-in, and clears submitting',
    () async {
      await controller.load();
      final states = <bool>[];
      controller.addListener(() => states.add(controller.isSubmitting));

      final later = await controller.book(
        BookingRequest(
          hotel: sampleHotels[1],
          stay: stay.copyWith(
            checkIn: DateTime(2026, 11, 1),
            checkOut: DateTime(2026, 11, 3),
          ),
          guest: guest,
        ),
      );
      final sooner = await controller.book(
        BookingRequest(hotel: sampleHotels[0], stay: stay, guest: guest),
      );

      expect(controller.upcoming, <Booking>[sooner, later]);
      expect(controller.history, isEmpty);
      expect(states, <bool>[true, false, true, false]);
      expect(controller.byCode(sooner.confirmationCode), sooner);
      expect(controller.byCode('nope'), isNull);
    },
  );

  test('book rethrows policy violations and resets submitting', () async {
    await controller.load();
    await expectLater(
      controller.book(
        BookingRequest(
          hotel: sampleHotels[0],
          stay: stay.withGuests(8),
          guest: guest,
        ),
      ),
      throwsA(isA<BookingException>()),
    );
    expect(controller.isSubmitting, isFalse);
    expect(controller.isEmpty, isTrue);
  });

  test(
    'cancel moves the booking to history and tracks the in-flight code',
    () async {
      await controller.load();
      final booking = await controller.book(
        BookingRequest(hotel: sampleHotels[0], stay: stay, guest: guest),
      );
      final codes = <String?>[];
      controller.addListener(() => codes.add(controller.cancellingCode));

      final cancelled = await controller.cancel(booking.confirmationCode);
      expect(cancelled.isCancelled, isTrue);
      expect(controller.upcoming, isEmpty);
      expect(controller.history.single.isCancelled, isTrue);
      expect(codes, <String?>[booking.confirmationCode, null]);
    },
  );
}
