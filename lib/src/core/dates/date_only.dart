/// Helpers for working with calendar dates without a time component.
///
/// Hotel stays are booked per calendar night, so all stay arithmetic in the
/// app happens on midnight-normalised [DateTime] values. Keeping time
/// components out of the domain avoids off-by-one errors around DST changes
/// and time zones when counting nights.
library;

/// Returns [date] with the time component removed (local midnight).
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Returns today's date at local midnight.
DateTime today() => dateOnly(DateTime.now());

/// Returns `true` when [a] and [b] fall on the same calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Number of whole nights between [checkIn] and [checkOut].
///
/// Negative values are clamped to zero so callers never see a negative stay.
int nightsBetween(DateTime checkIn, DateTime checkOut) {
  final nights = dateOnly(checkOut).difference(dateOnly(checkIn)).inDays;
  return nights < 0 ? 0 : nights;
}
