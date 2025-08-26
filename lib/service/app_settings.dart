import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const _keyTheme = "theme_mode";
  static const _keyLang = "language";

  /// 🔹 Save theme mode as String ("ThemeMode.light", etc.)
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, mode.toString());
  }

  /// 🔹 Load theme mode (auto-migrate old int values)
  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.get(_keyTheme);

    if (value is int) {
      // Old version stored ThemeMode index as int → migrate to string
      final theme = ThemeMode.values[value.clamp(0, ThemeMode.values.length - 1)];
      await prefs.setString(_keyTheme, theme.toString());
      return theme;
    } else if (value is String) {
      switch (value) {
        case "ThemeMode.light":
          return ThemeMode.light;
        case "ThemeMode.dark":
          return ThemeMode.dark;
        case "ThemeMode.system":
        default:
          return ThemeMode.system;
      }
    } else {
      return ThemeMode.system; // default if nothing stored
    }
  }

  /// 🔹 Save language code ("en", "ta")
  static Future<void> saveLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLang, langCode);
  }

  /// 🔹 Load language code (defaults to "en")
  static Future<String> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLang) ?? "en";
  }
}
