import 'dart:io';
import 'package:flutter/material.dart';
import 'package:statushub/constants/app_colors.dart';
import 'package:statushub/utils/media_actions.dart';
import 'package:statushub/utils/ad_helper.dart';
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  onPressed: actions.share,
                  icon: Icons.share_rounded,
                  label: local.share,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildButton(
                  onPressed: actions.repost,
                  icon: Icons.repeat_rounded,
                  label: local.repost,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          if (!isSaved) ...[
            const SizedBox(height: 16),
            _buildButton(
              onPressed: () async {
                await actions.save(); // 1. Save the file first

                // 2. Show the interstitial as a "post-action" reward
                AdHelper.showInterstitialAd(onComplete: () {
                  if (Navigator.of(sheetContext).canPop()) {
                    Navigator.of(sheetContext).pop();
                  }
                });
              },
              icon: Icons.download_rounded,
              label: local.saveToGallery,
              color: AppColors.primaryLight,
              isFullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isFullWidth = false,
  }) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color.withOpacity(0.6),
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: isFullWidth ? const EdgeInsets.symmetric(vertical: 16) : null,
        elevation: 3,
      ),
    );
  }
}