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
      : _iconPositions = _generateIconPositions(size);

  static List<_IconDataWithPosition> _generateIconPositions(Size size) {
    final random = Random();
    final icons = <IconData>[
      Icons.chat_bubble_outline,
      Icons.phone_outlined,
      Icons.star_border,
      Icons.favorite_border,
      Icons.camera_alt_outlined,
      Icons.image_outlined,
      Icons.mic_none,
      Icons.insert_emoticon_outlined,
      Icons.link_outlined,
      Icons.access_time,
      Icons.notifications_none,
      Icons.group_outlined,
      Icons.location_on_outlined,
      Icons.gif_box_outlined,
      Icons.videocam_outlined,
      Icons.call_made,
      Icons.call_received,
      Icons.file_copy_outlined,
      Icons.send_outlined,
      Icons.wifi_tethering_outlined,
      Icons.security_outlined,
      Icons.settings_outlined,
      Icons.cloud_outlined,
      Icons.language_outlined,
      Icons.person_outline,
      Icons.tag_outlined,
      Icons.lock_outline,
      Icons.thumb_up_off_alt,
      Icons.event_note,
      Icons.shopping_bag_outlined,
      Icons.mail_outline,
      Icons.account_circle_outlined,
      Icons.laptop_mac_outlined,
      Icons.bolt_outlined,
      Icons.music_note_outlined,
      Icons.map_outlined,
      Icons.book_outlined,
      Icons.coffee_outlined,
      Icons.pets_outlined,
      Icons.sports_soccer_outlined,
      Icons.train_outlined,
      Icons.flight_outlined,
      Icons.work_outline,
      Icons.wallet_outlined,
      Icons.home_outlined,
      Icons.star_rate_outlined,
      Icons.light_mode_outlined,
      Icons.dark_mode_outlined,
      Icons.energy_savings_leaf_outlined,
      Icons.celebration_outlined,
      Icons.eco_outlined,
    ];

    const double step = 30; // distance between icons
    final positions = <_IconDataWithPosition>[];
    int index = 0;

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final icon = icons[index % icons.length];
        final dx = x + random.nextDouble() * 8 - 4;
        final dy = y + random.nextDouble() * 8 - 4;
        final angle = (random.nextDouble() * pi / 3) - (pi / 6);
        final sizePx = 14 + random.nextDouble() * 10; // 14–24 px

        positions.add(_IconDataWithPosition(
          icon: icon,
          dx: dx,
          dy: dy,
          angle: angle,
          size: sizePx,
        ));
        index++;
      }
    }
    return positions;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final iconColor = (isDark ? Colors.white : Colors.black).withOpacity(0.07);

    for (final data in _iconPositions) {
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
      canvas.translate(data.dx, data.dy);
      canvas.rotate(data.angle);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
