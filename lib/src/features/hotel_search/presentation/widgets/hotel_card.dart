import 'package:flutter/material.dart';

import '../../domain/hotel.dart';

class HotelCard extends StatelessWidget {
  const HotelCard({
    Key? key,
    required this.hotel,
    required this.isSaved,
    required this.onSavedToggle,
  }) : super(key: key);

  final Hotel hotel;
  final bool isSaved;
  final VoidCallback onSavedToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _HotelBadge(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    hotel.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF172026),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hotel.location,
                    style: const TextStyle(
                      color: Color(0xFF52616A),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hotel.description,
                    style: const TextStyle(
                      color: Color(0xFF38454D),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      for (final tag in hotel.tags) _AmenityChip(label: tag),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _PriceAndRating(
              hotel: hotel,
              isSaved: isSaved,
              onSavedToggle: onSavedToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _HotelBadge extends StatelessWidget {
  const _HotelBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFBFDCD4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.hotel_outlined,
        color: Color(0xFF143D36),
        size: 30,
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({Key? key, required this.label}) : super(key: key);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8A3E2B),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PriceAndRating extends StatelessWidget {
  const _PriceAndRating({
    Key? key,
    required this.hotel,
    required this.isSaved,
    required this.onSavedToggle,
  }) : super(key: key);

  final Hotel hotel;
  final bool isSaved;
  final VoidCallback onSavedToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.star, color: Color(0xFFF4A261), size: 18),
            const SizedBox(width: 3),
            Text(
              hotel.rating.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Rs ${hotel.nightlyPrice}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF143D36),
          ),
        ),
        const Text(
          'per night',
          style: TextStyle(color: Color(0xFF6B7880), fontSize: 12),
        ),
        const SizedBox(height: 8),
        IconButton(
          tooltip: isSaved
              ? 'Remove ${hotel.name} from saved hotels'
              : 'Save ${hotel.name}',
          icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border),
          color: const Color(0xFFE66A4E),
          onPressed: onSavedToggle,
        ),
      ],
    );
  }
}
