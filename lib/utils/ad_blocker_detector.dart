import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBlockerDetector {
  static bool _hasShownDialog = false;

  /// Checks if the error code suggests an Ad Blocker is active
  static bool isBlockerError(LoadAdError error) {
    // 0: Internal Error, 2: Network Error
    return error.code == 0 || error.code == 2;
  }

  /// Shows the Modern Material 3 Dialog
  static void showDetectionDialog(BuildContext context) {
// 🛑 STOP if already shown in this session (Standard logic)
    if (_hasShownDialog) return;

    _hasShownDialog = true; // Mark as shown immediately

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _AdBlockerDialog(),
    );
  }
}

class _AdBlockerDialog extends StatelessWidget {
  const _AdBlockerDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerHigh, // Modern M3 Surface
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28), // Pixel-style rounded corners
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wrap content
          children: [
            // 1. Hero Icon with Tonal Background
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volunteer_activism_rounded, // Heart in hand icon
                size: 32,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 24),

            // 2. Headline
            Text(
              "Support StatusHub",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // 3. Body Text
            Text(
              "We noticed ads are failing to load. This usually happens when a private DNS or Ad Blocker is active.\n\n"
                  "StatusHub relies on ads to keep these tools free for everyone. Please consider supporting us by whitelisting our app.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5, // Better readability
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 4. Action Button (Full Width Tonal Button)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "I Understand",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}