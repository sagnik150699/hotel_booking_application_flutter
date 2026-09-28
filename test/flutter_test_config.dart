import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file.
///
/// A tap that misses its target is a bug in the test, so make it fail loudly
/// instead of printing a warning and carrying on.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  WidgetController.hitTestWarningShouldBeFatal = true;
  await testMain();
}
