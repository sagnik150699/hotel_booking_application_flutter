import 'package:flutter/foundation.dart';

import '../../../core/dates/date_only.dart';

/// Reasons a [StaySearch] cannot be used for a booking.
enum StaySearchError {
  checkInInPast('Check-in cannot be in the past.'),
  checkOutNotAfterCheckIn('Check-out must be after check-in.'),
  stayTooLong('Stays are limited to ${StaySearch.maxNights} nights.'),
  tooFewGuests('At least one guest is required.'),
  tooManyGuests('Bookings are limited to ${StaySearch.maxGuests} guests.');

  const StaySearchError(this.message);

  /// Copy suitable for showing directly to the user.
  final String message;
}

/// What the traveller is looking for: where, when and for how many people.
///
/// Dates are stored as local midnight values (see `dateOnly`). The object is
/// immutable; use [copyWith] to derive a modified search.
@immutable
class StaySearch {
  StaySearch({
    required String destination,
    required DateTime checkIn,
    required DateTime checkOut,
    required this.guests,
  }) : destination = destination.trim(),
       checkIn = dateOnly(checkIn),
       checkOut = dateOnly(checkOut);

  /// Sensible starting point: an empty destination, a two-night stay starting
  /// the day after tomorrow, for two guests.
  factory StaySearch.initial({DateTime? today}) {
    final base = dateOnly(today ?? DateTime.now());
    return StaySearch(
      destination: '',
      checkIn: base.add(const Duration(days: 2)),
      checkOut: base.add(const Duration(days: 4)),
      guests: 2,
    );
  }

  static const int minGuests = 1;
  static const int maxGuests = 8;
  static const int maxNights = 30;

  /// How far ahead the date pickers allow.
  static const int maxDaysAhead = 365;

  final String destination;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;

  int get nights => nightsBetween(checkIn, checkOut);

  bool get hasDestination => destination.isNotEmpty;

  /// Returns the first problem with this search relative to [today], or `null`
  /// when it is bookable.
  StaySearchError? validate({required DateTime today}) {
    final base = dateOnly(today);
    if (checkIn.isBefore(base)) {
      return StaySearchError.checkInInPast;
    }
    if (!checkOut.isAfter(checkIn)) {
      return StaySearchError.checkOutNotAfterCheckIn;
    }
    if (nights > maxNights) {
      return StaySearchError.stayTooLong;
    }
    if (guests < minGuests) {
      return StaySearchError.tooFewGuests;
    }
    if (guests > maxGuests) {
      return StaySearchError.tooManyGuests;
    }
    return null;
  }

  bool isValid({required DateTime today}) => validate(today: today) == null;

  StaySearch copyWith({
    String? destination,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
  }) {
    return StaySearch(
      destination: destination ?? this.destination,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guests: guests ?? this.guests,
    );
  }

  /// Returns a copy with new dates, nudging check-out forward when it would
  /// otherwise land on or before check-in.
  StaySearch withDates(DateTime newCheckIn, DateTime newCheckOut) {
    final start = dateOnly(newCheckIn);
    var end = dateOnly(newCheckOut);
    if (!end.isAfter(start)) {
      end = start.add(const Duration(days: 1));
    }
    return copyWith(checkIn: start, checkOut: end);
  }

  /// Returns a copy with [guests] clamped to the supported range.
  StaySearch withGuests(int count) =>
      copyWith(guests: count.clamp(minGuests, maxGuests).toInt());

  @override
  bool operator ==(Object other) =>
      other is StaySearch &&
      other.destination == destination &&
      other.checkIn == checkIn &&
      other.checkOut == checkOut &&
      other.guests == guests;

  @override
  int get hashCode => Object.hash(destination, checkIn, checkOut, guests);

  @override
  String toString() =>
      'StaySearch($destination, $checkIn → $checkOut, $guests guests)';
}
