import 'package:flutter/widgets.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  static const double tabletBreakpoint = 700;
  static const double desktopBreakpoint = 1100;

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= desktopBreakpoint) {
          return desktop ?? tablet ?? mobile;
        }

        if (constraints.maxWidth >= tabletBreakpoint) {
          return tablet ?? mobile;
        }

        return mobile;
      },
    );
  }
}
