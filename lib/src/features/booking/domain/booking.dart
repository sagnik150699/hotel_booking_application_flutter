import 'package:flutter/foundation.dart';

import '../../../core/dates/date_only.dart';
import '../../hotels/domain/hotel.dart';
import '../../hotels/domain/stay_quote.dart';
import '../../hotels/domain/stay_search.dart';
import 'guest_details.dart';

enum BookingStatus {
  confirmed('Confirmed'),
  cancelled('Cancelled');

  const BookingStatus(this.label);

  final String label;
}

/// Why a booking could not be created or changed.
enum BookingError {
  invalidStay,
  partyTooLarge,
  invalidGuestDetails,
  overlappingBooking,
  notFound,
  alreadyCancelled,
}

/// Thrown by the booking repository and policy. Carries a message that is
/// safe to show to the user.
class BookingException implements Exception {
  const BookingException(this.error, this.message);

  final BookingError error;
  final String message;

  @override
  String toString() => 'BookingException(${error.name}: $message)';
}

/// Everything needed to ask for a reservation.
@immutable
class BookingRequest {
  const BookingRequest({
    required this.hotel,
    required this.stay,
    required this.guest,
  });

  final Hotel hotel;
  final StaySearch stay;
  final GuestDetails guest;

  StayQuote get quote => StayQuote.forStay(hotel, stay);
}

/// Business rules a request must satisfy. Lives in the domain so both the UI
/// (for early feedback) and the repository (as the real gate) apply exactly
/// the same checks.
abstract final class BookingPolicy {
  static BookingException? check(
    BookingRequest request, {
    required DateTime today,
  }) {
    final stayError = request.stay.validate(today: today);
    if (stayError != null) {
      return BookingException(BookingError.invalidStay, stayError.message);
    }
    if (request.stay.guests > request.hotel.maxGuests) {
      final limit = request.hotel.maxGuests;
      return BookingException(
        BookingError.partyTooLarge,
        '${request.hotel.name} sleeps at most $limit '
        '${limit == 1 ? 'guest' : 'guests'}.',
      );
    }
    final guestError = GuestDetailsValidator.firstError(request.guest);
    if (guestError != null) {
      return BookingException(BookingError.invalidGuestDetails, guestError);
    }
    return null;
  }

  /// `true` when two stays at the same property share at least one night.
  static bool staysOverlap(StaySearch a, StaySearch b) =>
      a.checkIn.isBefore(b.checkOut) && b.checkIn.isBefore(a.checkOut);
}

/// A confirmed (or later cancelled) reservation.
@immutable
class Booking {
  const Booking({
    required this.confirmationCode,
    required this.hotel,
    required this.stay,
    required this.guest,
    required this.quote,
    required this.createdAt,
    this.status = BookingStatus.confirmed,
  });

  final String confirmationCode;
  final Hotel hotel;
  final StaySearch stay;
  final GuestDetails guest;
  final StayQuote quote;
  final DateTime createdAt;
  final BookingStatus status;

  bool get isCancelled => status == BookingStatus.cancelled;

  bool get isConfirmed => status == BookingStatus.confirmed;

  /// Confirmed and the stay has not yet ended.
  bool isUpcoming({required DateTime today}) =>
      isConfirmed && !stay.checkOut.isBefore(dateOnly(today));

  /// Cancellation is free until the day before check-in.
  bool canCancel({required DateTime today}) =>
      isConfirmed && stay.checkIn.isAfter(dateOnly(today));

  Booking copyWith({BookingStatus? status}) => Booking(
    confirmationCode: confirmationCode,
    hotel: hotel,
    stay: stay,
    guest: guest,
    quote: quote,
    createdAt: createdAt,
    status: status ?? this.status,
  );

  @override
  bool operator ==(Object other) =>
      other is Booking &&
      other.confirmationCode == confirmationCode &&
      other.status == status;

  @override
  int get hashCode => Object.hash(confirmationCode, status);

  @override
  String toString() =>
      'Booking($confirmationCode, ${hotel.name}, ${status.name})';
}
