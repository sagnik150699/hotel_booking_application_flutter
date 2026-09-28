import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/app/hotel_booking_app.dart';
import 'package:hotel_booking_app/src/features/booking/data/booking_repository.dart';
import 'package:hotel_booking_app/src/features/booking/domain/confirmation_code.dart';
import 'package:hotel_booking_app/src/features/hotels/data/hotel_repository.dart';
import 'package:hotel_booking_app/src/features/hotels/data/sample_hotels.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/hotel.dart';

/// Fixed "today" so date-dependent copy is stable in tests.
final DateTime testToday = DateTime(2026, 10, 1);

DateTime testClock() => testToday;

/// Common viewport sizes (logical pixels).
abstract final class Viewports {
  static const Size phone = Size(390, 844);

  /// Tall phone so more of a page is built without scrolling.
  static const Size tallPhone = Size(390, 1800);
  static const Size tablet = Size(820, 1180);
  static const Size desktop = Size(1440, 900);
}

/// Repository that always fails, for error-state tests.
class FailingHotelRepository implements HotelRepository {
  @override
  Future<List<Hotel>> fetchAll() async => throw StateError('offline');

  @override
  Future<Hotel?> findById(String id) async => throw StateError('offline');
}

/// Pumps the full app with deterministic data, zero latency and the
/// requested viewport, then settles the entrance animations.
Future<void> pumpApp(
  WidgetTester tester, {
  Size size = Viewports.tallPhone,
  HotelRepository? hotelRepository,
  BookingRepository? bookingRepository,
  List<Hotel>? hotels,
  ThemeMode themeMode = ThemeMode.light,
  bool settle = true,
}) async {
  await setViewport(tester, size);

  await tester.pumpWidget(
    HotelBookingApp(
      hotelRepository:
          hotelRepository ??
          InMemoryHotelRepository(
            hotels: hotels ?? sampleHotels,
            latency: Duration.zero,
          ),
      bookingRepository:
          bookingRepository ??
          InMemoryBookingRepository(
            latency: Duration.zero,
            clock: testClock,
            codeGenerator: ConfirmationCodeGenerator(),
          ),
      clock: testClock,
      themeMode: themeMode,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}

Future<void> setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
}

/// Scrolls the page until [finder] is built, then centres it in the viewport.
///
/// Centring matters: rows cascade in with a short slide animation, so aligning
/// a freshly built card with the very top edge can leave it a few pixels
/// off-screen once the animation completes.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}
