import 'package:flutter/foundation.dart';

/// Broad positioning of a property. Drives cover art colours and filtering.
enum HotelCategory {
  boutique('Boutique'),
  business('Business'),
  resort('Resort'),
  heritage('Heritage'),
  budget('Budget');

  const HotelCategory(this.label);

  /// Human readable label shown in chips and on cover art.
  final String label;
}

/// A bookable property.
///
/// Prices are whole rupees per night and never carry a currency symbol; the
/// presentation layer formats them. The class is immutable and compares by
/// [id] only, so two snapshots of the same property are considered equal even
/// if a price changed between them.
@immutable
class Hotel {
  const Hotel({
    required this.id,
    required this.name,
    required this.city,
    required this.area,
    required this.tagline,
    required this.description,
    required this.nightlyPrice,
    required this.rating,
    required this.reviewCount,
    required this.maxGuests,
    required this.category,
    required this.amenities,
    this.freeCancellation = false,
  }) : assert(nightlyPrice > 0, 'nightlyPrice must be positive'),
       assert(rating >= 0 && rating <= 5, 'rating must be between 0 and 5'),
       assert(reviewCount >= 0, 'reviewCount cannot be negative'),
       assert(maxGuests > 0, 'maxGuests must be positive');

  /// Stable identifier used for saved lists and bookings.
  final String id;
  final String name;
  final String city;
  final String area;

  /// One-line hook shown on cards.
  final String tagline;

  /// Longer copy shown on the details page.
  final String description;

  /// Price per night in whole rupees.
  final int nightlyPrice;

  /// Average guest rating from 0 to 5.
  final double rating;
  final int reviewCount;

  /// Largest party a single booking can hold.
  final int maxGuests;
  final HotelCategory category;
  final List<String> amenities;
  final bool freeCancellation;

  /// `Area, City`
  String get location => '$area, $city';

  /// Lower-cased text used by the search engine. Computed on demand so the
  /// model stays a plain value object.
  String get searchableText => <String>[
    name,
    city,
    area,
    category.label,
    ...amenities,
  ].join(' ').toLowerCase();

  @override
  bool operator ==(Object other) => other is Hotel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Hotel($id, $name)';
}
