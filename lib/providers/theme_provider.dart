import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/app_settings.dart';

// --- Theme Notifier ---
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final savedTheme = await AppSettings.loadThemeMode();
    state = savedTheme;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    AppSettings.saveThemeMode(mode);
  }
}

// --- Theme Provider ---
final themeProvider =
StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());
