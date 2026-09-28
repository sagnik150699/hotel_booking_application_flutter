import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../shared/widgets/animated_amount_text.dart';
import '../../../hotels/domain/stay_quote.dart';

/// Itemised cost of a stay. The total animates when the quote changes.
class PriceBreakdown extends StatelessWidget {
  const PriceBreakdown({super.key, required this.quote});

  final StayQuote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Line(
          label:
              '${formatInr(quote.nightlyPrice)} × ${formatNights(quote.nights)}',
          amount: quote.roomTotal,
        ),
        const SizedBox(height: AppSpacing.sm),
        _Line(
          label: 'Taxes (${StayQuote.taxRatePercent}%)',
          amount: quote.taxes,
        ),
        const SizedBox(height: AppSpacing.sm),
        _Line(label: 'Service fee', amount: quote.fees),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Divider(),
        ),
        Row(
          children: <Widget>[
            Expanded(child: Text('Total', style: theme.textTheme.titleMedium)),
            AnimatedAmountText(
              key: const Key('quoteTotal'),
              amount: quote.total,
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: muted)),
        Text(formatInr(amount), style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
