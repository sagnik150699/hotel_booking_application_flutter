import 'package:flutter/foundation.dart';

import 'hotel.dart';

/// Ordering applied to search results.
enum HotelSortOption {
  recommended('Recommended'),
  priceLowToHigh('Price: low to high'),
  priceHighToLow('Price: high to low'),
  topRated('Top rated');

  const HotelSortOption(this.label);

  final String label;
}

/// Refinements applied on top of the destination search.
@immutable
class HotelFilters {
  const HotelFilters({
    this.sort = HotelSortOption.recommended,
    this.maxNightlyPrice,
    this.minRating = 0,
    this.amenities = const <String>{},
    this.categories = const <HotelCategory>{},
    this.freeCancellationOnly = false,
  });

  static const HotelFilters none = HotelFilters();

  /// Rating thresholds offered by the UI.
  static const List<double> ratingSteps = <double>[0, 4.0, 4.5];

  final HotelSortOption sort;

  /// Upper bound on price per night, or `null` for no cap.
  final int? maxNightlyPrice;
  final double minRating;

  /// Every listed amenity must be present.
  final Set<String> amenities;

  /// When non-empty, only these categories are shown.
  final Set<HotelCategory> categories;
  final bool freeCancellationOnly;

  /// `true` when anything other than the sort order has been changed.
  bool get hasActiveRefinements =>
      maxNightlyPrice != null ||
      minRating > 0 ||
      amenities.isNotEmpty ||
      categories.isNotEmpty ||
      freeCancellationOnly;

  int get activeRefinementCount =>
      (maxNightlyPrice != null ? 1 : 0) +
      (minRating > 0 ? 1 : 0) +
      amenities.length +
      categories.length +
      (freeCancellationOnly ? 1 : 0);

  bool matches(Hotel hotel) {
    final priceCap = maxNightlyPrice;
    if (priceCap != null && hotel.nightlyPrice > priceCap) {
      return false;
    }
    if (hotel.rating < minRating) {
      return false;
    }
    if (freeCancellationOnly && !hotel.freeCancellation) {
      return false;
    }
    if (categories.isNotEmpty && !categories.contains(hotel.category)) {
      return false;
    }
    for (final amenity in amenities) {
      if (!hotel.amenities.contains(amenity)) {
        return false;
      }
    }
    return true;
  }

  HotelFilters copyWith({
    HotelSortOption? sort,
    int? maxNightlyPrice,
    bool clearMaxNightlyPrice = false,
    double? minRating,
    Set<String>? amenities,
    Set<HotelCategory>? categories,
    bool? freeCancellationOnly,
  }) {
    return HotelFilters(
      sort: sort ?? this.sort,
      maxNightlyPrice: clearMaxNightlyPrice
          ? null
          : (maxNightlyPrice ?? this.maxNightlyPrice),
      minRating: minRating ?? this.minRating,
      amenities: amenities ?? this.amenities,
      categories: categories ?? this.categories,
      freeCancellationOnly: freeCancellationOnly ?? this.freeCancellationOnly,
    );
  }

  HotelFilters toggleAmenity(String amenity) {
    final next = Set<String>.of(amenities);
    if (!next.remove(amenity)) {
      next.add(amenity);
    }
    return copyWith(amenities: next);
  }

  HotelFilters toggleCategory(HotelCategory category) {
    final next = Set<HotelCategory>.of(categories);
    if (!next.remove(category)) {
      next.add(category);
    }
    return copyWith(categories: next);
  }

  /// Keeps the sort order but drops every refinement.
  HotelFilters clearRefinements() => HotelFilters(sort: sort);

  @override
  bool operator ==(Object other) =>
      other is HotelFilters &&
      other.sort == sort &&
      other.maxNightlyPrice == maxNightlyPrice &&
      other.minRating == minRating &&
      setEquals(other.amenities, amenities) &&
      setEquals(other.categories, categories) &&
      other.freeCancellationOnly == freeCancellationOnly;

  @override
  int get hashCode => Object.hash(
    sort,
    maxNightlyPrice,
    minRating,
    Object.hashAllUnordered(amenities),
    Object.hashAllUnordered(categories),
    freeCancellationOnly,
  );
}
