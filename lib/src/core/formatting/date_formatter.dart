/// Lightweight, locale-independent date formatting for the booking UI.
///
/// The app targets a single presentation style ("Sat, 12 Oct 2026") so a
/// hand-written formatter keeps the dependency surface small and predictable
/// in tests.
library;

const List<String> _monthAbbreviations = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _weekdayAbbreviations = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// Three-letter month name, e.g. `Oct`.
String monthAbbreviation(DateTime date) => _monthAbbreviations[date.month - 1];

/// Three-letter weekday name, e.g. `Sat`.
String weekdayAbbreviation(DateTime date) =>
    _weekdayAbbreviations[date.weekday - 1];

/// `12 Oct`
String formatShortDate(DateTime date) =>
    '${date.day} ${monthAbbreviation(date)}';

/// `12 Oct 2026`
String formatMediumDate(DateTime date) =>
    '${formatShortDate(date)} ${date.year}';

/// `Sat, 12 Oct 2026`
String formatLongDate(DateTime date) =>
    '${weekdayAbbreviation(date)}, ${formatMediumDate(date)}';

/// Compact range such as `12 – 14 Oct` or `30 Sep – 2 Oct`.
///
/// When the two dates fall in different years the year is appended to both
/// sides so the range is never ambiguous.
String formatDateRange(DateTime start, DateTime end) {
  const separator = ' – ';

  if (start.year != end.year) {
    return '${formatMediumDate(start)}$separator${formatMediumDate(end)}';
  }
  if (start.month == end.month) {
    return '${start.day}$separator${end.day} ${monthAbbreviation(start)}';
  }
  return '${formatShortDate(start)}$separator${formatShortDate(end)}';
}

/// `2 nights` / `1 night`.
String formatNights(int nights) =>
    '$nights ${nights == 1 ? 'night' : 'nights'}';

/// `2 guests` / `1 guest`.
String formatGuests(int guests) =>
    '$guests ${guests == 1 ? 'guest' : 'guests'}';
