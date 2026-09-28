import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Lifts its child slightly on hover (web, desktop) and presses it down while
/// tapped, giving cards a tactile feel without any platform checks.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = AppRadius.lg,
    this.liftScale = 1.012,
    this.pressScale = 0.985,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double liftScale;
  final double pressScale;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scale = _pressed
        ? widget.pressScale
        : _hovered
        ? widget.liftScale
        : 1.0;
    final shadowAlpha = _hovered && !_pressed ? 0.16 : 0.0;

    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: AppDurations.fast,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: shadowAlpha),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
