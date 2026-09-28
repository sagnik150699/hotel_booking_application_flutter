import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../application/hotel_search_controller.dart';
import '../../domain/hotel.dart';
import '../../domain/hotel_filters.dart';
import 'amenity_chip.dart';
import 'hotel_cover.dart';

/// Sort menu plus quick refinement chips.
///
/// Renders as a horizontally scrolling strip by default, or as a wrapping
/// block (for the desktop sidebar) when [wrap] is true.
class HotelFiltersBar extends StatelessWidget {
  const HotelFiltersBar({
    super.key,
    required this.controller,
    this.wrap = false,
    this.maxAmenities = 6,
  });

  final HotelSearchController controller;
  final bool wrap;
  final int maxAmenities;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final filters = controller.filters;
        final chips = <Widget>[
          if (filters.hasActiveRefinements)
            ActionChip(
              key: const Key('clearFiltersChip'),
              avatar: const Icon(Icons.close, size: 18),
              label: Text('Clear (${filters.activeRefinementCount})'),
              onPressed: controller.clearRefinements,
            ),
          _SortChip(sort: filters.sort, onSelected: controller.setSort),
          FilterChip(
            label: const Text('Free cancellation'),
            avatar: const Icon(Icons.event_available_outlined, size: 18),
            selected: filters.freeCancellationOnly,
            onSelected: controller.setFreeCancellationOnly,
          ),
          for (final rating in HotelFilters.ratingSteps.where((r) => r > 0))
            FilterChip(
              label: Text('Rated ${rating.toStringAsFixed(1)}+'),
              avatar: const Icon(
                Icons.star_rounded,
                size: 18,
                color: AppColors.star,
              ),
              selected: filters.minRating == rating,
              onSelected: (selected) =>
                  controller.setMinRating(selected ? rating : 0),
            ),
          for (final category in HotelCategory.values)
            FilterChip(
              label: Text(category.label),
              avatar: Icon(category.icon, size: 18),
              selected: filters.categories.contains(category),
              onSelected: (_) => controller.toggleCategory(category),
            ),
          for (final amenity in controller.availableAmenities.take(
            maxAmenities,
          ))
            FilterChip(
              label: Text(amenity),
              avatar: Icon(amenityIcon(amenity), size: 18),
              selected: filters.amenities.contains(amenity),
              onSelected: (_) => controller.toggleAmenity(amenity),
            ),
        ];

        if (wrap) {
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: chips,
          );
        }

        // Chips are few, so build them eagerly; a lazy list would defer the
        // trailing chips until scrolled into view.
        return SizedBox(
          height: 48,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              spacing: AppSpacing.sm,
              children: <Widget>[for (final chip in chips) Center(child: chip)],
            ),
          ),
        );
      },
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.sort, required this.onSelected});

  final HotelSortOption sort;
  final ValueChanged<HotelSortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<HotelSortOption>(
      key: const Key('sortMenu'),
      tooltip: 'Sort results',
      initialValue: sort,
      onSelected: onSelected,
      itemBuilder: (context) => <PopupMenuEntry<HotelSortOption>>[
        for (final option in HotelSortOption.values)
          PopupMenuItem<HotelSortOption>(
            value: option,
            child: Row(
              children: <Widget>[
                Icon(
                  option == sort
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(option.label, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
      ],
      child: Chip(
        avatar: const Icon(Icons.swap_vert, size: 18),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(sort.label),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}
