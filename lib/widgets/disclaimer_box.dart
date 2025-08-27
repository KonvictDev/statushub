import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class DisclaimerBox extends StatelessWidget {
  const DisclaimerBox({super.key});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(isDark ? 0.3 : 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                  local.statusDisclaimer,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.grey[800],
                    height: 1.3,
                  ),
                )
            ),
          ],
        ),
      ),
    );
  }
}