import '../../../core/dates/date_only.dart';
import '../domain/booking.dart';
import '../domain/confirmation_code.dart';

/// Persistence boundary for reservations.
abstract interface class BookingRepository {
  Future<List<Booking>> fetchAll();

  /// Creates a booking or throws a [BookingException].
  Future<Booking> create(BookingRequest request);

  /// Cancels the booking with [confirmationCode] or throws a
  /// [BookingException].
  Future<Booking> cancel(String confirmationCode);
}

/// Keeps bookings in memory for the lifetime of the app.
///
/// Enforces [BookingPolicy] on every write and refuses overlapping stays at
/// the same property, mirroring what a real backend would do. [clock] is
/// injectable so tests can pin "today".
class InMemoryBookingRepository implements BookingRepository {
  InMemoryBookingRepository({
    ConfirmationCodeGenerator? codeGenerator,
    DateTime Function()? clock,
    this.latency = const Duration(milliseconds: 600),
    Iterable<Booking> initialBookings = const <Booking>[],
  }) : _codes = codeGenerator ?? ConfirmationCodeGenerator(),
       _clock = clock ?? DateTime.now,
       _bookings = List<Booking>.of(initialBookings);

  final ConfirmationCodeGenerator _codes;
  final DateTime Function() _clock;
  final Duration latency;
  final List<Booking> _bookings;

  @override
  Future<List<Booking>> fetchAll() async {
    await _simulateLatency();
    return List<Booking>.unmodifiable(_bookings);
  }

  @override
  Future<Booking> create(BookingRequest request) async {
    await _simulateLatency();

    final now = _clock();
    final violation = BookingPolicy.check(request, today: dateOnly(now));
    if (violation != null) {
      throw violation;
    }

    final clash = _bookings.any(
      (existing) =>
          existing.isConfirmed &&
          existing.hotel == request.hotel &&
          BookingPolicy.staysOverlap(existing.stay, request.stay),
    );
    if (clash) {
      throw BookingException(
        BookingError.overlappingBooking,
        'You already have a booking at ${request.hotel.name} for these dates.',
      );
    }

    final booking = Booking(
      confirmationCode: _uniqueCode(),
      hotel: request.hotel,
      stay: request.stay,
      guest: request.guest,
      quote: request.quote,
      createdAt: now,
    );
    _bookings.add(booking);
    return booking;
  }

  @override
  Future<Booking> cancel(String confirmationCode) async {
    await _simulateLatency();

    final index = _bookings.indexWhere(
      (booking) => booking.confirmationCode == confirmationCode,
    );
    if (index < 0) {
      throw const BookingException(
        BookingError.notFound,
        'We could not find that booking.',
      );
    }
    final existing = _bookings[index];
    if (existing.isCancelled) {
      throw const BookingException(
        BookingError.alreadyCancelled,
        'This booking has already been cancelled.',
      );
    }

    final cancelled = existing.copyWith(status: BookingStatus.cancelled);
    _bookings[index] = cancelled;
    return cancelled;
  }

  String _uniqueCode() {
    // Collisions are astronomically unlikely, but a loop costs nothing.
    while (true) {
      final code = _codes.next();
      if (!_bookings.any((booking) => booking.confirmationCode == code)) {
        return code;
      }
    }
  }

  Future<void> _simulateLatency() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
  }
}
