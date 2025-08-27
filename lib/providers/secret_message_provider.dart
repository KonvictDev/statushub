import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statushub/l10n/app_localizations.dart';

// --- ENCRYPTION/DECRYPTION LOGIC ---
enum EncryptionMode { emoji, symbol }

class EncryptionHelper {
  static const String _separator = '\u200B';

  static const Map<String, String> _emojiMap = {
    'a': '🔥', 'b': '💧', 'c': '🌍', 'd': '💨', 'e': '🌪️',
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
    'A': 'Alpha', 'B': 'ℬ', 'C': 'ℭ', 'D': 'mathcalD', 'E': 'ℰ',
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

// --- PROVIDER STATE & NOTIFIER ---
class SecretMessageState {
  final String message;
  final String result;
  final EncryptionMode mode;

  SecretMessageState({
    this.message = '',
    this.result = '',
    this.mode = EncryptionMode.emoji,
  });

  SecretMessageState copyWith({
    String? message,
    String? result,
    EncryptionMode? mode,
  }) {
    return SecretMessageState(
      message: message ?? this.message,
      result: result ?? this.result,
      mode: mode ?? this.mode,
    );
  }
}

class SecretMessageNotifier extends StateNotifier<SecretMessageState> {
  SecretMessageNotifier() : super(SecretMessageState());

  void setMessage(String message) {
    state = state.copyWith(message: message);
  }

  void setMode(EncryptionMode mode) {
    state = state.copyWith(mode: mode);
  }

  void encrypt(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    if (state.message.isEmpty) {
      state = state.copyWith(result: local.enterMessageError);
      return;
    }
    final encrypted = EncryptionHelper.encrypt(state.message, state.mode);
    state = state.copyWith(result: encrypted);
  }

  void decrypt(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    if (state.message.isEmpty) {
      state = state.copyWith(result: local.enterMessageError);
      return;
    }
    final decrypted = EncryptionHelper.decrypt(state.message, state.mode);
    state = state.copyWith(result: decrypted);
  }
}

final secretMessageProvider = StateNotifierProvider<SecretMessageNotifier, SecretMessageState>((ref) {
  return SecretMessageNotifier();
});