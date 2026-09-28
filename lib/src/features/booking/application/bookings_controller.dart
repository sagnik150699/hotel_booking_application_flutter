import 'package:flutter/foundation.dart';

import '../../../core/dates/date_only.dart';
import '../../../core/load_status.dart';
import '../data/booking_repository.dart';
import '../domain/booking.dart';

/// Loads, creates and cancels bookings.
///
/// Errors from the repository surface as [BookingException]s to the caller so
/// the UI can show the message; the controller itself only tracks status.
class BookingsController extends ChangeNotifier {
  BookingsController({
    required BookingRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now;

  final BookingRepository _repository;
  final DateTime Function() _clock;

  LoadStatus _status = LoadStatus.idle;
  List<Booking> _bookings = const <Booking>[];
  bool _isSubmitting = false;
  String? _cancellingCode;

  LoadStatus get status => _status;

  bool get isSubmitting => _isSubmitting;

  /// Confirmation code of the booking currently being cancelled, if any.
  String? get cancellingCode => _cancellingCode;

  DateTime get today => dateOnly(_clock());

  /// All bookings, soonest check-in first.
  List<Booking> get bookings => _bookings;

  List<Booking> get upcoming => _bookings
      .where((b) => b.isUpcoming(today: today))
      .toList(growable: false);

  /// Cancelled bookings and stays that have already ended.
  List<Booking> get history => _bookings
      .where((b) => !b.isUpcoming(today: today))
      .toList(growable: false);

  bool get isEmpty => _bookings.isEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _setBookings(await _repository.fetchAll());
      _status = LoadStatus.ready;
    } on Object catch (_) {
      _status = LoadStatus.failed;
    }
    notifyListeners();
  }

  /// Creates a booking. Rethrows [BookingException] so the caller can show
  /// the message; any other error is also rethrown after clearing the
  /// submitting flag.
  Future<Booking> book(BookingRequest request) async {
    if (_isSubmitting) {
      throw StateError('A booking is already being submitted.');
    }
    _isSubmitting = true;
    notifyListeners();
    try {
      final booking = await _repository.create(request);
      _setBookings(<Booking>[..._bookings, booking]);
      return booking;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<Booking> cancel(String confirmationCode) async {
    _cancellingCode = confirmationCode;
    notifyListeners();
    try {
      final cancelled = await _repository.cancel(confirmationCode);
      _setBookings(<Booking>[
        for (final booking in _bookings)
          if (booking.confirmationCode == confirmationCode)
            cancelled
          else
            booking,
      ]);
      return cancelled;
    } finally {
      _cancellingCode = null;
      notifyListeners();
    }
  }

  Booking? byCode(String confirmationCode) {
    for (final booking in _bookings) {
      if (booking.confirmationCode == confirmationCode) {
        return booking;
      }
    }
    return null;
  }

  void _setBookings(List<Booking> bookings) {
    final sorted = List<Booking>.of(bookings)
      ..sort((a, b) {
        final byCheckIn = a.stay.checkIn.compareTo(b.stay.checkIn);
        return byCheckIn != 0 ? byCheckIn : a.createdAt.compareTo(b.createdAt);
      });
    _bookings = List<Booking>.unmodifiable(sorted);
  }
}
