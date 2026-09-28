import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../hotels/domain/hotel.dart';
import '../../../hotels/domain/stay_search.dart';
import '../../../hotels/presentation/widgets/hotel_cover.dart';

/// Compact recap of which hotel, which dates and how many guests.
class StaySummaryCard extends StatelessWidget {
  const StaySummaryCard({super.key, required this.hotel, required this.stay});

  final Hotel hotel;
  final StaySearch stay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                width: 96,
                height: 96,
                child: HotelCover(hotel: hotel, showCategory: false),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    hotel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hotel.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Detail(
                    icon: Icons.calendar_month_outlined,
                    text:
                        '${formatLongDate(stay.checkIn)} – ${formatLongDate(stay.checkOut)}',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _Detail(
                    icon: Icons.people_outline,
                    text:
                        '${formatNights(stay.nights)} · ${formatGuests(stay.guests)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
