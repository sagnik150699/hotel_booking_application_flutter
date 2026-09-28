import 'package:flutter/widgets.dart';

import '../features/booking/application/bookings_controller.dart';
import '../features/booking/data/booking_repository.dart';
import '../features/hotels/application/hotel_search_controller.dart';
import '../features/hotels/application/saved_hotels_controller.dart';
import '../features/hotels/data/hotel_repository.dart';
import '../features/shell/application/shell_controller.dart';

/// The app's long-lived controllers, wired together in one place.
///
/// This is deliberately plain Flutter: an [InheritedWidget] carrying a bag of
/// [ChangeNotifier]s. It shows the mechanism packages such as `provider` build
/// on, and it keeps the sample free of third-party runtime dependencies.
class AppDependencies {
  AppDependencies({
    required HotelRepository hotelRepository,
    required BookingRepository bookingRepository,
    DateTime Function()? clock,
  }) : search = HotelSearchController(
         repository: hotelRepository,
         clock: clock,
       ),
       saved = SavedHotelsController(),
       bookings = BookingsController(
         repository: bookingRepository,
         clock: clock,
       ),
       shell = ShellController();

  final HotelSearchController search;
  final SavedHotelsController saved;
  final BookingsController bookings;
  final ShellController shell;

  void dispose() {
    search.dispose();
    saved.dispose();
    bookings.dispose();
    shell.dispose();
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencies, required super.child});

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.of() called outside of HotelBookingApp');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.dependencies != dependencies;
}
