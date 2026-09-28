import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/features/hotels/application/saved_hotels_controller.dart';
import 'package:hotel_booking_app/src/features/hotels/data/sample_hotels.dart';

void main() {
  test('toggle adds then removes, notifying listeners', () {
    final controller = SavedHotelsController();
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    final hotel = sampleHotels.first;
    expect(controller.isEmpty, isTrue);
    expect(controller.toggle(hotel), isTrue);
    expect(controller.isSaved(hotel.id), isTrue);
    expect(controller.count, 1);
    expect(controller.toggle(hotel), isFalse);
    expect(controller.isSaved(hotel.id), isFalse);
    expect(notifications, 2);
  });

  test('savedFrom preserves inventory order and ignores unknown ids', () {
    final controller = SavedHotelsController(
      initialIds: <String>['drj-tea-estate', 'unknown', 'kol-park-residency'],
    );
    addTearDown(controller.dispose);
    expect(controller.savedFrom(sampleHotels).map((h) => h.id), <String>[
      'kol-park-residency',
      'drj-tea-estate',
    ]);
    expect(controller.savedIds, containsAll(<String>['unknown']));
    expect(() => controller.savedIds.add('x'), throwsUnsupportedError);
  });

  test('remove and clear', () {
    final controller = SavedHotelsController(initialIds: <String>['a', 'b']);
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.remove('missing');
    controller.remove('a');
    controller.clear();
    controller.clear();
    expect(controller.isEmpty, isTrue);
    expect(notifications, 2);
  });
}
