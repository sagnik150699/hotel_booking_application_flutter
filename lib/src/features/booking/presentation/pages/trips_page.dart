import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../shared/widgets/content_column.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/entrance_animation.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../shell/application/shell_controller.dart';
import '../../../shell/presentation/home_shell.dart';
import '../../domain/booking.dart';
import '../widgets/booking_card.dart';

/// Upcoming reservations and history, with cancellation.
class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  Future<void> _confirmCancel(
    BuildContext context,
    AppDependencies deps,
    Booking booking,
  ) async {
    final stay = booking.stay;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
          'Your reservation at ${booking.hotel.name} for '
          '${formatDateRange(stay.checkIn, stay.checkOut)} will be released. '
          'This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            key: const Key('confirmCancelButton'),
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      await deps.bookings.cancel(booking.confirmationCode);
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Booking cancelled')));
    } on BookingException catch (error) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);

    return ListenableBuilder(
      listenable: deps.bookings,
      builder: (context, _) {
        final bookings = deps.bookings;
        final upcoming = bookings.upcoming;
        final history = bookings.history;

        return CustomScrollView(
          slivers: <Widget>[
            const SliverAppBar(
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              title: Text('Trips'),
            ),
            if (bookings.status.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (bookings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.luggage_outlined,
                  title: 'No trips yet',
                  message:
                      'Book a stay and it will show up here with its confirmation code.',
                  actionLabel: 'Find a stay',
                  onAction: () => context.showShellTab(ShellTab.explore),
                ),
              )
            else
              SliverContentColumn(
                maxWidth: 820,
                sliver: SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList.list(
                    children: <Widget>[
                      if (upcoming.isNotEmpty) ...<Widget>[
                        SectionHeader(
                          title: 'Upcoming',
                          subtitle:
                              '${upcoming.length} ${upcoming.length == 1 ? 'trip' : 'trips'}',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final (index, booking)
                            in upcoming.indexed) ...<Widget>[
                          StaggeredEntrance(
                            index: index,
                            child: BookingCard(
                              booking: booking,
                              isCancelling:
                                  bookings.cancellingCode ==
                                  booking.confirmationCode,
                              onCancel: booking.canCancel(today: bookings.today)
                                  ? () => _confirmCancel(context, deps, booking)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                      if (history.isNotEmpty) ...<Widget>[
                        if (upcoming.isNotEmpty)
                          const SizedBox(height: AppSpacing.lg),
                        const SectionHeader(title: 'Past and cancelled'),
                        const SizedBox(height: AppSpacing.md),
                        for (final (index, booking)
                            in history.indexed) ...<Widget>[
                          StaggeredEntrance(
                            index: index,
                            child: BookingCard(booking: booking),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
