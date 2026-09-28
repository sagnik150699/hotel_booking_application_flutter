import '../domain/hotel.dart';
import 'sample_hotels.dart';

/// Source of hotel inventory.
///
/// The UI only ever talks to this interface, so the in-memory sample data can
/// be replaced by a REST or GraphQL client without touching a single widget.
abstract interface class HotelRepository {
  Future<List<Hotel>> fetchAll();

  Future<Hotel?> findById(String id);
}

/// Serves the bundled [sampleHotels] with an optional artificial delay so the
/// app's loading states are exercised in development. Tests pass
/// `latency: Duration.zero` to skip the delay entirely.
class InMemoryHotelRepository implements HotelRepository {
  InMemoryHotelRepository({
    List<Hotel>? hotels,
    this.latency = const Duration(milliseconds: 450),
  }) : _hotels = List<Hotel>.unmodifiable(hotels ?? sampleHotels);

  final List<Hotel> _hotels;
  final Duration latency;

  @override
  Future<List<Hotel>> fetchAll() async {
    await _simulateLatency();
    return _hotels;
  }

  @override
  Future<Hotel?> findById(String id) async {
    await _simulateLatency();
    for (final hotel in _hotels) {
      if (hotel.id == id) {
        return hotel;
      }
    }
    return null;
  }

  Future<void> _simulateLatency() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
  }
}
