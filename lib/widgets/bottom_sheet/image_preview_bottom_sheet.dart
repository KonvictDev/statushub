import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart';

import '../action_buttons.dart';
import '../disclaimer_box.dart';
import '../drag_indicator.dart';
import '../../l10n/app_localizations.dart';

class ImageViewerBottomSheet extends StatelessWidget {
  final File file;
  final Future<void> Function()? onSave;
  final bool isSaved;

  const ImageViewerBottomSheet({
    super.key,
    required this.file,
    this.onSave,
    required this.isSaved,
  });

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

  void _onShare(BuildContext context) async {
    final local = AppLocalizations.of(context)!;
    final shareableFile = await _getShareableFile(prefix: "Status_hub");
    if (shareableFile == null) return;

    await Share.shareXFiles(
      [XFile(shareableFile.path)],
      text: local.appShareDetails,
    );
  }

  void _onRepost(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? Colors.black : Colors.white, // background adapts to theme
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DragIndicator(),
            const DisclaimerBox(),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              color: isDark ? Colors.grey[900] : Colors.grey.shade100, // container also adapts
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: Hero(
                  tag: file.path,
                  child: Image.file(file, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ActionButtons(
              onShare: () => _onShare(context),
              onRepost: () => _onRepost(context),
              onSave: isSaved ? null : onSave,
              sheetContext: context,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

}
