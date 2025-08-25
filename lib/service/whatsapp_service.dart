import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_stickers_handler/model/sticker_pack.dart';
import 'package:whatsapp_stickers_handler/service/sticker_pack_util.dart';
import 'package:whatsapp_stickers_handler/whatsapp_stickers_handler.dart';

class WhatsAppService {

  final _handler = WhatsappStickersHandler();
  static const _kPackIdKey = 'wa_pack_identifier';
  static const _kPackNameKey = 'wa_pack_name';
  static const _kPackPublisherKey = 'wa_pack_publisher';
  static const _kPackDirKey = 'wa_pack_dir';

  Future<String> _getOrCreatePackDir() async {
    final prefs = await SharedPreferences.getInstance();
    final appDir = await getApplicationDocumentsDirectory();
    String? identifier = prefs.getString(_kPackIdKey);
    String? stickerDir = prefs.getString(_kPackDirKey);

    if (identifier == null || stickerDir == null) {
      identifier = "sticker_pack_${DateTime.now().millisecondsSinceEpoch}";
      stickerDir = "${appDir.path}/$identifier";
      await Directory(stickerDir).create(recursive: true);
      await prefs.setString(_kPackIdKey, identifier);
      await prefs.setString(_kPackDirKey, stickerDir);
    }
    return stickerDir;
  }

  Future<void> createOrUpdatePack({
    required File sticker,
    required String packName,
    required String publisher,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stickerDir = await _getOrCreatePackDir();

    final util = StickerPackUtil();
    final newStickerPath = '$stickerDir/sticker_${DateTime.now().millisecondsSinceEpoch}.webp';
    await util.createStickerFromImage(sticker.path, newStickerPath);

    final stickers = await _listWebpFiles(stickerDir);

    // Ensure min 3 stickers
    if (stickers.length < 3) {
      while (stickers.length < 3) {
        final duplicatePath = '$stickerDir/duplicate_${stickers.length}.webp';
        await File(stickers.first).copy(duplicatePath);
        stickers.add(duplicatePath);
      }
    }

    final trayPngPath = await util.saveWebpAsTrayImage(stickers.first);

    final pack = StickerPack(
      identifier: prefs.getString(_kPackIdKey)!,
      name: packName,
      publisher: publisher,
      trayImage: trayPngPath,
      stickers: stickers,
    );

    final installed = await _handler.isStickerPackInstalled(pack.identifier);
    if (installed) {
      await _handler.updateStickerPack(pack);
    } else {
      await _handler.addStickerPack(pack);
    }
  }

  Future<List<String>> _listWebpFiles(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];
    final files = await dir
        .list(recursive: false)
        .where((e) => e is File && e.path.toLowerCase().endsWith('.webp'))
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return files.map((f) => f.path).toList();
  }

  static Future<void> sendMessage(BuildContext context, String number, String message) async {
    final formatted = number.replaceAll(RegExp(r'\D'), '');
    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse("https://api.whatsapp.com/send?phone=$formatted&text=$encodedMessage");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("WhatsApp not installed or URL is invalid")),
      );
    }
  }
}
