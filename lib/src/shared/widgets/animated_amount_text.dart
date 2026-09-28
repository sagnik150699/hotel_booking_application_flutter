import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/formatting/currency_formatter.dart';

/// Counts smoothly from the previous amount to the new one whenever [amount]
/// changes, e.g. as the traveller adjusts dates on the details page.
class AnimatedAmountText extends StatelessWidget {
  const AnimatedAmountText({
    super.key,
    required this.amount,
    this.style,
    this.duration = AppDurations.slow,
  });

  final int amount;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: amount.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(
        formatInr(value.round()),
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
