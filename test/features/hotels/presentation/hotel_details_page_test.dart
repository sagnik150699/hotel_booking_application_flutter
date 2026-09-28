import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/features/hotels/presentation/pages/hotel_details_page.dart';

import '../../../helpers/pump_app.dart';

Future<void> openDetails(WidgetTester tester, String name) async {
  await scrollTo(tester, find.text(name));
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  expect(find.byType(HotelDetailsPage), findsOneWidget);
}

void main() {
  testWidgets('shows description, amenities and the stay quote', (
    tester,
  ) async {
    await pumpApp(tester);
    await openDetails(tester, 'The Park Residency');

    expect(find.text('The Park Residency'), findsOneWidget);
    expect(find.textContaining('refurbished 1930s townhouse'), findsOneWidget);
    expect(find.text('Amenities'), findsOneWidget);
    expect(find.text('Rooftop café'), findsOneWidget);
    expect(find.text('Sleeps 3'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);
    // ₹6,400 × 2 nights = ₹12,800 + 12% tax (₹1,536) + ₹249 fee.
    expect(find.text('₹6,400 × 2 nights'), findsOneWidget);
    expect(find.byKey(const Key('reserveButton')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('reserveButton')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('save toggles from the details page and back button returns', (
    tester,
  ) async {
    await pumpApp(tester);
    await openDetails(tester, 'Riverside Grand');

    await tester.tap(find.byTooltip('Save Riverside Grand'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove Riverside Grand from saved'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(HotelDetailsPage), findsNothing);
    expect(find.byTooltip('Remove Riverside Grand from saved'), findsOneWidget);
  });

  testWidgets('blocks reserving when the party is too large', (tester) async {
    await pumpApp(tester);
    await openDetails(tester, 'Riverside Grand'); // sleeps 2

    await tester.tap(find.byTooltip('Increase guests'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sleeps up to 2 guests'), findsWidgets);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('reserveButton')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byTooltip('Decrease guests'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('reserveButton')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('desktop layout keeps the planner beside the overview', (
    tester,
  ) async {
    await pumpApp(tester, size: Viewports.desktop);
    await tester.tap(find.text('Anjuna Shore Resort'));
    await tester.pumpAndSettle();

    expect(find.text('Your stay'), findsOneWidget);
    expect(find.text('You will not be charged yet.'), findsOneWidget);
    expect(find.byKey(const Key('reserveButton')), findsOneWidget);
  });
}
