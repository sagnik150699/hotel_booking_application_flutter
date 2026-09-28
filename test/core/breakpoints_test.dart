import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/core/responsive/breakpoints.dart';
import 'package:hotel_booking_app/src/core/responsive/responsive_layout.dart';

void main() {
  test('sizeForWidth maps widths to size classes', () {
    expect(Breakpoints.sizeForWidth(320), ScreenSize.mobile);
    expect(Breakpoints.sizeForWidth(599), ScreenSize.mobile);
    expect(Breakpoints.sizeForWidth(600), ScreenSize.tablet);
    expect(Breakpoints.sizeForWidth(1023), ScreenSize.tablet);
    expect(Breakpoints.sizeForWidth(1024), ScreenSize.desktop);
  });

  test('ScreenSize helpers', () {
    expect(ScreenSize.mobile.isWide, isFalse);
    expect(ScreenSize.tablet.isWide, isTrue);
    expect(ScreenSize.desktop.isDesktop, isTrue);
  });

  testWidgets('ResponsiveLayout falls back to narrower layouts', (
    tester,
  ) async {
    Widget build(double width, {Widget? tablet, Widget? desktop}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: width,
            height: 100,
            child: ResponsiveLayout(
              mobile: const Text('mobile'),
              tablet: tablet,
              desktop: desktop,
            ),
          ),
        ),
      );
    }

    tester.view.physicalSize =
        const Size(2000, 1000) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(build(1200));
    expect(find.text('mobile'), findsOneWidget);

    await tester.pumpWidget(build(1200, tablet: const Text('tablet')));
    expect(find.text('tablet'), findsOneWidget);

    await tester.pumpWidget(
      build(1200, tablet: const Text('tablet'), desktop: const Text('desktop')),
    );
    expect(find.text('desktop'), findsOneWidget);

    await tester.pumpWidget(build(700, tablet: const Text('tablet')));
    expect(find.text('tablet'), findsOneWidget);
  });
}
