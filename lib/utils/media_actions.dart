import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:statushub/l10n/app_localizations.dart';
import 'package:statushub/utils/media_utils.dart'; // Ensure this import points to your MediaUtils file

class MediaActions {
  final BuildContext context;
  final File file;
  final bool isVideo;

  MediaActions(this.context, this.file, {required this.isVideo});

  // Helper to create a temporary copy of the file for sharing
  Future<File?> _getShareableFile({required String prefix}) async {
    try {
      final originalExtension = p.extension(file.path);
      final tempDir = await getTemporaryDirectory();
      final newFileName = "${prefix}_${DateTime.now().millisecondsSinceEpoch}$originalExtension";
      final newPath = "${tempDir.path}/$newFileName";
      return await file.copy(newPath);
    } catch (e) {
      debugPrint("Error copying file for sharing: $e");
      return null;
    }
  }

  // Share using the system share sheet
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
  Future<void> repost() async {
    final local = AppLocalizations.of(context)!;
    final shareableFile = await _getShareableFile(prefix: "Status_hub_repost");
    if (shareableFile == null) return;

    try {
      await SocialSharingPlus.shareToSocialMedia(
        SocialPlatform.whatsapp,
        local.appShareDetails,
        media: shareableFile.path,
        isOpenBrowser: true,
      );
    } catch (e) {
      debugPrint("Error while reposting to WhatsApp: $e");
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
      // Use the corrected MediaUtils class to save the file
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