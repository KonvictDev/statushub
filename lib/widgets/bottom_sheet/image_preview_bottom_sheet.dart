import 'dart:io';
import 'package:flutter/material.dart';
import 'package:statushub/l10n/app_localizations.dart';
import '../action_buttons.dart';
import '../disclaimer_box.dart';
import '../drag_indicator.dart';

class ImageViewerBottomSheet extends StatelessWidget {
  final File file;
  final bool isSaved;

  const ImageViewerBottomSheet({
    super.key,
    required this.file,
    required this.isSaved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final local = AppLocalizations.of(context)!;

    return Material(
      color: isDark ? Colors.black : Colors.white,
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
              color: isDark ? Colors.grey[900] : Colors.grey.shade100,
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
              file: file,
              isSaved: isSaved,
              isVideo: false,
              sheetContext: context,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}