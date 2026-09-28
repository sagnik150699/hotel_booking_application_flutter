import 'package:flutter/foundation.dart';

import 'hotel.dart';
import 'stay_search.dart';

/// Price breakdown for a specific hotel and stay.
///
/// All amounts are whole rupees. The tax rate and service fee are sample
/// values for the demo; a production app would receive these from the
/// booking backend rather than compute them on the client.
@immutable
class StayQuote {
  const StayQuote({
    required this.nightlyPrice,
    required this.nights,
    required this.guests,
  }) : assert(nightlyPrice >= 0),
       assert(nights >= 0),
       assert(guests >= 0);

  factory StayQuote.forStay(Hotel hotel, StaySearch stay) => StayQuote(
    nightlyPrice: hotel.nightlyPrice,
    nights: stay.nights,
    guests: stay.guests,
  );

  /// Goods and services tax applied to the room total, in percent.
  static const int taxRatePercent = 12;

  /// Flat platform fee per booking. Waived when there are no nights.
  static const int serviceFee = 249;

  final int nightlyPrice;
  final int nights;
  final int guests;

  int get roomTotal => nightlyPrice * nights;

  int get taxes => (roomTotal * taxRatePercent / 100).round();

  int get fees => nights == 0 ? 0 : serviceFee;

  int get total => roomTotal + taxes + fees;

  @override
  bool operator ==(Object other) =>
      other is StayQuote &&
      other.nightlyPrice == nightlyPrice &&
      other.nights == nights &&
      other.guests == guests;

  @override
  int get hashCode => Object.hash(nightlyPrice, nights, guests);
}
