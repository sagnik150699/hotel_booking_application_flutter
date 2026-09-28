import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/hotel.dart';

/// Heart toggle that "pops" when a hotel is saved.
///
/// [onImage] renders a translucent dark disc behind the icon so it stays
/// legible over cover art.
class SaveButton extends StatefulWidget {
  const SaveButton({
    super.key,
    required this.hotel,
    required this.isSaved,
    required this.onPressed,
    this.onImage = false,
  });

  final Hotel hotel;
  final bool isSaved;
  final VoidCallback onPressed;
  final bool onImage;

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void didUpdateWidget(SaveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSaved && widget.isSaved) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tooltip = widget.isSaved
        ? 'Remove ${widget.hotel.name} from saved'
        : 'Save ${widget.hotel.name}';
    final iconColor = widget.isSaved
        ? AppColors.accent
        : widget.onImage
        ? Colors.white
        : scheme.onSurfaceVariant;

    return AnimatedBuilder(
      animation: _pop,
      builder: (context, child) {
        final scale = 1 + 0.35 * math.sin(math.pi * _pop.value);
        return Transform.scale(scale: scale, child: child);
      },
      child: IconButton(
        tooltip: tooltip,
        onPressed: widget.onPressed,
        isSelected: widget.isSaved,
        style: widget.onImage
            ? IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.35),
                shape: const CircleBorder(),
              )
            : null,
        icon: AnimatedSwitcher(
          duration: AppDurations.fast,
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            widget.isSaved ? Icons.favorite : Icons.favorite_border,
            key: ValueKey<bool>(widget.isSaved),
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
