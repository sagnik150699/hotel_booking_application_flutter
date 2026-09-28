import 'package:flutter/foundation.dart';

import '../domain/hotel.dart';

/// Tracks the traveller's shortlist by hotel id.
///
/// Storing ids rather than [Hotel] objects keeps the list stable if inventory
/// is refreshed and makes it trivial to persist later.
class SavedHotelsController extends ChangeNotifier {
  SavedHotelsController({Iterable<String> initialIds = const <String>[]})
    : _ids = Set<String>.of(initialIds);

  final Set<String> _ids;

  Set<String> get savedIds => Set<String>.unmodifiable(_ids);

  int get count => _ids.length;

  bool get isEmpty => _ids.isEmpty;

  bool isSaved(String hotelId) => _ids.contains(hotelId);

  /// Adds or removes [hotel] and returns whether it is now saved.
  bool toggle(Hotel hotel) {
    final nowSaved = !_ids.remove(hotel.id);
    if (nowSaved) {
      _ids.add(hotel.id);
    }
    notifyListeners();
    return nowSaved;
  }

  void remove(String hotelId) {
    if (_ids.remove(hotelId)) {
      notifyListeners();
    }
  }

  void clear() {
    if (_ids.isEmpty) {
      return;
    }
    _ids.clear();
    notifyListeners();
  }

  /// Saved hotels in the order they appear in [inventory].
  List<Hotel> savedFrom(Iterable<Hotel> inventory) => inventory
      .where((hotel) => _ids.contains(hotel.id))
      .toList(growable: false);
}
