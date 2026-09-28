import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/features/shell/presentation/home_shell.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('phones get a bottom navigation bar and switch tabs', (
    tester,
  ) async {
    await pumpApp(tester, size: Viewports.phone);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Find your next stay'), findsOneWidget);

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();
    expect(find.text('No trips yet'), findsOneWidget);

    // Empty-state action jumps back to Explore.
    await tester.tap(find.text('Find a stay'));
    await tester.pumpAndSettle();
    expect(find.text('Find your next stay'), findsOneWidget);
  });

  testWidgets('tablets get a compact navigation rail', (tester) async {
    await pumpApp(tester, size: Viewports.tablet);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );
    expect(find.text('Explore'), findsWidgets);
  });

  testWidgets('desktop gets an extended rail with the brand', (tester) async {
    await pumpApp(tester, size: Viewports.desktop);

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(find.text('Hotel Booking'), findsOneWidget);
    expect(find.text('Refine'), findsOneWidget);
    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('saved count shows as a badge', (tester) async {
    await pumpApp(tester, size: Viewports.phone);
    await scrollTo(tester, find.byTooltip('Save The Park Residency'));
    await tester.tap(find.byTooltip('Save The Park Residency'));
    await tester.pumpAndSettle();

    final badges = tester
        .widgetList<Badge>(find.byType(Badge))
        .where((b) => b.isLabelVisible);
    expect(badges, isNotEmpty);
    expect(find.text('Saved The Park Residency'), findsOneWidget);
  });

  testWidgets('dark theme renders', (tester) async {
    await pumpApp(tester, size: Viewports.phone, themeMode: ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.dark,
    );
    expect(find.text('Find your next stay'), findsOneWidget);
  });
}
