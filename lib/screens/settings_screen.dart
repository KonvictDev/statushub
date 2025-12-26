import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // ✅ Constants
  final String _packageName = "com.appsbyanandakumar.statushub";

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  // ✅ FIX: Use async I/O to prevent UI jank
  Future<void> _loadCacheSize() async {
    try {
      final dir = await CacheManager.instance.cacheDir;
      int totalBytes = 0;

      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            try {
              totalBytes += await entity.length();
            } catch (_) {}
          }
        }
      }

      if (mounted) {
        setState(() {
          _cacheSizeMB = (totalBytes / (1024 * 1024)).round();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clearCache() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    await CacheManager.instance.clearCache();
    await _loadCacheSize();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cacheCleared ?? "Cache Cleared"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _rateUs() async {
    // Note: This popup only shows if app is installed via Play Store.
    // In debug mode, it may do nothing or show logs, which is normal.
    if (await _inAppReview.isAvailable()) {
      _inAppReview.requestReview();
    } else {
      // Fallback to opening the store page directly
      _inAppReview.openStoreListing(appStoreId: _packageName);
    }
  }

  // ✅ FIX: Explicitly constructed the correct Play Store URL
  void _shareApp() {
    final loc = AppLocalizations.of(context)!;

    // Construct the live URL dynamically
    final url = "https://play.google.com/store/apps/details?id=$_packageName";

    // You can customize the text here
    final message = "📱 Download StatusHub to save WhatsApp Statuses, Recover Messages & more!\n\n✨ Get it here: $url";

    Share.share(message);
  }

  Future<void> _sendFeedback() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'appsbyanandakumar@gmail.com',
      query: 'subject=Feedback for StatusHub&body=Hi, I have some feedback regarding your app...',
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client.')),
        );
      }
    }
  }

  Future<void> _openPrivacyPolicy() async {
    // ✅ Check this URL - ensured no typos
    final url = Uri.parse('https://konvictdev.github.io/status_hub_privacy/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final sectionColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(loc.settings, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          physics: const BouncingScrollPhysics(),
          children: [

            // --- 1. GENERAL ---
            _AnimatedSection(
              delay: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(loc.general),
                  _buildSettingsGroup(
                    color: sectionColor,
                    children: [
                      _buildTile(
                        icon: Icons.cleaning_services_rounded,
                        iconColor: Colors.orange,
                        title: loc.cache ?? "Cache",
                        subtitle: _loading ? "Loading..." : "$_cacheSizeMB MB used",
                        trailing: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : TextButton(
                          onPressed: _clearCache,
                          child: Text(loc.clear ?? "Clear", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 2. APPEARANCE ---
            _AnimatedSection(
              delay: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(loc.preferences ?? "Preferences"),
                  _buildSettingsGroup(
                    color: sectionColor,
                    children: [
                      // Theme
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildIconContainer(Icons.brightness_6_rounded, Colors.purple),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(loc.textTheme ?? "Theme", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<ThemeMode>(
                                segments: const [
                                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 18), label: Text('Light')),
                                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 18), label: Text('Dark')),
                                  ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.phone_android_rounded, size: 18), label: Text('Auto')),
                                ],
                                selected: {currentTheme},
                                onSelectionChanged: (newSelection) {
                                  HapticFeedback.selectionClick();
                                  ref.read(themeProvider.notifier).setTheme(newSelection.first);
                                },
                                style: ButtonStyle(
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildDivider(),
                      // Language
                      _buildTile(
                        icon: Icons.language_rounded,
                        iconColor: Colors.blue,
                        title: "Language", // Use loc.language if available
                        subtitle: _getLanguageName(currentLocale.languageCode),
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentLocale.languageCode,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500),
                            onChanged: (value) {
                              if (value != null) ref.read(localeProvider.notifier).setLocale(value);
                            },
                            items: [
                              _buildDropdownItem('en', 'English'),
                              _buildDropdownItem('ta', 'தமிழ்'),
                              _buildDropdownItem('ml', 'മലയാളം'),
                              _buildDropdownItem('te', 'తెలుగు'),
                              _buildDropdownItem('kn', 'ಕన్నడ'),
                              _buildDropdownItem('hi', 'हिन्दी'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 3. SUPPORT ---
            _AnimatedSection(
              delay: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(loc.about),
                  _buildSettingsGroup(
                    color: sectionColor,
                    children: [
                      _buildTile(
                        icon: Icons.star_rate_rounded,
                        iconColor: Colors.amber,
                        title: "Rate Us",
                        subtitle: "Rate us on Play Store",
                        onTap: _rateUs,
                        showArrow: true,
                      ),
                      _buildDivider(),
                      _buildTile(
                        icon: Icons.share_rounded,
                        iconColor: Colors.green,
                        title: loc.share ?? "Share",
                        subtitle: "Share app with friends",
                        onTap: _shareApp,
                        showArrow: true,
                      ),
                      _buildDivider(),
                      _buildTile(
                        icon: Icons.feedback_rounded,
                        iconColor: Colors.teal,
                        title: "Send Feedback",
                        subtitle: "Contact us via email",
                        onTap: _sendFeedback,
                        showArrow: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 4. LEGAL ---
            _AnimatedSection(
              delay: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader("Legal"),
                  _buildSettingsGroup(
                    color: sectionColor,
                    children: [
                      _buildTile(
                        icon: Icons.privacy_tip_rounded,
                        iconColor: Colors.grey,
                        title: "Privacy Policy",
                        onTap: _openPrivacyPolicy,
                        showArrow: true,
                      ),
                      _buildDivider(),
                      _buildTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: Colors.blueGrey,
                        title: "App Info",
                        subtitle: "v1.0.0",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- FOOTER ---
            _AnimatedSection(
              delay: 4,
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.favorite_rounded, size: 16, color: Colors.red.withOpacity(0.6)),
                    const SizedBox(height: 4),
                    Text(
                      "Made in India",
                      style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({required Color color, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap();
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildIconContainer(icon, iconColor),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey))
          : null,
      trailing: trailing ?? (showArrow
          ? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey)
          : null),
    );
  }

  Widget _buildIconContainer(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 60, endIndent: 0, color: Colors.black12);
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ta': return "தமிழ்";
      case 'ml': return "മലയാളം";
      case 'te': return "తెలుగు";
      case 'kn': return "ಕన్నడ";
      case 'hi': return "हिन्दी";
      default: return "English";
    }
  }

  DropdownMenuItem<String> _buildDropdownItem(String value, String label) {
    return DropdownMenuItem(value: value, child: Text(label));
  }
}

// 🚀 CUSTOM ANIMATION WRAPPER
class _AnimatedSection extends StatefulWidget {
  final Widget child;
  final int delay; // 0, 1, 2... for staggering
  const _AnimatedSection({required this.child, required this.delay});

  @override
  State<_AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<_AnimatedSection> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: widget.delay * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}