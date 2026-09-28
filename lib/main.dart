import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app/hotel_booking_app.dart';

/// Build with `--dart-define=SCREENSHOT_MODE=true` to turn the semantics tree
/// on from the first frame. On the web this exposes accessible DOM nodes so
/// the screenshot script (tool/capture_screenshots.cjs) can drive the app;
/// the flag is off in normal builds.
const bool _screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  if (_screenshotMode) {
    binding.ensureSemantics();
  }
  // Draw behind the system bars on Android and iOS for a modern edge-to-edge look.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const HotelBookingApp());
}
