import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Maps an amenity label to a Material icon. Unknown amenities get a tick.
IconData amenityIcon(String amenity) {
  switch (amenity.toLowerCase()) {
    case 'free wi-fi':
    case 'wi-fi':
      return Icons.wifi;
    case 'breakfast included':
      return Icons.free_breakfast_outlined;
    case 'pool':
      return Icons.pool_outlined;
    case 'gym':
      return Icons.fitness_center_outlined;
    case 'spa':
      return Icons.spa_outlined;
    case 'parking':
      return Icons.local_parking_outlined;
    case 'airport pickup':
      return Icons.airport_shuttle_outlined;
    case 'workspace':
      return Icons.desk_outlined;
    case 'kitchenette':
      return Icons.kitchen_outlined;
    case 'laundry':
      return Icons.local_laundry_service_outlined;
    case 'pet friendly':
      return Icons.pets_outlined;
    case 'rooftop bar':
      return Icons.wine_bar_outlined;
    case 'rooftop café':
      return Icons.local_cafe_outlined;
    case 'sea view':
      return Icons.waves_outlined;
    case 'city view':
      return Icons.location_city_outlined;
    case 'mountain view':
      return Icons.landscape_outlined;
    case 'lake view':
      return Icons.water_outlined;
    default:
      return Icons.check_circle_outline;
  }
}

/// Compact icon + label tag for an amenity.
class AmenityChip extends StatelessWidget {
  const AmenityChip({super.key, required this.label, this.compact = true});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 5 : 9,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            amenityIcon(label),
            size: compact ? 14 : 18,
            color: scheme.primary,
          ),
          SizedBox(width: compact ? 5 : 8),
          Text(
            label,
            style:
                (compact
                        ? theme.textTheme.labelSmall
                        : theme.textTheme.labelLarge)
                    ?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
          ),
        ],
      ),
    );
  }
}
