import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/validation/input_sanitizer.dart';
import '../../application/hotel_search_controller.dart';
import '../../domain/hotel_search_engine.dart';
import 'stay_inputs.dart';

/// Destination, dates and guests. Filtering is live; the search button
/// dismisses the keyboard and calls [onSearch] for any extra behaviour.
class StaySearchPanel extends StatefulWidget {
  const StaySearchPanel({super.key, required this.controller, this.onSearch});

  final HotelSearchController controller;
  final VoidCallback? onSearch;

  @override
  State<StaySearchPanel> createState() => _StaySearchPanelState();
}

class _StaySearchPanelState extends State<StaySearchPanel> {
  late final TextEditingController _destination = TextEditingController(
    text: widget.controller.stay.destination,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromController);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    _destination.dispose();
    super.dispose();
  }

  /// Keeps the text field in step when the destination changes elsewhere,
  /// e.g. after "Reset".
  void _syncFromController() {
    final destination = widget.controller.stay.destination;
    if (_destination.text.trim() != destination) {
      _destination.value = TextEditingValue(
        text: destination,
        selection: TextSelection.collapsed(offset: destination.length),
      );
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    widget.onSearch?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = widget.controller;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final stay = controller.stay;
        final stayError = controller.stayError;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Where to?', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _destination,
                  builder: (context, value, _) {
                    return TextField(
                      key: const Key('destinationField'),
                      controller: _destination,
                      onChanged: controller.updateDestination,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _submit(),
                      textCapitalization: TextCapitalization.words,
                      autocorrect: false,
                      inputFormatters: <TextInputFormatter>[
                        LengthLimitingTextInputFormatter(
                          HotelSearchEngine.maxQueryLength,
                        ),
                        FilteringTextInputFormatter.deny(
                          InputSanitizer.disallowedPattern,
                        ),
                      ],
                      decoration: InputDecoration(
                        hintText: 'City, area, hotel or amenity',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: value.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear destination',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _destination.clear();
                                  controller.updateDestination('');
                                },
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final dates = DateRangeButton(
                      checkIn: stay.checkIn,
                      checkOut: stay.checkOut,
                      today: controller.today,
                      onChanged: controller.updateDates,
                    );
                    final guests = GuestStepper(
                      guests: stay.guests,
                      onChanged: controller.updateGuests,
                    );
                    if (constraints.maxWidth < 420) {
                      return Column(
                        children: <Widget>[
                          dates,
                          const SizedBox(height: AppSpacing.md),
                          guests,
                        ],
                      );
                    }
                    return Row(
                      children: <Widget>[
                        Expanded(child: dates),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: guests),
                      ],
                    );
                  },
                ),
                if (stayError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      stayError.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('searchButton'),
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.tertiary,
                          foregroundColor: scheme.onTertiary,
                        ),
                        icon: const Icon(Icons.search),
                        label: const Text('Search stays'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filledTonal(
                      tooltip: 'Reset search',
                      onPressed: controller.resetAll,
                      icon: const Icon(Icons.refresh),
                      constraints: const BoxConstraints.tightFor(
                        width: 52,
                        height: 52,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
