import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/dates/date_only.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../domain/stay_search.dart';

/// Input-styled button that opens the date range picker.
class DateRangeButton extends StatelessWidget {
  const DateRangeButton({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.onChanged,
    this.today,
  });

  final DateTime checkIn;
  final DateTime checkOut;
  final void Function(DateTime checkIn, DateTime checkOut) onChanged;

  /// Earliest selectable day; defaults to the current date.
  final DateTime? today;

  Future<void> _pick(BuildContext context) async {
    final first = dateOnly(today ?? DateTime.now());
    final last = first.add(const Duration(days: StaySearch.maxDaysAhead));
    final initialStart = checkIn.isBefore(first) ? first : checkIn;
    final initialEnd = checkOut.isAfter(initialStart)
        ? checkOut
        : initialStart.add(const Duration(days: 1));

    final range = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: 'Select check-in and check-out',
      saveText: 'Done',
      builder: (context, child) {
        // Keep the picker a comfortable size on desktop and web.
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
            child: child,
          ),
        );
      },
    );
    if (range != null) {
      onChanged(range.start, range.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nights = nightsBetween(checkIn, checkOut);
    return StayInputField(
      key: const Key('dateRangeButton'),
      label: 'Dates',
      icon: Icons.calendar_month_outlined,
      value: formatDateRange(checkIn, checkOut),
      detail: formatNights(nights),
      tooltip: 'Choose check-in and check-out dates',
      onTap: () => _pick(context),
    );
  }
}

/// Plus/minus control for the number of guests.
class GuestStepper extends StatelessWidget {
  const GuestStepper({
    super.key,
    required this.guests,
    required this.onChanged,
    this.min = StaySearch.minGuests,
    this.max = StaySearch.maxGuests,
  });

  final int guests;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StayInputField(
      label: 'Guests',
      icon: Icons.people_outline,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepButton(
            tooltip: 'Decrease guests',
            icon: Icons.remove,
            onPressed: guests > min ? () => onChanged(guests - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: AnimatedSwitcher(
              duration: AppDurations.fast,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                '$guests',
                key: ValueKey<int>(guests),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
          _StepButton(
            tooltip: 'Increase guests',
            icon: Icons.add,
            onPressed: guests < max ? () => onChanged(guests + 1) : null,
          ),
        ],
      ),
      value: formatGuests(guests),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Shared frame for the date and guest controls so they line up with the
/// destination text field.
class StayInputField extends StatelessWidget {
  const StayInputField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    this.detail,
    this.trailing,
    this.tooltip,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
  final String? detail;
  final Widget? trailing;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fill =
        theme.inputDecorationTheme.fillColor ?? scheme.surfaceContainerLow;

    Widget body = Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail == null ? value : '$value · $detail',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );

    if (onTap != null) {
      body = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: body,
        ),
      );
    }
    if (tooltip != null) {
      body = Tooltip(message: tooltip!, child: body);
    }
    return body;
  }
}
