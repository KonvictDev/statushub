import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart' ;

import '../action_buttons.dart';
import '../disclaimer_box.dart';
import '../drag_indicator.dart';

class ImageViewerBottomSheet extends StatelessWidget {
  final File file;
  final Future<void> Function()? onSave;

  const ImageViewerBottomSheet({
    super.key,
    required this.file,
    this.onSave,
  });


  void _onShare() async {
    try {
      // Pick a custom file name
      final newFileName = "Status_hub_${DateTime.now().millisecondsSinceEpoch}.jpg";

      // Create a temp directory path
      final tempDir = Directory.systemTemp;
      final newPath = "${tempDir.path}/$newFileName";

      // Copy the file with the new name
      final renamedFile = await file.copy(newPath);

      // Your app details (customize this)
      const appDetails = """
📱 Shared via MyAwesomeApp  
✨ Download now: https://example.com/app  
""";

      // Share the renamed file + app details
      await Share.shareXFiles(
        [XFile(renamedFile.path)],
        text: appDetails,
      );
    } catch (e) {
      debugPrint("Error while sharing: $e");
    }
  }


  /// Repost to WhatsApp / WhatsApp Business
  void _onRepost(BuildContext context) async {
    try {
      // Get app cache directory (matches file_paths.xml)
      final tempDir = await getTemporaryDirectory();

      final newFileName =
          "Status_hub_repost_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final newPath = "${tempDir.path}/$newFileName";

      final renamedFile = await file.copy(newPath);

      const appDetails = """
📱 Reposted via MyAwesomeApp  
✨ Download now: https://example.com/app  
""";

      await SocialSharingPlus.shareToSocialMedia(
        SocialPlatform.whatsapp,
        appDetails,
        media: renamedFile.path,
        isOpenBrowser: true,
      );
    } catch (e) {
      debugPrint("Error while reposting to WhatsApp: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to open WhatsApp")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container( // 👈 pushes the sheet down
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DragIndicator(),
              const DisclaimerBox(),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                color: Colors.grey.shade100,
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
                onShare: _onShare,
                onRepost: ()=>_onRepost(context),
                onSave: onSave ,
                sheetContext: context,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

}
