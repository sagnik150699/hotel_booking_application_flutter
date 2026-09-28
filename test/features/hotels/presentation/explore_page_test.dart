import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/features/hotels/domain/hotel_filters.dart';
import 'package:hotel_booking_app/src/features/hotels/presentation/widgets/hotel_card.dart';

import '../../../helpers/pump_app.dart';

/// Chips live in a horizontal strip; bring one fully into view before tapping.
Future<void> tapChip(WidgetTester tester, Finder chip) async {
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

List<String> visibleHotelIds(WidgetTester tester) => tester
    .widgetList<HotelCard>(find.byType(HotelCard))
    .map((c) => c.hotel.id)
    .toList();

void main() {
  testWidgets('shows recommended stays with the current stay summary', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Recommended stays'), findsOneWidget);
    expect(
      find.textContaining('3 – 5 Oct · 2 nights · 2 guests'),
      findsOneWidget,
    );
    expect(find.text('Anjuna Shore Resort'), findsOneWidget);
    expect(find.textContaining('₹11,800'), findsWidgets);
    expect(find.byKey(const Key('destinationField')), findsOneWidget);
  });

  testWidgets('filters live as the destination is typed and can be cleared', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.enterText(
      find.byKey(const Key('destinationField')),
      'Kolkata',
    );
    await tester.pumpAndSettle();
    expect(find.text('3 stays for Kolkata'), findsOneWidget);
    expect(find.text('The Park Residency'), findsOneWidget);
    expect(find.text('Anjuna Shore Resort'), findsNothing);

    await tester.tap(find.byTooltip('Clear destination'));
    await tester.pumpAndSettle();
    expect(find.text('Recommended stays'), findsOneWidget);
  });

  testWidgets('search button announces the result count', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byKey(const Key('destinationField')), 'Goa');
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pump();
    expect(find.text('Showing 2 stays for "Goa"'), findsOneWidget);
  });

  testWidgets('shows an empty state and resets from it', (tester) async {
    await pumpApp(tester);
    await tester.enterText(
      find.byKey(const Key('destinationField')),
      'atlantis',
    );
    await tester.pumpAndSettle();

    expect(find.text('No stays match'), findsOneWidget);
    await tester.tap(find.text('Reset search'));
    await tester.pumpAndSettle();
    expect(find.text('Recommended stays'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('destinationField')))
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('guest stepper respects limits and party size filters hotels', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('2 guests'), findsWidgets);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byTooltip('Increase guests'));
      await tester.pumpAndSettle();
    }
    expect(find.text('6 guests'), findsWidgets);
    expect(find.text('1 stays for'), findsNothing);
    expect(visibleHotelIds(tester), <String>['drj-tea-estate']);

    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byTooltip('Decrease guests'));
      await tester.pumpAndSettle();
    }
    expect(find.text('1 guest'), findsWidgets);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove))
          .onPressed,
      isNull,
    );
  });

  testWidgets('sort menu reorders results', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('sortMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(HotelSortOption.priceLowToHigh.label).last);
    await tester.pumpAndSettle();

    expect(visibleHotelIds(tester).first, 'blr-whitefield-inn');
    expect(find.textContaining('sorted by price: low to high'), findsOneWidget);
  });

  testWidgets('filter chips refine and the clear chip removes them', (
    tester,
  ) async {
    await pumpApp(tester);

    await tapChip(tester, find.widgetWithText(FilterChip, 'Free cancellation'));
    expect(find.text('8 stays found'), findsOneWidget);
    expect(find.byKey(const Key('clearFiltersChip')), findsOneWidget);

    await tapChip(tester, find.widgetWithText(FilterChip, 'Rated 4.5+'));
    expect(find.text('6 stays found'), findsOneWidget);

    await tapChip(tester, find.byKey(const Key('clearFiltersChip')));
    expect(find.text('Recommended stays'), findsOneWidget);
    expect(find.byKey(const Key('clearFiltersChip')), findsNothing);
  });

  testWidgets('date picker opens from the dates field', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('dateRangeButton')));
    await tester.pumpAndSettle();
    expect(find.text('Select check-in and check-out'), findsOneWidget);
  });

  testWidgets('shows an error state with retry when loading fails', (
    tester,
  ) async {
    await pumpApp(tester, hotelRepository: FailingHotelRepository());
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('desktop layout shows a results grid beside the sidebar', (
    tester,
  ) async {
    await pumpApp(tester, size: Viewports.desktop);
    expect(find.text('Refine'), findsOneWidget);
    expect(find.byType(HotelCard), findsWidgets);
    final firstRow = tester
        .widgetList<HotelCard>(find.byType(HotelCard))
        .take(2)
        .toList();
    expect(
      tester.getTopLeft(find.byWidget(firstRow[0])).dy,
      tester.getTopLeft(find.byWidget(firstRow[1])).dy,
    );
  });
}
