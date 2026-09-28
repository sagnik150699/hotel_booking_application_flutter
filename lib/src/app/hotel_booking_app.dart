import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../features/booking/data/booking_repository.dart';
import '../features/hotels/data/hotel_repository.dart';
import '../features/shell/presentation/home_shell.dart';
import 'app_scope.dart';
import 'theme/app_theme.dart';

/// Root of the application.
///
/// Repositories and the clock are injectable so tests and previews can run
/// with deterministic data and no artificial latency.
class HotelBookingApp extends StatefulWidget {
  const HotelBookingApp({
    super.key,
    this.hotelRepository,
    this.bookingRepository,
    this.clock,
    this.themeMode = ThemeMode.system,
  });

  final HotelRepository? hotelRepository;
  final BookingRepository? bookingRepository;
  final DateTime Function()? clock;
  final ThemeMode themeMode;

  @override
  State<HotelBookingApp> createState() => _HotelBookingAppState();
}

class _HotelBookingAppState extends State<HotelBookingApp> {
  late final AppDependencies _dependencies;

  @override
  void initState() {
    super.initState();
    _dependencies = AppDependencies(
      hotelRepository: widget.hotelRepository ?? InMemoryHotelRepository(),
      bookingRepository:
          widget.bookingRepository ??
          InMemoryBookingRepository(clock: widget.clock),
      clock: widget.clock,
    );
    unawaited(_dependencies.search.load());
    unawaited(_dependencies.bookings.load());
  }

  @override
  void dispose() {
    _dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: _dependencies,
      child: MaterialApp(
        title: 'Hotel Booking',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: widget.themeMode,
        scrollBehavior: const _AppScrollBehavior(),
        home: const HomeShell(),
      ),
    );
  }
}

/// Lets lists be dragged with a mouse on web and desktop, matching touch.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
