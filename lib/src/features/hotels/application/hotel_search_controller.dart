import 'package:flutter/foundation.dart';

import '../../../core/dates/date_only.dart';
import '../../../core/load_status.dart';
import '../data/hotel_repository.dart';
import '../domain/hotel.dart';
import '../domain/hotel_filters.dart';
import '../domain/hotel_search_engine.dart';
import '../domain/stay_search.dart';

/// Owns the inventory, the current [StaySearch] and [HotelFilters], and
/// exposes the derived result list. Widgets rebuild through
/// `ListenableBuilder`; nothing here imports the widgets layer.
class HotelSearchController extends ChangeNotifier {
  HotelSearchController({
    required HotelRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now,
       _stay = StaySearch.initial(today: (clock ?? DateTime.now)());

  final HotelRepository _repository;
  final DateTime Function() _clock;

  LoadStatus _status = LoadStatus.idle;
  List<Hotel> _hotels = const <Hotel>[];
  Object? _error;
  StaySearch _stay;
  HotelFilters _filters = HotelFilters.none;

  LoadStatus get status => _status;
  Object? get error => _error;

  /// Every hotel in the inventory, regardless of the current search.
  List<Hotel> get hotels => _hotels;

  StaySearch get stay => _stay;
  HotelFilters get filters => _filters;

  DateTime get today => dateOnly(_clock());

  /// Problem with the current stay, if any.
  StaySearchError? get stayError => _stay.validate(today: today);

  /// Hotels matching the current search and filters, in sort order.
  List<Hotel> get results => HotelSearchEngine.search(_hotels, _stay, _filters);

  /// Amenities offered by at least one hotel, most common first.
  List<String> get availableAmenities {
    final counts = <String, int>{};
    for (final hotel in _hotels) {
      for (final amenity in hotel.amenities) {
        counts.update(amenity, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return sorted;
  }

  /// Highest nightly price in the inventory; used to scale the price filter.
  int get maxInventoryPrice => _hotels.isEmpty
      ? 0
      : _hotels.map((h) => h.nightlyPrice).reduce((a, b) => a > b ? a : b);

  Hotel? hotelById(String id) {
    for (final hotel in _hotels) {
      if (hotel.id == id) {
        return hotel;
      }
    }
    return null;
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _hotels = await _repository.fetchAll();
      _status = LoadStatus.ready;
    } on Object catch (error) {
      _error = error;
      _status = LoadStatus.failed;
    }
    notifyListeners();
  }

  void updateDestination(String destination) {
    final next = _stay.copyWith(destination: destination);
    if (next == _stay) {
      return;
    }
    _stay = next;
    notifyListeners();
  }

  void updateDates(DateTime checkIn, DateTime checkOut) {
    _stay = _stay.withDates(checkIn, checkOut);
    notifyListeners();
  }

  void updateGuests(int guests) {
    final next = _stay.withGuests(guests);
    if (next == _stay) {
      return;
    }
    _stay = next;
    notifyListeners();
  }

  void incrementGuests() => updateGuests(_stay.guests + 1);

  void decrementGuests() => updateGuests(_stay.guests - 1);

  void setSort(HotelSortOption sort) {
    if (sort == _filters.sort) {
      return;
    }
    _filters = _filters.copyWith(sort: sort);
    notifyListeners();
  }

  void toggleAmenity(String amenity) {
    _filters = _filters.toggleAmenity(amenity);
    notifyListeners();
  }

  void toggleCategory(HotelCategory category) {
    _filters = _filters.toggleCategory(category);
    notifyListeners();
  }

  void setMinRating(double minRating) {
    _filters = _filters.copyWith(minRating: minRating);
    notifyListeners();
  }

  void setMaxNightlyPrice(int? maxNightlyPrice) {
    _filters = maxNightlyPrice == null
        ? _filters.copyWith(clearMaxNightlyPrice: true)
        : _filters.copyWith(maxNightlyPrice: maxNightlyPrice);
    notifyListeners();
  }

  void setFreeCancellationOnly(bool value) {
    _filters = _filters.copyWith(freeCancellationOnly: value);
    notifyListeners();
  }

  void clearRefinements() {
    _filters = _filters.clearRefinements();
    notifyListeners();
  }

  /// Back to the initial search and no refinements.
  void resetAll() {
    _stay = StaySearch.initial(today: today);
    _filters = HotelFilters.none;
    notifyListeners();
  }
}
