import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';

import '../service/app_settings.dart';
import '../utils/cache_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _cacheSizeMB = 0;
  bool _loading = true;

  ThemeMode _themeMode = ThemeMode.system;
  String _selectedLanguage = "English";

  final InAppReview _inAppReview = InAppReview.instance;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
    _loadSettings();
  }

  Future<void> _loadCacheSize() async {
    final size = await _calculateCacheSize();
    if (mounted) {
      setState(() {
        _cacheSizeMB = size;
        _loading = false;
      });
    }
  }

  Future<int> _calculateCacheSize() async {
    final dir = await CacheManager.instance.cacheDir;
    int totalBytes = 0;
    if (dir.existsSync()) {
      for (final f in dir.listSync(recursive: true)) {
        if (f is File) {
          totalBytes += await f.length();
        }
      }
    }
    return (totalBytes / (1024 * 1024)).ceil();
  }

  Future<void> _clearCache() async {
    setState(() => _loading = true);
    await CacheManager.instance.clearCache();
    await _loadCacheSize();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cache cleared ✅")),
      );
    }
  }

  Future<void> _loadSettings() async {
    final theme = await AppSettings.loadThemeMode();
    final lang = await AppSettings.loadLanguage();
    if (mounted) {
      setState(() {
        _themeMode = theme;
        _selectedLanguage = lang;
      });
    }
  }

  void _changeThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    AppSettings.saveThemeMode(mode);
  }

  void _changeLanguage(String lang) {
    setState(() => _selectedLanguage = lang);
    AppSettings.saveLanguage(lang);
  }

  Future<void> _rateUs() async {
    if (await _inAppReview.isAvailable()) {
      _inAppReview.requestReview();
    } else {
      _inAppReview.openStoreListing(appStoreId: "com.example.app");
    }
  }

  void _shareApp() {
    Share.share(
      "Check out this awesome app: https://play.google.com/store/apps/details?id=com.example.app",
    );
  }

  void _sendFeedback() {
    // Example: open email client
    // You could also integrate a feedback form
    Share.share("Feedback: Please contact us at support@example.com");
  }

  void _openPrivacyPolicy() {
    // Replace with Navigator.push(WebView...) or url_launcher
    Share.share("View our privacy policy: https://example.com/privacy");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildHeader("General"),
          _buildCacheCard(),

          const SizedBox(height: 12),

          _buildHeader("Preferences"),
          _buildThemeCard(),
          const SizedBox(height: 12),
          _buildLanguageCard(),

          const SizedBox(height: 12),

          _buildHeader("About"),
          _buildRateCard(),
          const SizedBox(height: 12),
          _buildShareCard(),
          const SizedBox(height: 12),
          _buildFeedbackCard(),
          const SizedBox(height: 12),
          _buildPrivacyPolicyCard(),
          const SizedBox(height: 12),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCacheCard() => _buildCard(
    child: ListTile(
      leading: const Icon(Icons.storage_rounded),
      title: const Text("Cache"),
      subtitle: _loading
          ? const Text("Loading...")
          : Text("$_cacheSizeMB MB used"),
      trailing: FilledButton.icon(
        onPressed: _loading ? null : _clearCache,
        icon: const Icon(Icons.delete_sweep_rounded),
        label: const Text("Clear"),
      ),
    ),
  );

  Widget _buildThemeCard() => _buildCard(
    child: Column(
      children: [
        const ListTile(
          leading: Icon(Icons.brightness_6_rounded),
          title: Text("Theme"),
          subtitle: Text("Choose light, dark, or system mode"),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 12, right: 5),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded),
                label: Text("Light"),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded),
                label: Text("Dark"),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.phone_android_rounded),
                label: Text("System"),
              ),
            ],
            selected: {_themeMode},
            onSelectionChanged: (newSelection) {
              _changeThemeMode(newSelection.first);
            },
          ),
        ),
      ],
    ),
  );

  Widget _buildLanguageCard() => _buildCard(
    child: ListTile(
      leading: const Icon(Icons.language_rounded),
      title: const Text("App Language"),
      subtitle: Text(_selectedLanguage),
      trailing: DropdownButton<String>(
        value: _selectedLanguage,
        onChanged: (value) {
          if (value != null) _changeLanguage(value);
        },
        items: const [
          DropdownMenuItem(value: "English", child: Text("English")),
          DropdownMenuItem(value: "Español", child: Text("Español")),
          DropdownMenuItem(value: "Français", child: Text("Français")),
          DropdownMenuItem(value: "Deutsch", child: Text("Deutsch")),
        ],
      ),
    ),
  );

  Widget _buildRateCard() => _buildCard(
    child: ListTile(
      leading: const Icon(Icons.star_rate_rounded),
      title: const Text("Rate Us"),
      subtitle: const Text("Love the app? Leave a review!"),
      onTap: _rateUs,
    ),
  );

  Widget _buildShareCard() => _buildCard(
    child: ListTile(
      leading: const Icon(Icons.share_rounded),
      title: const Text("Share App"),
      subtitle: const Text("Tell your friends about us"),
      onTap: _shareApp,
    ),
  );

  Widget _buildFeedbackCard() => _buildCard(
    child: ListTile(
      leading: const Icon(Icons.feedback_rounded),
      title: const Text("Send Feedback"),
      subtitle: const Text("Let us know your thoughts"),
      onTap: _sendFeedback,
    ),
  );

  Widget _buildPrivacyPolicyCard() => _buildCard(
    child: ListTile(
      leading: const Icon(Icons.privacy_tip_rounded),
      title: const Text("Privacy Policy"),
      subtitle: const Text("Read how we handle your data"),
      onTap: _openPrivacyPolicy,
    ),
  );

  Widget _buildInfoCard() => _buildCard(
    child: const ListTile(
      leading: Icon(Icons.info_outline_rounded),
      title: Text("App Info"),
      subtitle: Text("Version 1.0.0"),
    ),
  );

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
