import 'package:flutter/widgets.dart';

/// Layout size classes used across the app.
///
/// The thresholds follow the Material 3 window size class guidance:
/// compact (< 600), medium (600–839) and expanded (≥ 840). Names are kept
/// device-flavoured because that reads more naturally in course material.
enum ScreenSize {
  /// Phones in portrait.
  mobile,

  /// Large phones in landscape, small tablets, narrow desktop windows.
  tablet,

  /// Tablets in landscape, desktops and wide browser windows.
  desktop;

  bool get isMobile => this == ScreenSize.mobile;
  bool get isTablet => this == ScreenSize.tablet;
  bool get isDesktop => this == ScreenSize.desktop;

  /// Anything wider than a phone.
  bool get isWide => this != ScreenSize.mobile;
}

/// Central place for breakpoint values so widgets and tests agree.
abstract final class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  /// Widest the main content column is allowed to grow on large screens.
  static const double maxContentWidth = 1280;

  static ScreenSize sizeForWidth(double width) {
    if (width >= desktop) {
      return ScreenSize.desktop;
    }
    if (width >= tablet) {
      return ScreenSize.tablet;
    }
    return ScreenSize.mobile;
  }

  static ScreenSize of(BuildContext context) =>
      sizeForWidth(MediaQuery.sizeOf(context).width);
}
