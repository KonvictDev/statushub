import 'dart:io';
import 'package:flutter/material.dart';
import 'package:statushub/screens/permission_screen.dart';
import 'package:statushub/constants/app_colors.dart';
import '../service/status_service.dart';
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
      setState(() {
        allStatuses = current;
        savedStatuses = saved;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load statuses: $e')),
      );
    }
  }

  Future<void> _refreshStatuses() async {
    await _loadAllStatuses();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) {
      return PermissionScreen(
        onPermissionGranted: () async {
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
                            'Status Hub',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          // Action Icons with proper tap targets
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.whatshot, color: Colors.white),
                                onPressed: () {},
                                tooltip: 'Hot Status', // Accessibility hint
                              ),
                              IconButton(
                                icon: const Icon(Icons.workspace_premium_outlined, color: Colors.white),
                                onPressed: () {},
                                tooltip: 'Subscription',
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings, color: Colors.white),
                                onPressed: () {},
                                tooltip: 'Settings',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_rounded, size: 20),
                              SizedBox(width: 6),
                              Text('Home'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download_outlined, size: 20),
                              SizedBox(width: 6),
                              Text('Saved'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.extension_outlined, size: 20),
                              SizedBox(width: 6),
                              Text('Tools'),
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
