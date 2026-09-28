import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Picks one of three layouts based on the width available to this widget.
///
/// Unlike [Breakpoints.of], which reads the whole window size, this widget
/// uses a [LayoutBuilder] so it responds to the space it is actually given,
/// e.g. inside a split view or a dialog.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        switch (Breakpoints.sizeForWidth(constraints.maxWidth)) {
          case ScreenSize.desktop:
            return desktop ?? tablet ?? mobile;
          case ScreenSize.tablet:
            return tablet ?? mobile;
          case ScreenSize.mobile:
            return mobile;
        }
      },
    );
  }
}

/// Convenience builder variant when the three layouts share most of their
/// widget tree and only differ by a few parameters.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, ScreenSize size) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          builder(context, Breakpoints.sizeForWidth(constraints.maxWidth)),
    );
  }
}
