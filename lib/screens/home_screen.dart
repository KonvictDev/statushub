import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:statushub/screens/permission_screen.dart';
import 'package:statushub/constants/app_colors.dart';
import 'package:statushub/providers/status_provider.dart';
import 'package:statushub/utils/ad_blocker_detector.dart';
import 'package:statushub/utils/ad_helper.dart';
import '../l10n/app_localizations.dart';
import '../router/route_names.dart';
import '../service/status_service.dart';
import '../service/whatsapp_service.dart';
import '../widgets/disclaimer_box.dart';
import '../widgets/features_tab.dart';
import '../widgets/status_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasPermission = false;
  bool _isLoading = true;

  // 💰 Ad Variables
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdBlocked = false; // Track if user is blocking ads

  @override
  void initState() {
    super.initState();
    // Use PostFrameCallback to check permissions after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });

    // 💰 Try to load ad immediately to check for blockers
    _loadBannerAd();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await StatusService.hasRequiredPermissions();

    if (!mounted) return;
    setState(() {
      _hasPermission = hasPermission;
      _isLoading = false;
    });


  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _isAdBlocked = false; // Ad loaded, so no blocker!
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("Home Banner Failed: ${error.message}");
          ad.dispose();

          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              // 🚨 Check if it's a blocker error
              _isAdBlocked = AdBlockerDetector.isBlockerError(error);
            });

            // 🚨 Show Dialog (Once per session)
            if (_isAdBlocked) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AdBlockerDetector.showDetectionDialog(context);
              });
            }
          }
        },
      ),
    )..load();
  }


  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (!_hasPermission) {
      return PermissionScreen(
        onPermissionGranted: () {
          if (mounted) {
            setState(() => _hasPermission = true);
            // 🚀 Add this line to trigger the first scan immediately
            // after permission is granted
            ref.read(statusProvider.notifier).loadStatuses();
          }
        },
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            // --- HEADER SECTION ---
            Container(
              color: AppColors.primary,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            local.statusHub,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              // 🔄 Refresh Button
                              IconButton(
                                icon: const Icon(Icons.refresh, color: AppColors.white),
                                onPressed: () => ref.read(statusProvider.notifier).loadStatuses(),
                              ),
                              // 📱 WhatsApp Launcher
                              IconButton(
                                icon: Image.asset(
                                  'assets/icons/whatsapp.png',
                                  color: AppColors.white,
                                  width: 24,
                                  height: 24,
                                ),
                                onPressed: () => WhatsAppService.openWhatsApp(context),
                              ),
                              // ⚙️ Settings
                              IconButton(
                                icon: const Icon(Icons.settings, color: AppColors.white),
                                onPressed: () => GoRouter.of(context).pushNamed(RouteNames.settings),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      labelColor: AppColors.white,
                      unselectedLabelColor: AppColors.white70,
                      indicatorColor: AppColors.white,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: [
                        Tab(text: local.home, icon: const Icon(Icons.home_rounded, size: 20)),
                        Tab(text: local.saved, icon: const Icon(Icons.download_outlined, size: 20)),
                        Tab(text: local.tools, icon: const Icon(Icons.extension_outlined, size: 20)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // --- 🚨 AD BLOCKER BANNER (Persists if Blocked) ---
            if (_isAdBlocked)
              Container(
                width: double.infinity,
                color: Colors.orange.shade100,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.sentiment_dissatisfied, color: Colors.orange.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Ads help keep this app free. No worries though you can still use all features perfectly, even with your ad blocker on!",
                        style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // --- CONTENT SECTION ---
            Expanded(
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // Tab 1: Recent Statuses
                  _buildStatusView(isSaved: false),
                  // Tab 2: Saved Statuses
                  _buildStatusView(isSaved: true),
                  // Tab 3: Tools
                  const FeaturesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusView({required bool isSaved}) {
    return Column(
      children: [
        if (!isSaved) const DisclaimerBox(),
        Expanded(
          child: StatusTab(isSaved: isSaved),
        ),
      ],
    );
  }
}