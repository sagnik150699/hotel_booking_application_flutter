import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/entrance_animation.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../domain/hotel.dart';
import '../../domain/stay_search.dart';
import 'hotel_card.dart';

/// Number of result columns that comfortably fit in [width].
int columnsForWidth(double width) {
  if (width >= 900) {
    return 3;
  }
  if (width >= 560) {
    return 2;
  }
  return 1;
}

/// Lays hotels out in rows of [columns] equal-height cards, cascading in.
///
/// Rows are built lazily through a [SliverList]; using rows rather than a
/// [SliverGrid] lets each card size itself to its content.
class HotelResultsSliver extends StatelessWidget {
  const HotelResultsSliver({
    super.key,
    required this.hotels,
    required this.stay,
    required this.columns,
    required this.isSaved,
    required this.onSaveToggle,
    required this.onHotelTap,
    this.heroTagPrefix = 'hotel-cover',
    this.spacing = AppSpacing.lg,
  });

  final List<Hotel> hotels;
  final StaySearch stay;
  final int columns;
  final bool Function(Hotel hotel) isSaved;
  final ValueChanged<Hotel> onSaveToggle;
  final void Function(Hotel hotel, String heroTag) onHotelTap;
  final String heroTagPrefix;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rowCount = (hotels.length / columns).ceil();

    return SliverList.builder(
      itemCount: rowCount,
      itemBuilder: (context, row) {
        final start = row * columns;
        final end = math.min(start + columns, hotels.length);
        final rowHotels = hotels.sublist(start, end);

        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (var i = 0; i < columns; i++) ...<Widget>[
                  if (i > 0) SizedBox(width: spacing),
                  Expanded(
                    child: i < rowHotels.length
                        ? StaggeredEntrance(
                            index: start + i,
                            child: Builder(
                              builder: (context) {
                                final hotel = rowHotels[i];
                                final heroTag = '$heroTagPrefix-${hotel.id}';
                                return HotelCard(
                                  hotel: hotel,
                                  stay: stay,
                                  isSaved: isSaved(hotel),
                                  onSaveToggle: () => onSaveToggle(hotel),
                                  onTap: () => onHotelTap(hotel, heroTag),
                                  heroTag: heroTag,
                                );
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder rows shown while the inventory loads.
class HotelResultsSkeletonSliver extends StatelessWidget {
  const HotelResultsSkeletonSliver({
    super.key,
    required this.columns,
    this.rows = 2,
    this.spacing = AppSpacing.lg,
  });

  final int columns;
  final int rows;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: rows,
      itemBuilder: (context, row) => Padding(
        padding: EdgeInsets.only(bottom: spacing),
        child: Row(
          children: <Widget>[
            for (var i = 0; i < columns; i++) ...<Widget>[
              if (i > 0) SizedBox(width: spacing),
              const Expanded(child: _SkeletonCard()),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SkeletonBox(
              width: double.infinity,
              height: HotelCard.coverHeight,
              radius: 0,
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SkeletonBox(width: 180, height: 18),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(width: 120),
                  SizedBox(height: AppSpacing.md),
                  SkeletonBox(width: double.infinity),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonBox(width: 220),
                  SizedBox(height: AppSpacing.lg),
                  SkeletonBox(width: 100, height: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
