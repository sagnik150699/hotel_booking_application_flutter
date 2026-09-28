import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/validation/input_sanitizer.dart';
import '../../../../shared/widgets/content_column.dart';
import '../../../../shared/widgets/entrance_animation.dart';
import '../../../hotels/domain/hotel.dart';
import '../../../hotels/domain/stay_quote.dart';
import '../../../hotels/domain/stay_search.dart';
import '../../domain/booking.dart';
import '../../domain/guest_details.dart';
import '../widgets/price_breakdown.dart';
import '../widgets/stay_summary_card.dart';
import 'booking_confirmation_page.dart';

/// Checkout: guest details, price recap and confirmation.
///
/// Every field is validated on the client for fast feedback, then validated
/// again by [BookingPolicy] inside the repository. No payment is collected.
class BookingPage extends StatefulWidget {
  const BookingPage({super.key, required this.hotel, required this.stay});

  final Hotel hotel;
  final StaySearch stay;

  static Route<void> route({required Hotel hotel, required StaySearch stay}) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'booking'),
      builder: (_) => BookingPage(hotel: hotel, stay: stay),
    );
  }

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _agreed = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }
    if (!_agreed) {
      _showMessage('Please accept the house rules to continue.');
      return;
    }

    final deps = AppScope.of(context);
    final request = BookingRequest(
      hotel: widget.hotel,
      stay: widget.stay,
      guest: GuestDetails.sanitized(
        fullName: _name.text,
        email: _email.text,
        phone: _phone.text,
      ),
    );

    // Give the same answer the repository would, before a round trip.
    final early = BookingPolicy.check(request, today: deps.bookings.today);
    if (early != null) {
      _showMessage(early.message);
      return;
    }

    try {
      final booking = await deps.bookings.book(request);
      if (!mounted) {
        return;
      }
      await Navigator.of(
        context,
      ).pushReplacement(BookingConfirmationPage.route(booking: booking));
    } on BookingException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    final quote = StayQuote.forStay(widget.hotel, widget.stay);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm your stay')),
      body: ListenableBuilder(
        listenable: deps.bookings,
        builder: (context, _) {
          final submitting = deps.bookings.isSubmitting;
          final summary = EntranceAnimation(
            child: StaySummaryCard(hotel: widget.hotel, stay: widget.stay),
          );
          final price = EntranceAnimation(
            delay: const Duration(milliseconds: 100),
            child: _SectionCard(
              title: 'Price details',
              child: PriceBreakdown(quote: quote),
            ),
          );
          final form = EntranceAnimation(
            delay: const Duration(milliseconds: 60),
            child: _GuestForm(
              formKey: _formKey,
              name: _name,
              email: _email,
              phone: _phone,
              autovalidate: _autovalidate,
              agreed: _agreed,
              onAgreedChanged: (value) => setState(() => _agreed = value),
            ),
          );
          final submit = _SubmitButton(
            submitting: submitting,
            onPressed: _submit,
          );

          return ResponsiveBuilder(
            builder: (context, size) {
              if (size.isDesktop) {
                return ContentColumn(
                  maxWidth: 1100,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: form),
                        const SizedBox(width: AppSpacing.xl),
                        SizedBox(
                          width: 400,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              summary,
                              const SizedBox(height: AppSpacing.lg),
                              price,
                              const SizedBox(height: AppSpacing.lg),
                              submit,
                              const SizedBox(height: AppSpacing.sm),
                              const _DemoNote(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ContentColumn(
                maxWidth: 760,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: <Widget>[
                    summary,
                    const SizedBox(height: AppSpacing.lg),
                    form,
                    const SizedBox(height: AppSpacing.lg),
                    price,
                    const SizedBox(height: AppSpacing.xl),
                    submit,
                    const SizedBox(height: AppSpacing.sm),
                    const _DemoNote(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _GuestForm extends StatelessWidget {
  const _GuestForm({
    required this.formKey,
    required this.name,
    required this.email,
    required this.phone,
    required this.autovalidate,
    required this.agreed,
    required this.onAgreedChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  final AutovalidateMode autovalidate;
  final bool agreed;
  final ValueChanged<bool> onAgreedChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      autovalidateMode: autovalidate,
      child: _SectionCard(
        title: 'Guest details',
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                key: const Key('guestNameField'),
                controller: name,
                validator: GuestDetailsValidator.fullName,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.name,
                autofillHints: const <String>[AutofillHints.name],
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(
                    GuestDetailsValidator.nameMaxLength,
                  ),
                  FilteringTextInputFormatter.deny(
                    InputSanitizer.disallowedPattern,
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  hintText: 'As it appears on your ID',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('guestEmailField'),
                controller: email,
                validator: GuestDetailsValidator.email,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const <String>[AutofillHints.email],
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(
                    GuestDetailsValidator.emailMaxLength,
                  ),
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  FilteringTextInputFormatter.deny(
                    InputSanitizer.disallowedPattern,
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  hintText: 'Where we send the confirmation',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('guestPhoneField'),
                controller: phone,
                validator: GuestDetailsValidator.phone,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.phone,
                autofillHints: const <String>[AutofillHints.telephoneNumber],
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(24),
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s().\-]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: '+91 98765 43210',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                key: const Key('houseRulesCheckbox'),
                value: agreed,
                onChanged: (value) => onAgreedChanged(value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I agree to the house rules and the cancellation policy.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.submitting, required this.onPressed});

  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton(
      key: const Key('confirmBookingButton'),
      onPressed: submitting ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.tertiary,
        foregroundColor: scheme.onTertiary,
        minimumSize: const Size.fromHeight(56),
      ),
      child: AnimatedSwitcher(
        duration: AppDurations.fast,
        child: submitting
            ? SizedBox.square(
                key: const ValueKey<String>('progress'),
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: scheme.onTertiary,
                ),
              )
            : const Text('Confirm booking', key: ValueKey<String>('label')),
      ),
    );
  }
}

class _DemoNote extends StatelessWidget {
  const _DemoNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          Icons.lock_outline,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Demo app: no payment is taken and your details never leave this device.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
