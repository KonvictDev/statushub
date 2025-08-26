import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../widgets/whatsapp_background.dart';

// --- HELPER CLASS FOR ENCRYPTION/DECRYPTION LOGIC ---

enum EncryptionMode { emoji, symbol }

class EncryptionHelper {
  static const String _separator = '\u200B';

  static const Map<String, String> _emojiMap = {
    'a': '🔥', 'b': '💧', 'c': '🌍', 'd': '💨', 'e': '�',
    'f': '⚡', 'g': '🌙', 'h': '☀️', 'i': '❄️', 'j': '🍀',
    'k': '🍁', 'l': '🌲', 'm': '🌊', 'n': '🗻', 'o': '🌸',
    'p': '🌹', 'q': '🌻', 'r': '🍄', 's': '🐚', 't': '🐢',
    'u': '🐳', 'v': '🦋', 'w': '🐞', 'x': '🐝', 'y': '🐜',
    'z': '🕷️',
    'A': '🚀', 'B': '🚗', 'C': '🚲', 'D': '✈️', 'E': '🚁',
    'F': '⛵', 'G': '🚂', 'H': '🚌', 'I': '🚑', 'J': '🚓',
    'K': '🚜', 'L': '🚚', 'M': '🛵', 'N': '🛸', 'O': '🛶',
    'P': '🚤', 'Q': '🚠', 'R': '🚟', 'S': '🛰️', 'T': '🚇',
    'U': '🚝', 'V': '🚄', 'W': '🚅', 'X': '🚈', 'Y': '🛺',
    'Z': '🚔',
    '0': '🔴', '1': '🟠', '2': '🟡', '3': '🟢', '4': '🔵',
    '5': '🟣', '6': '🟤', '7': '⚫', '8': '⚪', '9': '🟥',
    ' ': '🔳', '.': '🔹', ',': '🔸', '!': '🔺', '?': '🔻',
  };

  static const Map<String, String> _symbolMap = {
    'a': 'α', 'b': 'β', 'c': 'γ', 'd': 'δ', 'e': 'ε',
    'f': 'ζ', 'g': 'η', 'h': 'θ', 'i': 'ι', 'j': 'κ',
    'k': 'λ', 'l': 'μ', 'm': 'ν', 'n': 'ξ', 'o': 'ο',
    'p': 'π', 'q': 'ρ', 'r': 'σ', 's': 'τ', 't': 'υ',
    'u': 'φ', 'v': 'χ', 'w': 'ψ', 'x': 'ω', 'y': '‡',
    'z': '†',
    'A': 'Alpha', 'B': 'ℬ', 'C': 'ℭ', 'D': 'mathcal{D}', 'E': 'ℰ',
    'F': 'ℱ', 'G': 'ℊ', 'H': 'ℋ', 'I': 'ℐ', 'J': '⍙',
    'K': '⍜', 'L': '⍛', 'M': '⍱', 'N': '⍲', 'O': '⍴',
    'P': '⍷', 'Q': '⍸', 'R': '⍺', 'S': '⎀', 'T': '⎁',
    'U': '⎂', 'V': '⎃', 'W': '⎄', 'X': '⎅', 'Y': '⎆',
    'Z': '⎇',
    '0': '⓪', '1': '①', '2': '②', '3': '③', '4': '④',
    '5': '⑤', '6': '⑥', '7': '⑦', '8': '⑧', '9': '⑨',
    ' ': '␣', '.': '•', ',': '·', '!': '¡', '?': '¿',
  };

  static final Map<String, String> _reversedEmojiMap =
  _emojiMap.map((key, value) => MapEntry(value, key));
  static final Map<String, String> _reversedSymbolMap =
  _symbolMap.map((key, value) => MapEntry(value, key));

  static String encrypt(String message, EncryptionMode mode) {
    if (message.isEmpty) return "Input cannot be empty.";
    final map = mode == EncryptionMode.emoji ? _emojiMap : _symbolMap;
    final buffer = StringBuffer();
    for (int i = 0; i < message.length; i++) {
      buffer.write(map[message[i]] ?? '❓');
      if (i < message.length - 1) buffer.write(_separator);
    }
    return buffer.toString();
  }

  static String decrypt(String encryptedMessage, EncryptionMode mode) {
    if (encryptedMessage.isEmpty) return "Input cannot be empty.";
    final reversedMap =
    mode == EncryptionMode.emoji ? _reversedEmojiMap : _reversedSymbolMap;
    final buffer = StringBuffer();
    final parts = encryptedMessage.split(_separator);
    for (final part in parts) {
      buffer.write(reversedMap[part] ?? '?');
    }
    return buffer.toString();
  }
}

// --- MAIN UI WIDGET ---


class SecretMessageEncrypter extends StatefulWidget {
  const SecretMessageEncrypter({super.key});

  @override
  State<SecretMessageEncrypter> createState() => _SecretMessageEncrypterState();
}

class _SecretMessageEncrypterState extends State<SecretMessageEncrypter> {
  final TextEditingController _textController = TextEditingController();
  String _resultText = '';
  EncryptionMode _selectedMode = EncryptionMode.emoji;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _encryptMessage(AppLocalizations local) {
    final String message = _textController.text;
    if (message.isEmpty) {
      _showSnackBar(local.enterMessageError);
      return;
    }
    setState(() {
      _resultText = EncryptionHelper.encrypt(message, _selectedMode);
    });
  }

  void _decryptMessage(AppLocalizations local) {
    final String message = _textController.text;
    if (message.isEmpty) {
      _showSnackBar(local.enterMessageError);
      return;
    }
    setState(() {
      _resultText = EncryptionHelper.decrypt(message, _selectedMode);
    });
  }

  void _copyToClipboard(AppLocalizations local) {
    if (_resultText.isEmpty || _resultText == local.resultPlaceholder) {
      _showSnackBar(local.noResultToCopy);
      return;
    }
    Clipboard.setData(ClipboardData(text: _resultText)).then((_) {
      _showSnackBar(local.resultCopied);
    });
  }

  void _showSnackBar(String message) {
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
    final fillColor = isDarkMode ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.9);

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
      labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      body: Stack(
        children: [
          const WhatsAppBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button + Title
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

                  // Message TextField
                  TextField(
                    controller: _textController,
                    decoration: _buildInputDecoration(
                        local.enterMessageLabel, Icons.message, isDarkMode),
                    maxLines: 5,
                    minLines: 3,
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown
                  DropdownButtonFormField<EncryptionMode>(
                    value: _selectedMode,
                    decoration: _buildInputDecoration(
                        local.encryptionModeLabel, Icons.style, isDarkMode),
                    dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
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
                        setState(() {
                          _selectedMode = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _encryptMessage(local),
                          icon: Icon(Icons.enhanced_encryption, color: textColor),
                          label: Text(local.encryptButton, style: TextStyle(color: textColor)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Colors.white10
                                : Colors.white.withOpacity(0.9),
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                          onPressed: () => _decryptMessage(local),
                          icon: Icon(Icons.no_encryption_gmailerrorred, color: textColor),
                          label: Text(local.decryptButton, style: TextStyle(color: textColor)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Colors.white10
                                : Colors.white.withOpacity(0.9),
                            padding: const EdgeInsets.symmetric(vertical: 12),
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

                  // Result Container
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
                        _resultText.isEmpty
                            ? local.resultPlaceholder
                            : _resultText,
                        style: TextStyle(
                          fontSize: 16,
                          color: _resultText.isEmpty
                              ? Colors.grey.shade400
                              : textColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Copy Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(local),
                      icon: Icon(Icons.copy_all_outlined, color: textColor),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

