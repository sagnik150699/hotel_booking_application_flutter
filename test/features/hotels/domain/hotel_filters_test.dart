import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/hotel.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/hotel_filters.dart';

void main() {
  const hotel = Hotel(
    id: 'h1',
    name: 'Test Hotel',
    city: 'Goa',
    area: 'Anjuna',
    tagline: 't',
    description: 'd',
    nightlyPrice: 5000,
    rating: 4.4,
    reviewCount: 10,
    maxGuests: 2,
    category: HotelCategory.resort,
    amenities: <String>['Pool', 'Free Wi-Fi'],
  );

  test('no filters matches everything and is not active', () {
    expect(HotelFilters.none.matches(hotel), isTrue);
    expect(HotelFilters.none.hasActiveRefinements, isFalse);
    expect(HotelFilters.none.activeRefinementCount, 0);
  });

  test('each refinement can exclude a hotel', () {
    expect(const HotelFilters(maxNightlyPrice: 4999).matches(hotel), isFalse);
    expect(const HotelFilters(maxNightlyPrice: 5000).matches(hotel), isTrue);
    expect(const HotelFilters(minRating: 4.5).matches(hotel), isFalse);
    expect(
      const HotelFilters(freeCancellationOnly: true).matches(hotel),
      isFalse,
    );
    expect(
      const HotelFilters(
        categories: <HotelCategory>{HotelCategory.budget},
      ).matches(hotel),
      isFalse,
    );
    expect(
      const HotelFilters(amenities: <String>{'Pool', 'Spa'}).matches(hotel),
      isFalse,
    );
    expect(
      const HotelFilters(amenities: <String>{'Pool'}).matches(hotel),
      isTrue,
    );
  });

  test('toggles, counts and clears refinements while keeping the sort', () {
    var filters = const HotelFilters(sort: HotelSortOption.topRated)
        .toggleAmenity('Pool')
        .toggleCategory(HotelCategory.resort)
        .copyWith(
          minRating: 4.5,
          freeCancellationOnly: true,
          maxNightlyPrice: 9000,
        );
    expect(filters.activeRefinementCount, 5);
    expect(filters.hasActiveRefinements, isTrue);

    filters = filters.toggleAmenity('Pool');
    expect(filters.amenities, isEmpty);

    filters = filters.copyWith(clearMaxNightlyPrice: true);
    expect(filters.maxNightlyPrice, isNull);

    final cleared = filters.clearRefinements();
    expect(cleared.hasActiveRefinements, isFalse);
    expect(cleared.sort, HotelSortOption.topRated);
  });

  test('value equality treats sets by content', () {
    const a = HotelFilters(amenities: <String>{'Pool', 'Gym'});
    const b = HotelFilters(amenities: <String>{'Gym', 'Pool'});
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
