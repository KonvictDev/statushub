import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<void> sendMessage(
    BuildContext context,
    String number,
    String message,
  ) async {
    final formatted = number.replaceAll(RegExp(r'\D'), '');
    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse(
      "https://api.whatsapp.com/send?phone=$formatted&text=$encodedMessage",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("WhatsApp not installed or URL is invalid"),
        ),
      );
    }
  }

  static const MethodChannel _channel = MethodChannel(
    'com.appsbyanandakumar.statushub/open_whatsapp',
  );

  static Future<void> openWhatsApp(BuildContext context) async {
    if (Platform.isAndroid) {
      try {
        // Call native Android code to open WhatsApp
        final bool success = await _channel.invokeMethod('openWhatsApp');
        if (!success) {
          // fallback to Play Store
          final storeUri = Uri.parse(
            'https://play.google.com/store/apps/details?id=com.whatsapp',
          );
          await launchUrl(storeUri, mode: LaunchMode.externalApplication);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("WhatsApp not installed, opening Play Store..."),
            ),
          );
        }
      } on PlatformException catch (e) {
        // fallback to Play Store
        final storeUri = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.whatsapp',
        );
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("WhatsApp not installed, opening Play Store..."),
          ),
        );
      }
    } else if (Platform.isIOS) {
      // iOS fallback: open WhatsApp with dummy text
      final uri = Uri.parse('whatsapp://send?text=Hi');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // fallback to App Store
        final storeUri = Uri.parse(
          'https://apps.apple.com/app/whatsapp-messenger/id310633997',
        );
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("WhatsApp not installed, opening App Store..."),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Platform not supported")));
    }
  }

  static Future<void> shareFile(String path, {required bool isVideo}) async {
    try {
      await _channel.invokeMethod('shareFile', {
        'path': path,
        'isVideo': isVideo,
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to share to WhatsApp: ${e.message}");
    }
  }
}
