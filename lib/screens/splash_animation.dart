import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WhatsAppBackground extends StatefulWidget {
  const WhatsAppBackground({super.key});

  @override
  State<WhatsAppBackground> createState() => _WhatsAppBackgroundState();
}

class _WhatsAppBackgroundState extends State<WhatsAppBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<_IconDataWithPosition> _iconPositions;
  late Size _screenSize;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _screenSize = Size.zero;
    _iconPositions = [];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generatePositions(Size size) {
    _iconPositions = _WhatsAppPatternPainter.generateIconPositions(size);
  }

  @override
  Widget build(BuildContext context) {
    final newSize = MediaQuery.of(context).size;

    if (_screenSize != newSize) {
      _screenSize = newSize;
      _generatePositions(newSize);
    }

    return Container(
      color: const Color(0xFF25D366),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            size: newSize,
            painter: _WhatsAppPatternPainter(
              iconPositions: _iconPositions,
              animationValue: _animationController.value,
              size: newSize,
            ),
          );
        },
      ),
    );
  }
}

// ---------------- WhatsApp Pattern Painter ----------------

class _WhatsAppPatternPainter extends CustomPainter {
  final List<_IconDataWithPosition> iconPositions;
  final double animationValue;
  final Size size;

  _WhatsAppPatternPainter({
    required this.iconPositions,
    required this.animationValue,
    required this.size,
  });

  // Fixed seed for consistent layout
  static List<_IconDataWithPosition> generateIconPositions(Size size) {
    final random = Random(42); // Fixed seed
    final icons = <IconData>[
      Icons.chat_bubble_outline,
      Icons.phone_outlined,
      Icons.camera_alt_outlined,
      Icons.mic_none,
      Icons.insert_emoticon_outlined,
      Icons.image_outlined,
      Icons.send_outlined,
      Icons.group_outlined,
      Icons.call_made,
      Icons.call_received,
      Icons.video_call_outlined,
      Icons.lock_outline,
      Icons.star_border,
      Icons.access_time,
      Icons.notifications_none,
      Icons.location_on_outlined,
      Icons.file_copy_outlined,
      Icons.music_note_outlined,
      Icons.attach_file,
      Icons.gif_box_outlined,
      Icons.home_outlined,
      Icons.person_outline,
      Icons.thumb_up_off_alt,
      Icons.event_note,
    ];

    const double step = 40;
    final positions = <_IconDataWithPosition>[];
    int index = 0;

    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        final icon = icons[index % icons.length];
        final dx = x + random.nextDouble() * 12 - 6;
        final dy = y + random.nextDouble() * 12 - 6;
        final angle = (random.nextDouble() * pi / 6) - (pi / 12);
        final iconSize = 24 + random.nextDouble() * 12;

        positions.add(_IconDataWithPosition(
          icon: icon,
          dx: dx,
          dy: dy,
          angle: angle,
          size: iconSize,
        ));
        index++;
      }
    }
    return positions;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final iconColor = Colors.black.withOpacity(0.08);
    final verticalMovement = size.height * animationValue;

    for (final data in iconPositions) {
      double y = data.dy - verticalMovement;
      if (y < -20) y += size.height + 40;

      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(data.icon.codePoint),
          style: TextStyle(
            fontFamily: data.icon.fontFamily,
            fontSize: data.size,
            color: iconColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(data.dx, y);
      canvas.rotate(data.angle);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WhatsAppPatternPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.size != size;
  }
}

class _IconDataWithPosition {
  final IconData icon;
  final double dx, dy, angle, size;

  _IconDataWithPosition({
    required this.icon,
    required this.dx,
    required this.dy,
    required this.angle,
    required this.size,
  });
}