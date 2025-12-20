import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:statushub/screens/permission_screen.dart';
import 'package:statushub/constants/app_colors.dart';
import 'package:statushub/providers/status_provider.dart';
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

  @override
  void initState() {
    super.initState();
    // Use PostFrameCallback to check permissions after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await StatusService.hasRequiredPermissions();

    if (!mounted) return;
    setState(() {
      _hasPermission = hasPermission;
      _isLoading = false;
    });

    // 🚀 SENIOR OPTIMIZATION:
    // Do NOT call loadStatuses() here.
    // Let the StatusTab handle its own loading with a delayed future
    // to avoid freezing the entry transition.
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