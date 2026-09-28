import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../hotels/presentation/widgets/hotel_cover.dart';
import '../../domain/booking.dart';

/// One reservation in the Trips list.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.onCancel,
    this.isCancelling = false,
  });

  final Booking booking;

  /// Null hides the cancel action (already cancelled, or too late).
  final VoidCallback? onCancel;
  final bool isCancelling;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stay = booking.stay;

    return AnimatedOpacity(
      duration: AppDurations.medium,
      opacity: booking.isCancelled ? 0.65 : 1,
      child: Card(
        key: Key('bookingCard-${booking.confirmationCode}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: HotelCover(
                        hotel: booking.hotel,
                        showCategory: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          booking.hotel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.hotel.location,
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
                  _StatusChip(status: booking.status),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(
                icon: Icons.calendar_month_outlined,
                text:
                    '${formatDateRange(stay.checkIn, stay.checkOut)} · ${formatNights(stay.nights)}',
              ),
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                icon: Icons.people_outline,
                text: formatGuests(stay.guests),
              ),
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                icon: Icons.confirmation_number_outlined,
                text: booking.confirmationCode,
                monospace: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Total ${formatInr(booking.quote.total)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  if (onCancel != null)
                    TextButton(
                      key: Key('cancelBooking-${booking.confirmationCode}'),
                      onPressed: isCancelling ? null : onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                      child: isCancelling
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Cancel booking'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = status == BookingStatus.confirmed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: confirmed
            ? AppColors.success.withValues(alpha: 0.14)
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            confirmed ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 14,
            color: confirmed ? AppColors.success : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: confirmed ? AppColors.success : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.monospace = false,
  });

  final IconData icon;
  final String text;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFeatures: monospace
                  ? const <FontFeature>[FontFeature.tabularFigures()]
                  : null,
              letterSpacing: monospace ? 1.2 : null,
              fontWeight: monospace ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}
