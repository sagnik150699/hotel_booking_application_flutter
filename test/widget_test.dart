import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/app/hotel_booking_app.dart';

void main() {
  testWidgets('renders the hotel search experience', (tester) async {
    await tester.pumpWidget(const HotelBookingApp());

    expect(find.text('Find stays that fit the trip'), findsOneWidget);
    expect(find.text('Search hotels'), findsOneWidget);
    expect(find.text('The Park Residency'), findsOneWidget);
  });

  testWidgets('filters hotels by destination search text', (tester) async {
    await tester.pumpWidget(const HotelBookingApp());

    await tester.enterText(find.byKey(const Key('destinationField')), 'Salt');
    await tester.pump();

    expect(find.text('1 stays found'), findsOneWidget);
    expect(find.text('Salt Lake Suites'), findsOneWidget);
    expect(find.text('The Park Residency'), findsNothing);
  });

  testWidgets('updates guests and clears filters', (tester) async {
    await tester.pumpWidget(const HotelBookingApp());

    await tester.tap(find.byTooltip('Increase guests'));
    await tester.pump();

    expect(find.text('3 guests'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('destinationField')), 'none');
    await tester.pump();

    expect(
        find.text(
            'No matching hotels found. Try a different city, area, or amenity.'),
        findsOneWidget);

    await tester.tap(find.byTooltip('Clear filters'));
    await tester.pump();

    expect(find.text('2 guests'), findsOneWidget);
    expect(find.text('Recommended stays'), findsOneWidget);
    expect(find.text('The Park Residency'), findsOneWidget);
  });

  testWidgets('saves hotels and shows the saved list', (tester) async {
    await tester.pumpWidget(const HotelBookingApp());

    await tester.tap(find.byTooltip('Save The Park Residency'));
    await tester.pump();

    expect(
      find.byTooltip('Remove The Park Residency from saved hotels'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Saved hotels'));
    await tester.pumpAndSettle();

    expect(find.text('Saved hotels'), findsOneWidget);
    expect(find.text('The Park Residency'), findsWidgets);
  });
}
