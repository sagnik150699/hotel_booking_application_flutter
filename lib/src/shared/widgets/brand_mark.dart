import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// The app's logo: a rounded tile with a stylised hotel façade and a sun.
///
/// Painted with vectors so it renders crisply at any size and needs no asset
/// to load before the first frame.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hotel Booking logo',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _BrandMarkPainter()),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 512;
    final rect = Offset.zero & size;

    final tile = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF17907A), AppColors.seed, Color(0xFF0A4E43)],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(112 * unit)),
      tile,
    );

    canvas.drawCircle(
      Offset(372 * unit, 150 * unit),
      46 * unit,
      Paint()..color = AppColors.star,
    );

    final facade = RRect.fromRectAndRadius(
      Rect.fromLTWH(120 * unit, 176 * unit, 272 * unit, 216 * unit),
      Radius.circular(28 * unit),
    );
    canvas.drawRRect(facade, Paint()..color = Colors.white);

    final window = Paint()..color = AppColors.seed;
    for (final x in <double>[156, 230, 304]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * unit, 212 * unit, 52 * unit, 52 * unit),
          Radius.circular(12 * unit),
        ),
        window,
      );
    }
    for (final x in <double>[156, 304]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * unit, 292 * unit, 52 * unit, 52 * unit),
          Radius.circular(12 * unit),
        ),
        window,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(226 * unit, 292 * unit, 60 * unit, 100 * unit),
        topLeft: Radius.circular(30 * unit),
        topRight: Radius.circular(30 * unit),
      ),
      Paint()..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
