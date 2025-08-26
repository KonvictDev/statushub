import 'package:flutter/material.dart';
import 'package:statushub/constants/app_colors.dart';
import '../l10n/app_localizations.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback? onShare;
  final VoidCallback? onRepost;
  final Future<void> Function()? onSave;
  final BuildContext sheetContext;

  const ActionButtons({
    super.key,
    this.onShare,
    this.onRepost,
    this.onSave,
    required this.sheetContext,
  });

  Future<void> _handleSave() async {
    if (onSave != null) {
      await onSave!();
      if (Navigator.of(sheetContext).canPop()) {
        Navigator.of(sheetContext).pop();
      }
    }
  }

  void _handleShare() => onShare?.call();
  void _handleRepost() => onRepost?.call();

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

// Use fixed colors for all themes with opacity
    final primaryBg = AppColors.primary.withOpacity(0.6);    // 80% opacity
    final primaryFg = AppColors.white;                        // text stays fully opaque

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
                  onPressed: _handleShare,
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
                  onPressed: _handleRepost,
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
          if (onSave != null)
            FilledButton.icon(
              onPressed: _handleSave,
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
