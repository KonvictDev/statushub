import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:statushub/l10n/app_localizations.dart';
import 'package:statushub/utils/media_utils.dart';
import 'package:statushub/service/whatsapp_service.dart'; // ✅ Required for Native Share

class MediaActions {
  final BuildContext context;
  final File file;
  final bool isVideo;

  MediaActions(this.context, this.file, {required this.isVideo});

  // Helper to create a temporary copy of the file for sharing
  // ✅ FIX 1: Saves to 'status_cache' so your CacheManager auto-cleans it later
  Future<File?> _getShareableFile({required String prefix}) async {
    try {
      final originalExtension = p.extension(file.path);
      final tempDir = await getTemporaryDirectory();

      final cacheDir = Directory('${tempDir.path}/status_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final newFileName = "${prefix}_${DateTime.now().millisecondsSinceEpoch}$originalExtension";
      final newPath = "${cacheDir.path}/$newFileName";
      return await file.copy(newPath);
    } catch (e) {
      debugPrint("Error copying file for sharing: $e");
      return null;
    }
  }

  // Share using the system share sheet (General Share)
  Future<void> share() async {
    final local = AppLocalizations.of(context)!;
    final shareableFile = await _getShareableFile(prefix: "Status_hub");
    if (shareableFile == null) return;

    await Share.shareXFiles(
      [XFile(shareableFile.path)],
      text: local.appShareDetails,
    );
  }

  // Repost directly to WhatsApp
  // ✅ FIX 2: Uses Native MethodChannel to avoid plugin failures
  Future<void> repost() async {
    final local = AppLocalizations.of(context)!;

    // 1. Prepare the file
    final shareableFile = await _getShareableFile(prefix: "Status_hub_repost");
    if (shareableFile == null) return;

    // 2. Use Native Method Channel (Robust)
    try {
      await WhatsAppService.shareFile(
          shareableFile.path,
          isVideo: isVideo
      );
    } catch (e) {
      debugPrint("Error while reposting: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(local.failedToOpenWhatsApp)),
        );
      }
    }
  }

  // Save the status to the gallery
  Future<void> save() async {
    final local = AppLocalizations.of(context)!;
    try {
      await MediaUtils.saveToGallery(file, isVideo: isVideo);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(local.saveToGallery),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Save error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to save status"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}