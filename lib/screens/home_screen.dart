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

    if (hasPermission) {
      ref.read(statusProvider.notifier).loadStatuses();
    }
  }

  Future<void> _refreshStatuses() async {
    await ref.read(statusProvider.notifier).loadStatuses();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) {
      return PermissionScreen(
        onPermissionGranted: () async {
          if (!mounted) return;
          setState(() => _hasPermission = true);
          await ref.read(statusProvider.notifier).loadStatuses();
        },
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
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
                          // App Title
                          Text(
                            local.statusHub,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          // Action Icons
                          // Action Icons
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.refresh, color: AppColors.white),
                                tooltip: "refresh", // Make sure you add "refresh" in your localization
                                onPressed: () async {
                                  await _refreshStatuses();
                                },
                              ),
                              IconButton(
                                icon: Image.asset(
                                  'assets/icons/whatsapp.png',
                                  color: AppColors.white,
                                  width: 24,
                                  height: 24,
                                ),
                                tooltip: local.hotStatus,
                                onPressed: () => WhatsAppService.openWhatsApp(context),
                              ),
                              // 🔄 Refresh Button

                              IconButton(
                                icon: const Icon(Icons.settings, color: AppColors.white),
                                tooltip: local.settings,
                                onPressed: () {
                                  GoRouter.of(context).pushNamed(RouteNames.settings);
                                },
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
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.home_rounded, size: 20),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  local.home,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.download_outlined, size: 20),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  local.saved,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.extension_outlined, size: 20),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  local.tools,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Column(
                    children: [
                      const DisclaimerBox(), // 👈 MOVED WIDGET HERE
                      Expanded(
                        child: StatusTab(
                          isSaved: false,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                     // 👈 MOVED WIDGET HERE
                      Expanded(
                        child: StatusTab(
                          isSaved: true,
                        ),
                      ),
                    ],
                  ),
                  const FeaturesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
