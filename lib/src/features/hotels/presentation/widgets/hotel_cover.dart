import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/hotel.dart';

/// Colours and icon associated with each [HotelCategory].
extension HotelCategoryStyle on HotelCategory {
  List<Color> get gradient {
    switch (this) {
      case HotelCategory.boutique:
        return const <Color>[Color(0xFF6D3B7A), Color(0xFFC96A8A)];
      case HotelCategory.business:
        return const <Color>[Color(0xFF1F3B73), Color(0xFF4E7BD1)];
      case HotelCategory.resort:
        return const <Color>[Color(0xFF0B6E7A), Color(0xFF48C2B0)];
      case HotelCategory.heritage:
        return const <Color>[Color(0xFF9A4A2A), Color(0xFFE0A050)];
      case HotelCategory.budget:
        return const <Color>[Color(0xFF2E6B3E), Color(0xFF7DBB6A)];
    }
  }

  IconData get icon {
    switch (this) {
      case HotelCategory.boutique:
        return Icons.auto_awesome_outlined;
      case HotelCategory.business:
        return Icons.business_center_outlined;
      case HotelCategory.resort:
        return Icons.beach_access_outlined;
      case HotelCategory.heritage:
        return Icons.account_balance_outlined;
      case HotelCategory.budget:
        return Icons.savings_outlined;
    }
  }
}

/// Cover art for a hotel: the bundled illustration fading in over a category
/// gradient, so there is always something meaningful on screen even before
/// the image decodes.
class HotelCover extends StatelessWidget {
  const HotelCover({
    super.key,
    required this.hotel,
    this.showCategory = true,
    this.fit = BoxFit.cover,
  });

  final Hotel hotel;
  final bool showCategory;
  final BoxFit fit;

  static String assetPath(Hotel hotel) =>
      'assets/images/hotels/${hotel.id}.jpg';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Illustration of ${hotel.name}',
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: hotel.category.gradient,
              ),
            ),
          ),
          Image.asset(
            assetPath(hotel),
            fit: fit,
            excludeFromSemantics: true,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) {
                return child;
              }
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: AppDurations.slow,
                curve: Curves.easeOut,
                child: child,
              );
            },
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
          if (showCategory)
            Positioned(
              left: AppSpacing.md,
              bottom: AppSpacing.md,
              child: CategoryPill(category: hotel.category),
            ),
        ],
      ),
    );
  }
}

/// Small translucent label naming the category, used over cover art.
class CategoryPill extends StatelessWidget {
  const CategoryPill({super.key, required this.category});

  final HotelCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(category.icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            category.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
