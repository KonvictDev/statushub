import 'dart:io';
import 'package:flutter/material.dart';
import 'package:statushub/constants/app_colors.dart';
import 'package:statushub/utils/media_actions.dart';
import '../l10n/app_localizations.dart';

class ActionButtons extends StatelessWidget {
  final BuildContext sheetContext;
  final File file;
  final bool isSaved;
  final bool isVideo;

  const ActionButtons({
    super.key,
    required this.sheetContext,
    required this.file,
    required this.isSaved,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final actions = MediaActions(context, file, isVideo: isVideo);

    final primaryBg = AppColors.primary.withOpacity(0.6);
    final primaryFg = AppColors.white;
    final secondaryBg = AppColors.primaryDark.withOpacity(0.6);
    final secondaryFg = AppColors.white;
    final tertiaryBg = AppColors.primaryLight.withOpacity(0.6);
    final tertiaryFg = AppColors.white;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: actions.share,
                  icon: const Icon(Icons.share_rounded),
                  label: Text(local.share),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryBg,
                    foregroundColor: primaryFg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: actions.repost,
                  icon: const Icon(Icons.repeat_rounded),
                  label: Text(local.repost),
                  style: FilledButton.styleFrom(
                    backgroundColor: secondaryBg,
                    foregroundColor: secondaryFg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isSaved)
            FilledButton.icon(
              onPressed: () async {
                await actions.save();
                if (Navigator.of(sheetContext).canPop()) {
                  Navigator.of(sheetContext).pop();
                }
              },
              icon: const Icon(Icons.download_rounded),
              label: Text(local.saveToGallery),
              style: FilledButton.styleFrom(
                backgroundColor: tertiaryBg,
                foregroundColor: tertiaryFg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 3,
              ),
            ),
        ],
      ),
    );
  }
}