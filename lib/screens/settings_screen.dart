import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_strings.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../utils/cache_manager.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _cacheSizeMB = 0;
  bool _loading = true;
  final InAppReview _inAppReview = InAppReview.instance;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
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
        SnackBar(content: Text(AppLocalizations.of(context)!.cacheCleared)),
      );
    }
  }

  Future<void> _rateUs() async {
    if (await _inAppReview.isAvailable()) {
      _inAppReview.requestReview();
    } else {
      _inAppReview.openStoreListing(appStoreId: "com.example.app");
    }
  }

  void _shareApp() => Share.share(AppStrings.shareMessage);
  void _sendFeedback() => Share.share(AppStrings.feedbackMessage);
  void _openPrivacyPolicy() => Share.share(AppStrings.privacyUrl);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(loc.settings)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildHeader(loc.general),
          _buildCacheCard(loc),
          const SizedBox(height: 12),
          _buildHeader(loc.preferences),
          _buildThemeCard(loc, currentTheme),
          const SizedBox(height: 12),
          _buildLanguageCard(loc, currentLocale),
          const SizedBox(height: 12),
          _buildHeader(loc.about),
          _buildRateCard(loc),
          const SizedBox(height: 12),
          _buildShareCard(loc),
          const SizedBox(height: 12),
          _buildFeedbackCard(loc),
          const SizedBox(height: 12),
          _buildPrivacyPolicyCard(loc),
          const SizedBox(height: 12),
          _buildInfoCard(loc),
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

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }

  /// Generic reusable simple card for ListTile
  Widget _buildSimpleCard({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) =>
      _buildCard(
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon),
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
        ),
      );

  Widget _buildCacheCard(AppLocalizations loc) => _buildCard(
    child: ListTile(
      leading: const Icon(Icons.storage_rounded),
      title: Text(loc.cache),
      subtitle:
      _loading ? Text(loc.loading) : Text("$_cacheSizeMB ${loc.usedSuffix}"),
      trailing: FilledButton.icon(
        onPressed: _loading ? null : _clearCache,
        icon: const Icon(Icons.delete_sweep_rounded),
        label: Text(loc.clear),
      ),
    ),
  );

  Widget _buildThemeCard(AppLocalizations loc, ThemeMode currentTheme) =>
      _buildCard(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_6_rounded),
              title: Text(loc.theme),
              subtitle: Text(loc.chooseTheme),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 5, bottom: 12, right: 5),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_rounded),
                    label: Text(loc.light),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_rounded),
                    label: Text(loc.dark),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.phone_android_rounded),
                    label: Text(loc.system),
                  ),
                ],
                selected: {currentTheme},
                onSelectionChanged: (newSelection) {
                  ref.read(themeProvider.notifier).setTheme(newSelection.first);
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildLanguageCard(AppLocalizations loc, Locale currentLocale) =>
      _buildCard(
        child: ListTile(
          leading: const Icon(Icons.language_rounded),
          title: Text(loc.appLanguage),
          subtitle:
          Text(currentLocale.languageCode == "ta" ? "தமிழ்" : "English"),
          trailing: DropdownButton<String>(
            value: currentLocale.languageCode,
            onChanged: (value) {
              if (value != null) {
                ref.read(localeProvider.notifier).setLocale(value);
              }
            },
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
            ],
          ),
        ),
      );

  // Refactored cards using _buildSimpleCard
  Widget _buildRateCard(AppLocalizations loc) =>
      _buildSimpleCard(
        icon: Icons.star_rate_rounded,
        title: loc.rateUs,
        subtitle: loc.rateSubtitle,
        onTap: _rateUs,
      );

  Widget _buildShareCard(AppLocalizations loc) =>
      _buildSimpleCard(
        icon: Icons.share_rounded,
        title: loc.shareApp,
        subtitle: loc.shareSubtitle,
        onTap: _shareApp,
      );

  Widget _buildFeedbackCard(AppLocalizations loc) =>
      _buildSimpleCard(
        icon: Icons.feedback_rounded,
        title: loc.sendFeedback,
        subtitle: loc.feedbackSubtitle,
        onTap: _sendFeedback,
      );

  Widget _buildPrivacyPolicyCard(AppLocalizations loc) =>
      _buildSimpleCard(
        icon: Icons.privacy_tip_rounded,
        title: loc.privacyPolicy,
        subtitle: loc.privacySubtitle,
        onTap: _openPrivacyPolicy,
      );

  Widget _buildInfoCard(AppLocalizations loc) =>
      _buildSimpleCard(
        icon: Icons.info_outline_rounded,
        title: loc.appInfo,
        subtitle: loc.version,
      );
}
