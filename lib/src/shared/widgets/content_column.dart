import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';

/// Centres its child and caps its width on wide screens so text lines stay
/// readable on desktop and web.
class ContentColumn extends StatelessWidget {
  const ContentColumn({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Sliver counterpart of [ContentColumn].
class SliverContentColumn extends StatelessWidget {
  const SliverContentColumn({
    super.key,
    required this.sliver,
    this.maxWidth = Breakpoints.maxContentWidth,
  });

  final Widget sliver;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final inset = math.max(
          0.0,
          (constraints.crossAxisExtent - maxWidth) / 2,
        );
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          sliver: sliver,
        );
      },
    );
  }
}
