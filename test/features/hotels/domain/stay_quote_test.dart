import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/features/hotels/data/sample_hotels.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/stay_quote.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/stay_search.dart';

void main() {
  test('quote multiplies nights, adds tax and a flat fee', () {
    const quote = StayQuote(nightlyPrice: 6400, nights: 2, guests: 2);
    expect(quote.roomTotal, 12800);
    expect(quote.taxes, 1536); // 12%
    expect(quote.fees, StayQuote.serviceFee);
    expect(quote.total, 12800 + 1536 + 249);
  });

  test('zero nights costs nothing, including the fee', () {
    const quote = StayQuote(nightlyPrice: 6400, nights: 0, guests: 2);
    expect(quote.total, 0);
    expect(quote.fees, 0);
  });

  test('taxes round to the nearest rupee', () {
    const quote = StayQuote(nightlyPrice: 4301, nights: 1, guests: 1);
    expect(quote.taxes, 516); // 516.12 → 516
  });

  test('forStay reads the hotel price and stay length', () {
    final hotel = sampleHotels.first;
    final stay = StaySearch.initial(today: DateTime(2026, 10, 1)).withGuests(3);
    final quote = StayQuote.forStay(hotel, stay);
    expect(quote.nightlyPrice, hotel.nightlyPrice);
    expect(quote.nights, 2);
    expect(quote.guests, 3);
    expect(quote, StayQuote.forStay(hotel, stay));
  });
}
