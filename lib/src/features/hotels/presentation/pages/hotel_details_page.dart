import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../shared/widgets/animated_amount_text.dart';
import '../../../../shared/widgets/content_column.dart';
import '../../../../shared/widgets/entrance_animation.dart';
import '../../../booking/presentation/pages/booking_page.dart';
import '../../../booking/presentation/widgets/price_breakdown.dart';
import '../../domain/hotel.dart';
import '../../domain/stay_quote.dart';
import '../../domain/stay_search.dart';
import '../widgets/amenity_chip.dart';
import '../widgets/hotel_cover.dart';
import '../widgets/rating_badge.dart';
import '../widgets/save_button.dart';
import '../widgets/stay_inputs.dart';

/// Everything about one property, with the stay planner and the way into
/// checkout.
class HotelDetailsPage extends StatelessWidget {
  const HotelDetailsPage({super.key, required this.hotel, this.heroTag});

  final Hotel hotel;
  final Object? heroTag;

  static Route<void> route({required Hotel hotel, Object? heroTag}) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'hotel-details'),
      builder: (_) => HotelDetailsPage(hotel: hotel, heroTag: heroTag),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[deps.search, deps.saved]),
      builder: (context, _) {
        final stay = deps.search.stay;
        final quote = StayQuote.forStay(hotel, stay);
        final blocker = _reserveBlocker(stay, deps.search.stayError);

        return ResponsiveBuilder(
          builder: (context, size) {
            final isDesktop = size.isDesktop;
            final planner = _StayPlanner(
              hotel: hotel,
              stay: stay,
              quote: quote,
              today: deps.search.today,
              blocker: blocker,
              onDatesChanged: deps.search.updateDates,
              onGuestsChanged: deps.search.updateGuests,
              onReserve: blocker == null ? () => _reserve(context, stay) : null,
              showReserve: isDesktop,
            );

            return Scaffold(
              body: CustomScrollView(
                slivers: <Widget>[
                  SliverAppBar(
                    expandedHeight: isDesktop ? 380 : 300,
                    pinned: true,
                    stretch: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    leading: _OnImageButton(
                      tooltip: 'Back',
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    actions: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: SaveButton(
                          hotel: hotel,
                          isSaved: deps.saved.isSaved(hotel.id),
                          onPressed: () => deps.saved.toggle(hotel),
                          onImage: true,
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          Hero(
                            tag: heroTag ?? 'hotel-cover-${hotel.id}',
                            child: HotelCover(
                              hotel: hotel,
                              showCategory: false,
                            ),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.center,
                                colors: <Color>[
                                  Color(0x66000000),
                                  Color(0x00000000),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ContentColumn(
                      maxWidth: 1100,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(child: _Overview(hotel: hotel)),
                                  const SizedBox(width: AppSpacing.xl),
                                  SizedBox(width: 380, child: planner),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  _Overview(hotel: hotel),
                                  const SizedBox(height: AppSpacing.xl),
                                  planner,
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xxl),
                  ),
                ],
              ),
              bottomNavigationBar: isDesktop
                  ? null
                  : _ReserveBar(
                      quote: quote,
                      stay: stay,
                      blocker: blocker,
                      onReserve: blocker == null
                          ? () => _reserve(context, stay)
                          : null,
                    ),
            );
          },
        );
      },
    );
  }

  String? _reserveBlocker(StaySearch stay, StaySearchError? stayError) {
    if (stayError != null) {
      return stayError.message;
    }
    if (stay.guests > hotel.maxGuests) {
      return 'Sleeps up to ${formatGuests(hotel.maxGuests)}. Reduce the party size to book.';
    }
    return null;
  }

  Future<void> _reserve(BuildContext context, StaySearch stay) {
    return Navigator.of(
      context,
    ).push(BookingPage.route(hotel: hotel, stay: stay));
  }
}

class _OnImageButton extends StatelessWidget {
  const _OnImageButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Center(
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.35),
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
          ),
          icon: Icon(icon),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.hotel});

  final Hotel hotel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        EntranceAnimation(
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Chip(
                avatar: Icon(hotel.category.icon, size: 18),
                label: Text(hotel.category.label),
              ),
              if (hotel.freeCancellation)
                const Chip(
                  avatar: Icon(
                    Icons.event_available_outlined,
                    size: 18,
                    color: AppColors.success,
                  ),
                  label: Text('Free cancellation'),
                ),
              Chip(
                avatar: const Icon(Icons.people_outline, size: 18),
                label: Text('Sleeps ${hotel.maxGuests}'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        EntranceAnimation(
          delay: const Duration(milliseconds: 60),
          child: Text(hotel.name, style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        EntranceAnimation(
          delay: const Duration(milliseconds: 90),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.place_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  hotel.location,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        EntranceAnimation(
          delay: const Duration(milliseconds: 120),
          child: Row(
            children: <Widget>[
              RatingBadge(
                rating: hotel.rating,
                reviewCount: hotel.reviewCount,
                large: true,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  _ratingLabel(hotel.rating),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        EntranceAnimation(
          delay: const Duration(milliseconds: 160),
          child: Text(
            hotel.tagline,
            style: theme.textTheme.titleMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        EntranceAnimation(
          delay: const Duration(milliseconds: 200),
          child: Text(
            hotel.description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        EntranceAnimation(
          delay: const Duration(milliseconds: 240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Amenities', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final amenity in hotel.amenities)
                    AmenityChip(label: amenity, compact: false),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _ratingLabel(double rating) {
    if (rating >= 4.8) {
      return 'Exceptional';
    }
    if (rating >= 4.5) {
      return 'Excellent';
    }
    if (rating >= 4.0) {
      return 'Very good';
    }
    return 'Good';
  }
}

class _StayPlanner extends StatelessWidget {
  const _StayPlanner({
    required this.hotel,
    required this.stay,
    required this.quote,
    required this.today,
    required this.blocker,
    required this.onDatesChanged,
    required this.onGuestsChanged,
    required this.onReserve,
    required this.showReserve,
  });

  final Hotel hotel;
  final StaySearch stay;
  final StayQuote quote;
  final DateTime today;
  final String? blocker;
  final void Function(DateTime checkIn, DateTime checkOut) onDatesChanged;
  final ValueChanged<int> onGuestsChanged;
  final VoidCallback? onReserve;
  final bool showReserve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return EntranceAnimation(
      delay: const Duration(milliseconds: 140),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Your stay', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              DateRangeButton(
                checkIn: stay.checkIn,
                checkOut: stay.checkOut,
                today: today,
                onChanged: onDatesChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              GuestStepper(guests: stay.guests, onChanged: onGuestsChanged),
              const SizedBox(height: AppSpacing.lg),
              PriceBreakdown(quote: quote),
              if (blocker != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.info_outline, size: 18, color: scheme.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        blocker!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (showReserve) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  key: const Key('reserveButton'),
                  onPressed: onReserve,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.tertiary,
                    foregroundColor: scheme.onTertiary,
                  ),
                  child: const Text('Reserve'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'You will not be charged yet.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReserveBar extends StatelessWidget {
  const _ReserveBar({
    required this.quote,
    required this.stay,
    required this.blocker,
    required this.onReserve,
  });

  final StayQuote quote;
  final StaySearch stay;
  final String? blocker;
  final VoidCallback? onReserve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return EntranceAnimation(
      offset: const Offset(0, 1),
      delay: const Duration(milliseconds: 120),
      child: Material(
        color: scheme.surface,
        elevation: 8,
        shadowColor: scheme.shadow.withValues(alpha: 0.2),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedAmountText(
                        amount: quote.total,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                      Text(
                        blocker ??
                            'total · ${formatNights(stay.nights)} · ${formatGuests(stay.guests)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: blocker == null
                              ? scheme.onSurfaceVariant
                              : scheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton(
                  key: const Key('reserveButton'),
                  onPressed: onReserve,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.tertiary,
                    foregroundColor: scheme.onTertiary,
                    minimumSize: const Size(140, 52),
                  ),
                  child: const Text('Reserve'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
