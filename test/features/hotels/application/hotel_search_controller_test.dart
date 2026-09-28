import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/core/load_status.dart';
import 'package:hotel_booking_app/src/features/hotels/application/hotel_search_controller.dart';
import 'package:hotel_booking_app/src/features/hotels/data/hotel_repository.dart';
import 'package:hotel_booking_app/src/features/hotels/data/sample_hotels.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/hotel.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/hotel_filters.dart';

import '../../../helpers/pump_app.dart';

void main() {
  late HotelSearchController controller;
  late int notifications;

  setUp(() {
    controller = HotelSearchController(
      repository: InMemoryHotelRepository(latency: Duration.zero),
      clock: testClock,
    );
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  test('starts idle with the initial stay', () {
    expect(controller.status, LoadStatus.idle);
    expect(controller.hotels, isEmpty);
    expect(controller.stay.guests, 2);
    expect(controller.today, testToday);
  });

  test('load moves to ready and exposes inventory-derived data', () async {
    await controller.load();
    expect(controller.status, LoadStatus.ready);
    expect(controller.hotels.length, sampleHotels.length);
    expect(controller.results.length, sampleHotels.length);
    expect(controller.availableAmenities.first, 'Free Wi-Fi');
    expect(controller.maxInventoryPrice, 14500);
    expect(
      controller.hotelById('goa-anjuna-shore')?.name,
      'Anjuna Shore Resort',
    );
    expect(controller.hotelById('nope'), isNull);
    expect(notifications, 2);
  });

  test('load failure is reported, not thrown', () async {
    final failing = HotelSearchController(
      repository: FailingHotelRepository(),
      clock: testClock,
    );
    addTearDown(failing.dispose);
    await failing.load();
    expect(failing.status, LoadStatus.failed);
    expect(failing.error, isA<StateError>());
  });

  test(
    'destination, dates and guests update the stay and notify once each',
    () async {
      await controller.load();
      notifications = 0;

      controller.updateDestination('Goa');
      controller.updateDestination('Goa'); // no-op
      expect(controller.results.length, 2);

      controller.updateDates(DateTime(2026, 10, 10), DateTime(2026, 10, 13));
      expect(controller.stay.nights, 3);

      controller.updateGuests(4);
      controller.incrementGuests();
      controller.decrementGuests();
      expect(controller.stay.guests, 4);
      expect(controller.results.map((h) => h.id), <String>['goa-anjuna-shore']);

      expect(notifications, 5);
    },
  );

  test('refinements and sorting', () async {
    await controller.load();
    controller.setSort(HotelSortOption.priceLowToHigh);
    controller.setSort(HotelSortOption.priceLowToHigh); // no-op
    expect(controller.results.first.id, 'blr-whitefield-inn');

    controller.toggleAmenity('Pool');
    controller.toggleCategory(HotelCategory.resort);
    controller.setMinRating(4.5);
    controller.setFreeCancellationOnly(true);
    controller.setMaxNightlyPrice(12000);
    expect(controller.filters.activeRefinementCount, 5);
    expect(controller.results.map((h) => h.id), <String>['goa-anjuna-shore']);

    controller.setMaxNightlyPrice(null);
    expect(controller.filters.maxNightlyPrice, isNull);

    controller.clearRefinements();
    expect(controller.filters.hasActiveRefinements, isFalse);
    expect(controller.filters.sort, HotelSortOption.priceLowToHigh);

    controller.resetAll();
    expect(controller.filters, HotelFilters.none);
    expect(controller.stay.guests, 2);
  });

  test('stayError reflects the clock', () async {
    controller.updateDates(DateTime(2026, 9, 1), DateTime(2026, 9, 3));
    expect(controller.stayError, isNotNull);
    controller.resetAll();
    expect(controller.stayError, isNull);
  });
}
