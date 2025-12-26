import 'dart:math';
import 'package:flutter/material.dart';

class WhatsAppBackground extends StatefulWidget {
  const WhatsAppBackground({super.key});

  @override
  State<WhatsAppBackground> createState() => _WhatsAppBackgroundState();
}

class _WhatsAppBackgroundState extends State<WhatsAppBackground> {
  WhatsAppPatternPainter? _painter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    // Generate painter only once per theme/size change
    _painter = WhatsAppPatternPainter(isDark: isDark, size: size);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD),
      child: CustomPaint(
        painter: _painter,
        size: MediaQuery.of(context).size,
      ),
    );
  }
}

class WhatsAppPatternPainter extends CustomPainter {
  final bool isDark;
  final List<_IconDataWithPosition> _iconPositions;

  WhatsAppPatternPainter({required this.isDark, required Size size})
      : _iconPositions = _generateIconPositions(size, isDark);

  static List<_IconDataWithPosition> _generateIconPositions(Size size, bool isDark) {
    final random = Random();
    final icons = <IconData>[
      Icons.chat_bubble_outline,
      Icons.phone_outlined,
      Icons.star_border,
      Icons.favorite_border,
      Icons.camera_alt_outlined,
      Icons.eco_outlined,
    ];

    final iconColor = (isDark ? Colors.white : Colors.black).withOpacity(0.07);
    const double step = 30;
    final positions = <_IconDataWithPosition>[];
    int index = 0;

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final icon = icons[index % icons.length];
        final dx = x + random.nextDouble() * 8 - 4;
        final dy = y + random.nextDouble() * 8 - 4;
        final angle = (random.nextDouble() * pi / 3) - (pi / 6);
        final sizePx = 14 + random.nextDouble() * 10;

        // ✅ OPTIMIZATION: Pre-calculate Layout
        final textPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              fontSize: sizePx,
              color: iconColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        positions.add(_IconDataWithPosition(
          icon: icon,
          dx: dx,
          dy: dy,
          angle: angle,
          size: sizePx,
          painter: textPainter,
        ));
        index++;
      }
    }
    return positions;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final data in _iconPositions) {
      canvas.save();
      canvas.translate(data.dx, data.dy);
      canvas.rotate(data.angle);

      // ✅ FAST PAINT
      data.painter.paint(canvas, Offset.zero);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IconDataWithPosition {
  final IconData icon;
  final double dx, dy, angle, size;
  final TextPainter painter; // ✅ Added

  _IconDataWithPosition({
    required this.icon,
    required this.dx,
    required this.dy,
    required this.angle,
    required this.size,
    required this.painter,
  });
}