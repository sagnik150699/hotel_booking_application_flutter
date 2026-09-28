import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../shared/widgets/hover_lift.dart';
import '../../domain/hotel.dart';
import '../../domain/stay_quote.dart';
import '../../domain/stay_search.dart';
import 'amenity_chip.dart';
import 'hotel_cover.dart';
import 'rating_badge.dart';
import 'save_button.dart';

/// Result card: cover art, essentials and the price for the current stay.
class HotelCard extends StatelessWidget {
  const HotelCard({
    super.key,
    required this.hotel,
    required this.stay,
    required this.isSaved,
    required this.onSaveToggle,
    required this.onTap,
    this.heroTag,
  });

  final Hotel hotel;
  final StaySearch stay;
  final bool isSaved;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;

  /// Shared with the details page so the cover flies between screens.
  final Object? heroTag;

  static const int _visibleAmenities = 3;
  static const double coverHeight = 176;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final quote = StayQuote.forStay(hotel, stay);
    final hidden = hotel.amenities.length - _visibleAmenities;

    return HoverLift(
      child: Card(
        child: InkWell(
          key: Key('hotelCard-${hotel.id}'),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: coverHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Hero(
                      tag: heroTag ?? 'hotel-cover-${hotel.id}',
                      child: HotelCover(hotel: hotel),
                    ),
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: SaveButton(
                        hotel: hotel,
                        isSaved: isSaved,
                        onPressed: onSaveToggle,
                        onImage: true,
                      ),
                    ),
                    if (hotel.freeCancellation)
                      const Positioned(
                        top: AppSpacing.md,
                        left: AppSpacing.md,
                        child: _Ribbon(label: 'Free cancellation'),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            hotel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        RatingBadge(rating: hotel.rating),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            hotel.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      hotel.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        for (final amenity in hotel.amenities.take(
                          _visibleAmenities,
                        ))
                          AmenityChip(label: amenity),
                        if (hidden > 0) _MoreChip(count: hidden),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text.rich(
                                TextSpan(
                                  children: <InlineSpan>[
                                    TextSpan(
                                      text: formatInr(hotel.nightlyPrice),
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(color: scheme.primary),
                                    ),
                                    TextSpan(
                                      text: ' / night',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (quote.nights > 0)
                                Text(
                                  '${formatInr(quote.total)} total · ${formatNights(quote.nights)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton.tonal(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                          ),
                          child: const Text('View'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '+$count more',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
