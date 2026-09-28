import '../../../core/validation/input_sanitizer.dart';
import 'hotel.dart';
import 'hotel_filters.dart';
import 'stay_search.dart';

/// Pure search logic: destination matching, party-size fit, refinements and
/// ordering. Keeping this free of Flutter types makes it trivial to unit test
/// and to swap for a server-side search later.
abstract final class HotelSearchEngine {
  /// Longest destination query the engine will consider.
  static const int maxQueryLength = 60;

  /// Returns the hotels from [hotels] that satisfy [stay] and [filters],
  /// ordered according to `filters.sort`.
  static List<Hotel> search(
    Iterable<Hotel> hotels,
    StaySearch stay,
    HotelFilters filters,
  ) {
    final tokens = tokenize(stay.destination);

    final matches = hotels.where((hotel) {
      if (hotel.maxGuests < stay.guests) {
        return false;
      }
      if (!filters.matches(hotel)) {
        return false;
      }
      if (tokens.isEmpty) {
        return true;
      }
      final haystack = hotel.searchableText;
      return tokens.every(haystack.contains);
    }).toList();

    matches.sort(comparatorFor(filters.sort));
    return List<Hotel>.unmodifiable(matches);
  }

  /// Splits a destination query into lower-cased search tokens.
  ///
  /// The query is sanitised first so control characters never reach the
  /// matcher, and it is capped at [maxQueryLength].
  static List<String> tokenize(String query) {
    final cleaned = InputSanitizer.clean(
      query,
      maxLength: maxQueryLength,
    ).toLowerCase();
    if (cleaned.isEmpty) {
      return const <String>[];
    }
    return cleaned
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  static Comparator<Hotel> comparatorFor(HotelSortOption sort) {
    switch (sort) {
      case HotelSortOption.priceLowToHigh:
        return (a, b) {
          final byPrice = a.nightlyPrice.compareTo(b.nightlyPrice);
          return byPrice != 0 ? byPrice : _byRatingDesc(a, b);
        };
      case HotelSortOption.priceHighToLow:
        return (a, b) {
          final byPrice = b.nightlyPrice.compareTo(a.nightlyPrice);
          return byPrice != 0 ? byPrice : _byRatingDesc(a, b);
        };
      case HotelSortOption.topRated:
        return _byRatingDesc;
      case HotelSortOption.recommended:
        return _byRecommendation;
    }
  }

  static int _byRatingDesc(Hotel a, Hotel b) {
    final byRating = b.rating.compareTo(a.rating);
    if (byRating != 0) {
      return byRating;
    }
    final byReviews = b.reviewCount.compareTo(a.reviewCount);
    return byReviews != 0 ? byReviews : a.name.compareTo(b.name);
  }

  /// Recommendation blends rating with how well-reviewed a property is, so a
  /// 4.8 from eleven reviews does not automatically beat a 4.7 from a thousand.
  static int _byRecommendation(Hotel a, Hotel b) {
    final byScore = _recommendationScore(b).compareTo(_recommendationScore(a));
    return byScore != 0 ? byScore : a.name.compareTo(b.name);
  }

  static double _recommendationScore(Hotel hotel) {
    // Bayesian-style shrinkage towards a 4.2 prior with a weight of 50 reviews.
    const prior = 4.2;
    const priorWeight = 50;
    final n = hotel.reviewCount;
    return (hotel.rating * n + prior * priorWeight) / (n + priorWeight);
  }
}
