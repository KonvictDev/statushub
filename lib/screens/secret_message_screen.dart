import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // ✅ Import AdMob
import 'package:statushub/utils/ad_helper.dart'; // ✅ Import AdHelper
import 'package:statushub/providers/secret_message_provider.dart';

import '../l10n/app_localizations.dart';
import '../widgets/whatsapp_background.dart';

// ✅ Converted to ConsumerStatefulWidget to manage Ad State
class SecretMessageEncrypter extends ConsumerStatefulWidget {
  const SecretMessageEncrypter({super.key});

  @override
  ConsumerState<SecretMessageEncrypter> createState() =>
      _SecretMessageEncrypterState();
}

class _SecretMessageEncrypterState
    extends ConsumerState<SecretMessageEncrypter> {
  // 💰 Ad Variables
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  // 💰 Load Banner Ad Logic
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load a banner ad: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // 💰 Dispose Ad
    super.dispose();
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
      String label, IconData icon, bool isDarkMode) {
    final borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey;
    final focusedColor = isDarkMode ? Colors.lightBlueAccent : Colors.blue;
    final fillColor = isDarkMode
        ? Colors.black.withOpacity(0.7)
        : Colors.white.withOpacity(0.9);

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: isDarkMode ? Colors.white : Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focusedColor),
      ),
      fillColor: fillColor,
      filled: true,
      labelStyle:
      TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    final state = ref.watch(secretMessageProvider);
    final notifier = ref.read(secretMessageProvider.notifier);

    return Scaffold(
      body: Stack(
        children: [
          const WhatsAppBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            BackButton(color: textColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                local.messageTitle,
                                style: TextStyle(
                                  fontSize: 24,
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 24),

                        TextField(
                          onChanged: notifier.setMessage,
                          decoration: _buildInputDecoration(
                              local.enterMessageLabel,
                              Icons.message,
                              isDarkMode),
                          maxLines: 5,
                          minLines: 3,
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<EncryptionMode>(
                          value: state.mode,
                          decoration: _buildInputDecoration(
                              local.encryptionModeLabel,
                              Icons.style,
                              isDarkMode),
                          dropdownColor:
                          isDarkMode ? Colors.grey[900] : Colors.white,
                          items: EncryptionMode.values.map((mode) {
                            return DropdownMenuItem(
                              value: mode,
                              child: Text(
                                mode == EncryptionMode.emoji
                                    ? local.emojiMode
                                    : local.symbolMode,
                                style: TextStyle(color: textColor),
                              ),
                            );
                          }).toList(),
                          onChanged: (EncryptionMode? newValue) {
                            if (newValue != null) {
                              notifier.setMode(newValue);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => notifier.encrypt(context),
                                icon: Icon(Icons.enhanced_encryption,
                                    color: textColor),
                                label: Text(local.encryptButton,
                                    style: TextStyle(color: textColor)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode
                                      ? Colors.white10
                                      : Colors.white.withOpacity(0.9),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: isDarkMode
                                            ? Colors.grey.shade700
                                            : Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => notifier.decrypt(context),
                                icon: Icon(Icons.no_encryption_gmailerrorred,
                                    color: textColor),
                                label: Text(local.decryptButton,
                                    style: TextStyle(color: textColor)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode
                                      ? Colors.white10
                                      : Colors.white.withOpacity(0.9),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: isDarkMode
                                            ? Colors.grey.shade700
                                            : Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(12.0),
                          height: 150,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.7)
                                : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              state.result.isEmpty
                                  ? local.resultPlaceholder
                                  : state.result,
                              style: TextStyle(
                                fontSize: 16,
                                color: state.result.isEmpty
                                    ? Colors.grey.shade400
                                    : textColor,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (state.result.isEmpty ||
                                  state.result == local.resultPlaceholder) {
                                _showSnackBar(context, local.noResultToCopy);
                                return;
                              }
                              Clipboard.setData(
                                  ClipboardData(text: state.result))
                                  .then((_) {
                                _showSnackBar(context, local.resultCopied);
                              });
                            },
                            icon: Icon(Icons.copy_all_outlined,
                                color: textColor),
                            label: Text(local.copyResultButton,
                                style: TextStyle(color: textColor)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? Colors.white10
                                  : Colors.white.withOpacity(0.9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: isDarkMode
                                        ? Colors.grey.shade700
                                        : Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // 💰 Banner Ad Display (Sticky Bottom)
                if (_isBannerAdReady)
                  Container(
                    alignment: Alignment.center,
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}