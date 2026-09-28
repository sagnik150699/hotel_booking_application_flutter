import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/currency_formatter.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../shared/widgets/content_column.dart';
import '../../../../shared/widgets/entrance_animation.dart';
import '../../../shell/application/shell_controller.dart';
import '../../domain/booking.dart';

/// Success screen with the confirmation code.
class BookingConfirmationPage extends StatelessWidget {
  const BookingConfirmationPage({super.key, required this.booking});

  final Booking booking;

  static Route<void> route({required Booking booking}) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'booking-confirmation'),
      builder: (_) => BookingConfirmationPage(booking: booking),
    );
  }

  Future<void> _copyCode(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: booking.confirmationCode));
    messenger
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Confirmation code copied')));
  }

  void _goToTab(BuildContext context, ShellTab tab) {
    final deps = AppScope.of(context);
    deps.shell.select(tab);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stay = booking.stay;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => _goToTab(context, ShellTab.explore),
          ),
        ],
      ),
      body: ContentColumn(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: <Widget>[
            const SizedBox(height: AppSpacing.lg),
            const Center(child: SuccessBadge()),
            const SizedBox(height: AppSpacing.xl),
            EntranceAnimation(
              delay: const Duration(milliseconds: 350),
              child: Column(
                children: <Widget>[
                  Text(
                    "You're booked, ${booking.guest.firstName}!",
                    key: const Key('confirmationHeadline'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'A confirmation is on its way to ${booking.guest.maskedEmail}.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            EntranceAnimation(
              delay: const Duration(milliseconds: 450),
              child: Card(
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Confirmation code',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimaryContainer.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Flexible(
                            child: SelectableText(
                              booking.confirmationCode,
                              key: const Key('confirmationCode'),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: scheme.onPrimaryContainer,
                                letterSpacing: 2,
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          IconButton(
                            tooltip: 'Copy code',
                            onPressed: () => _copyCode(context),
                            icon: const Icon(Icons.copy_outlined),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            EntranceAnimation(
              delay: const Duration(milliseconds: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _Row(label: 'Hotel', value: booking.hotel.name),
                      _Row(label: 'Location', value: booking.hotel.location),
                      _Row(
                        label: 'Check-in',
                        value: formatLongDate(stay.checkIn),
                      ),
                      _Row(
                        label: 'Check-out',
                        value: formatLongDate(stay.checkOut),
                      ),
                      _Row(label: 'Guests', value: formatGuests(stay.guests)),
                      _Row(
                        label: 'Total paid at hotel',
                        value: formatInr(booking.quote.total),
                        emphasise: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            EntranceAnimation(
              delay: const Duration(milliseconds: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  FilledButton.icon(
                    key: const Key('viewTripsButton'),
                    onPressed: () => _goToTab(context, ShellTab.trips),
                    icon: const Icon(Icons.luggage_outlined),
                    label: const Text('View my trips'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => _goToTab(context, ShellTab.explore),
                    child: const Text('Back to explore'),
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

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: emphasise
                  ? theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    )
                  : theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated tick: the disc springs in, a ring ripples outward and the check
/// mark draws itself. Plays once.
class SuccessBadge extends StatefulWidget {
  const SuccessBadge({super.key, this.size = 120});

  final double size;

  @override
  State<SuccessBadge> createState() => _SuccessBadgeState();
}

class _SuccessBadgeState extends State<SuccessBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Booking confirmed',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _SuccessPainter(progress: _controller.value),
          ),
        ),
      ),
    );
  }
}

class _SuccessPainter extends CustomPainter {
  _SuccessPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.width * 0.34;

    // Ripple ring.
    final ripple = Curves.easeOut.transform(
      progress.clamp(0.0, 1.0).toDouble(),
    );
    canvas.drawCircle(
      centre,
      radius + radius * 0.6 * ripple,
      Paint()
        ..color = AppColors.success.withValues(alpha: (1 - ripple) * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Disc springs in.
    final discT = Curves.elasticOut.transform(
      (progress / 0.6).clamp(0.0, 1.0).toDouble(),
    );
    canvas.drawCircle(
      centre,
      radius * discT,
      Paint()..color = AppColors.success,
    );

    // Check mark draws itself.
    final checkT = Curves.easeOutCubic.transform(
      ((progress - 0.35) / 0.45).clamp(0.0, 1.0).toDouble(),
    );
    if (checkT > 0) {
      final path = Path()
        ..moveTo(centre.dx - radius * 0.45, centre.dy + radius * 0.02)
        ..lineTo(centre.dx - radius * 0.12, centre.dy + radius * 0.36)
        ..lineTo(centre.dx + radius * 0.5, centre.dy - radius * 0.32);
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(
          metric.extractPath(0, metric.length * checkT),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius * 0.16
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
