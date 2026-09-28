import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Star rating pill, optionally with the review count.
class RatingBadge extends StatelessWidget {
  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount,
    this.large = false,
  });

  final double rating;
  final int? reviewCount;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reviews = reviewCount;

    return Semantics(
      label:
          'Rated ${rating.toStringAsFixed(1)} out of 5'
          '${reviews == null ? '' : ' from $reviews reviews'}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 12 : 8,
          vertical: large ? 8 : 5,
        ),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.star_rounded,
              size: large ? 22 : 16,
              color: AppColors.star,
            ),
            const SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style:
                  (large
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.labelLarge)
                      ?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
            ),
            if (reviews != null) ...<Widget>[
              const SizedBox(width: 4),
              Text(
                '($reviews)',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
