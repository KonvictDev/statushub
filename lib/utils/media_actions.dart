import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart';
import 'package:statushub/l10n/app_localizations.dart';

class MediaActions {
  final BuildContext context;
  final File file;
  final bool isVideo;

  MediaActions(this.context, this.file, {required this.isVideo});

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

  Future<void> share() async {
    final local = AppLocalizations.of(context)!;
    final shareableFile = await _getShareableFile(prefix: "Status_hub");
    if (shareableFile == null) return;
    await Share.shareXFiles(
      [XFile(shareableFile.path)],
      text: local.appShareDetails,
    );
  }

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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.failedToOpenWhatsApp)),
      );
    }
  }

  Future<void> save() async {
    final local = AppLocalizations.of(context)!;
    try {
      final saved = await saveToGallery(file, isVideo: isVideo);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(local.saveToGallery)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("failedToSave")),
        );
      }
    }
  }

  // This saveToGallery method is now within the class and handles native calls.
  Future<File> saveToGallery(File file, {required bool isVideo}) async {
    const platform = MethodChannel('com.appsbyanandakumar.statushub/media_scanner');
    final baseDir = Directory(
        '/storage/emulated/0/Download/StatusSaver/${isVideo ? "Videos" : "Images"}');
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    final newPath = p.join(baseDir.path, p.basename(file.path));
    final newFile = await file.copy(newPath);
    await platform.invokeMethod('scanMedia', {'paths': [newFile.path]});
    return newFile;
  }
}