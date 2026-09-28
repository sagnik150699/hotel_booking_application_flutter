import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/features/hotels/presentation/pages/hotel_details_page.dart';
import 'package:hotel_booking_app/src/features/hotels/presentation/widgets/hotel_card.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('saved stays appear on the Saved tab and can be removed', (
    tester,
  ) async {
    await pumpApp(tester, size: Viewports.phone);

    await scrollTo(tester, find.byTooltip('Save Anjuna Shore Resort'));
    await tester.tap(find.byTooltip('Save Anjuna Shore Resort'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Saved stays (1)'), findsOneWidget);
    expect(find.byType(HotelCard), findsOneWidget);

    await tester.tap(find.text('Anjuna Shore Resort'));
    await tester.pumpAndSettle();
    expect(find.byType(HotelDetailsPage), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove Anjuna Shore Resort from saved'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(find.byType(HotelCard), findsNothing);

    await tester.tap(find.text('Explore stays'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });
}
