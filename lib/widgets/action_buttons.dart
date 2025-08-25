import 'package:flutter/material.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

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
                  label: const Text("Share"),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
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
                  label: const Text("Repost"),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
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
          FilledButton.icon(
            onPressed: _handleSave,
            icon: const Icon(Icons.download_rounded),
            label: const Text("Save to Gallery"),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.tertiaryContainer,
              foregroundColor: colorScheme.onTertiaryContainer,
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
