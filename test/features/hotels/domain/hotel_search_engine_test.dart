import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/features/hotels/data/sample_hotels.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/hotel.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/hotel_filters.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/hotel_search_engine.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/stay_search.dart';

void main() {
  final today = DateTime(2026, 10, 1);
  final base = StaySearch.initial(today: today);

  List<Hotel> search(
    StaySearch stay, [
    HotelFilters filters = HotelFilters.none,
  ]) => HotelSearchEngine.search(sampleHotels, stay, filters);

  test('empty destination returns every hotel that fits the party', () {
    expect(search(base).length, sampleHotels.length);
    expect(search(base.withGuests(5)).map((h) => h.id), <String>[
      'drj-tea-estate',
    ]);
  });

  test('matches city, area, name and amenity, case-insensitively', () {
    expect(search(base.copyWith(destination: 'kolkata')).length, 3);
    expect(
      search(base.copyWith(destination: 'Anjuna')).single.id,
      'goa-anjuna-shore',
    );
    expect(
      search(base.copyWith(destination: 'amber')).single.id,
      'jai-haveli-amber',
    );
    expect(
      search(base.copyWith(destination: 'Lake view')).single.id,
      'udp-lake-palace-view',
    );
  });

  test('every token must match', () {
    expect(
      search(base.copyWith(destination: 'goa pool')).single.id,
      'goa-anjuna-shore',
    );
    expect(search(base.copyWith(destination: 'goa moon')), isEmpty);
  });

  test('tokenize sanitises and caps the query', () {
    expect(HotelSearchEngine.tokenize('  Park   Street '), <String>[
      'park',
      'street',
    ]);
    expect(HotelSearchEngine.tokenize(''), isEmpty);
    final long = 'a' * 200;
    expect(
      HotelSearchEngine.tokenize(long).single.length,
      HotelSearchEngine.maxQueryLength,
    );
    final control = 'goa${String.fromCharCode(0)}';
    expect(HotelSearchEngine.tokenize(control), <String>['goa']);
  });

  test('sort orders', () {
    final byPriceAsc = search(
      base,
      const HotelFilters(sort: HotelSortOption.priceLowToHigh),
    );
    expect(byPriceAsc.first.id, 'blr-whitefield-inn');
    for (var i = 1; i < byPriceAsc.length; i++) {
      expect(
        byPriceAsc[i].nightlyPrice,
        greaterThanOrEqualTo(byPriceAsc[i - 1].nightlyPrice),
      );
    }

    final byPriceDesc = search(
      base,
      const HotelFilters(sort: HotelSortOption.priceHighToLow),
    );
    expect(byPriceDesc.first.id, 'mum-marine-drive');

    final topRated = search(
      base,
      const HotelFilters(sort: HotelSortOption.topRated),
    );
    expect(topRated.first.id, 'drj-tea-estate');

    // Recommended favours well-reviewed hotels: Anjuna (4.8, 624 reviews) beats
    // the tea estate (4.9, 142 reviews).
    final recommended = search(base);
    expect(recommended.first.id, 'goa-anjuna-shore');
  });

  test('filters combine with the destination', () {
    final result = search(
      base.copyWith(destination: 'Kolkata'),
      const HotelFilters(freeCancellationOnly: true, maxNightlyPrice: 6000),
    );
    expect(result.map((h) => h.id), <String>['kol-salt-lake-suites']);
  });

  test('result list is unmodifiable', () {
    expect(() => search(base).add(sampleHotels.first), throwsUnsupportedError);
  });
}
