import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statushub/service/app_settings.dart';

// 1. The Notifier class
class LocaleNotifier extends StateNotifier<Locale> {
  // Initialize with a default locale. The UI will use this until the saved locale is loaded.
  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLocale() async {
    final langCode = await AppSettings.loadLanguage();
    state = Locale(langCode);
  }

  // Method to change and save the language
  void setLocale(String langCode) {
    // Only update if the language is actually different
    if (state.languageCode != langCode) {
      state = Locale(langCode);
      AppSettings.saveLanguage(langCode);
    }
  }
}

// 2. The Provider
// This is a global provider that will create and expose our LocaleNotifier.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});