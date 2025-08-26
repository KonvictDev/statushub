import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:statushub/screens/permission_screen.dart';
import 'package:statushub/constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../router/route_names.dart';
import '../service/status_service.dart';
import '../service/whatsapp_service.dart';
import '../widgets/features_tab.dart';
import '../widgets/status_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPermission = false;
  bool _isLoading = true;

  List<FileSystemEntity> allStatuses = [];
  List<FileSystemEntity> savedStatuses = [];

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
      await _loadAllStatuses();
    }
  }

  Future<void> _loadAllStatuses() async {
    try {
      final current = await StatusService.getStatuses();
      final saved = await StatusService.getSavedStatuses();
      if (!mounted) return;
      setState(() {
        allStatuses = current;
        savedStatuses = saved;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.failedToLoadStatuses} $e'),
        ),
      );
    }
  }

  Future<void> _refreshStatuses() async {
    await _loadAllStatuses();
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
          await _loadAllStatuses();
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
                          Row(
                            children: [
                              IconButton(
                                icon: Image.asset(
                                  'assets/icons/membership.png', // path to your icon in the icons folder
                                  // optional, only works for PNGs with transparency
                                  width: 24,                                 // adjust size
                                  height: 24,
                                ),
                                tooltip: local.subscription,
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: Image.asset(
                                  'assets/icons/whatsapp.png', // path to your icon in the icons folder
                                  color: AppColors.white,       // optional, only works for certain formats like PNG with transparency
                                  width: 24,                     // adjust size
                                  height: 24,
                                ),
                                tooltip: local.hotStatus,
                                onPressed: () => WhatsAppService.openWhatsApp(context),
                              ),



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
                  StatusTab(
                    files: allStatuses,
                    isSaved: false,
                    onRefresh: _refreshStatuses,
                  ),
                  StatusTab(
                    files: savedStatuses,
                    isSaved: true,
                    onRefresh: _refreshStatuses,
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