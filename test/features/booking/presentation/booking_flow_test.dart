import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking_app/src/features/booking/domain/confirmation_code.dart';
import 'package:hotel_booking_app/src/features/booking/presentation/pages/booking_confirmation_page.dart';
import 'package:hotel_booking_app/src/features/booking/presentation/pages/booking_page.dart';

import '../../../helpers/pump_app.dart';

Future<void> goToCheckout(WidgetTester tester, String hotelName) async {
  await scrollTo(tester, find.text(hotelName));
  await tester.tap(find.text(hotelName));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('reserveButton')));
  await tester.pumpAndSettle();
  expect(find.byType(BookingPage), findsOneWidget);
}

Future<void> fillGuestForm(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('guestNameField')),
    'Priya Sharma',
  );
  await tester.enterText(
    find.byKey(const Key('guestEmailField')),
    'priya@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('guestPhoneField')),
    '+91 98765 43210',
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('validates guest details before booking', (tester) async {
    await pumpApp(tester);
    await goToCheckout(tester, 'The Park Residency');

    await tester.tap(find.byKey(const Key('confirmBookingButton')));
    await tester.pumpAndSettle();
    expect(find.text("Enter the guest's full name."), findsOneWidget);
    expect(
      find.text('Enter an e-mail address for the confirmation.'),
      findsOneWidget,
    );
    expect(
      find.text('Enter a phone number the hotel can reach you on.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('guestNameField')), 'P');
    await tester.enterText(
      find.byKey(const Key('guestEmailField')),
      'not-an-email',
    );
    await tester.enterText(find.byKey(const Key('guestPhoneField')), '12');
    await tester.pumpAndSettle();
    expect(find.text('Name must be at least 2 characters.'), findsOneWidget);
    expect(find.text('Enter a valid e-mail address.'), findsOneWidget);
    expect(
      find.text('Phone number must have at least 8 digits.'),
      findsOneWidget,
    );

    await fillGuestForm(tester);
    await tester.tap(find.byKey(const Key('confirmBookingButton')));
    await tester.pumpAndSettle();
    expect(
      find.text('Please accept the house rules to continue.'),
      findsOneWidget,
    );
    expect(find.byType(BookingConfirmationPage), findsNothing);
  });

  testWidgets('books end to end, shows the code, lists and cancels the trip', (
    tester,
  ) async {
    await pumpApp(tester);
    await goToCheckout(tester, 'The Park Residency');

    expect(find.text('Confirm your stay'), findsOneWidget);
    expect(find.text('Sat, 3 Oct 2026 → Mon, 5 Oct 2026'), findsOneWidget);

    await fillGuestForm(tester);
    await tester.tap(find.byKey(const Key('houseRulesCheckbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmBookingButton')));
    await tester.pumpAndSettle();

    expect(find.byType(BookingConfirmationPage), findsOneWidget);
    expect(find.text("You're booked, Priya!"), findsOneWidget);
    expect(find.textContaining('p***a@example.com'), findsOneWidget);
    final code = tester
        .widget<SelectableText>(find.byKey(const Key('confirmationCode')))
        .data!;
    expect(ConfirmationCodeGenerator.isValid(code), isTrue);
    expect(find.text('₹14,585'), findsOneWidget); // 12,800 + 1,536 + 249

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.tap(find.byTooltip('Copy code'));
    await tester.pumpAndSettle();
    expect(copied, code);
    expect(find.text('Confirmation code copied'), findsOneWidget);

    await tester.tap(find.byKey(const Key('viewTripsButton')));
    await tester.pumpAndSettle();

    expect(find.byType(BookingConfirmationPage), findsNothing);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text(code), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);

    await tester.tap(find.byKey(Key('cancelBooking-$code')));
    await tester.pumpAndSettle();
    expect(find.text('Cancel this booking?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmCancelButton')));
    await tester.pumpAndSettle();

    expect(find.text('Booking cancelled'), findsOneWidget);
    expect(find.text('Past and cancelled'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Upcoming'), findsNothing);
  });

  testWidgets('refuses a second overlapping booking at the same hotel', (
    tester,
  ) async {
    await pumpApp(tester);

    for (var attempt = 0; attempt < 2; attempt++) {
      await goToCheckout(tester, 'Salt Lake Suites');
      await fillGuestForm(tester);
      await tester.tap(find.byKey(const Key('houseRulesCheckbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmBookingButton')));
      await tester.pumpAndSettle();

      if (attempt == 0) {
        expect(find.byType(BookingConfirmationPage), findsOneWidget);
        await tester.tap(find.text('Back to explore'));
        await tester.pumpAndSettle();
      } else {
        expect(find.byType(BookingConfirmationPage), findsNothing);
        expect(
          find.text(
            'You already have a booking at Salt Lake Suites for these dates.',
          ),
          findsOneWidget,
        );
      }
    }
  });

  testWidgets('desktop checkout shows the summary column', (tester) async {
    await pumpApp(tester, size: Viewports.desktop);
    await tester.tap(find.text('Anjuna Shore Resort'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reserveButton')));
    await tester.pumpAndSettle();

    expect(find.text('Guest details'), findsOneWidget);
    expect(find.text('Price details'), findsOneWidget);
    expect(find.textContaining('no payment is taken'), findsOneWidget);
  });
}
