import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Fades and slides its child into place once, when it is first built.
///
/// Used for page content and list items so screens feel composed rather than
/// popping in. The animation runs exactly once and never repeats, which keeps
/// `pumpAndSettle` in widget tests deterministic.
class EntranceAnimation extends StatefulWidget {
  const EntranceAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppDurations.entrance,
    this.offset = const Offset(0, 0.06),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Starting offset as a fraction of the child's size.
  final Offset offset;
  final Curve curve;

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration + widget.delay,
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMilliseconds /
          (widget.duration + widget.delay).inMilliseconds,
      1,
      curve: widget.curve,
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _progress,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.offset,
          end: Offset.zero,
        ).animate(_progress),
        child: widget.child,
      ),
    );
  }
}

/// Staggers [EntranceAnimation]s by list position so cards cascade in.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 55),
    this.maxSteps = 8,
  });

  final int index;
  final Widget child;
  final Duration step;

  /// Items beyond this index share the same delay so long lists never wait.
  final int maxSteps;

  @override
  Widget build(BuildContext context) {
    final clamped = index.clamp(0, maxSteps).toInt();
    return EntranceAnimation(delay: step * clamped, child: child);
  }
}
