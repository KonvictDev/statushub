import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:statushub/l10n/app_localizations.dart';
import 'package:statushub/providers/status_provider.dart';
import 'package:statushub/service/status_service.dart';
import 'package:statushub/service/whatsapp_service.dart';
import 'package:statushub/utils/grid_native_ad.dart';
import 'package:statushub/utils/native_ad_cache.dart';
import '../utils/ad_helper.dart';
import 'status_tile.dart';

class StatusTab extends ConsumerStatefulWidget {
  final bool isSaved;
  const StatusTab({super.key, required this.isSaved});

  @override
  ConsumerState<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends ConsumerState<StatusTab> with SingleTickerProviderStateMixin {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  // 🚀 SENIOR OPTIMIZATION: Unified Controller for all tile animations
  // This prevents creating 100+ separate tickers, which causes crashes.
  late AnimationController _gridController;

  @override
  void initState() {
    super.initState();
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );


    // 🚀 THE FIX: Trigger auto-load when the tab is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Small delay (500ms) to ensure the entry transition animation
      // finishes before we hit the disk I/O for 17+ files.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ref.read(statusProvider.notifier).loadStatuses();
        }
      });
    });
    // 💰 Initialize AdMob Banner
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
        onAdFailedToLoad: (ad, err) {
          debugPrint('Banner Ad failed: $err');
          ad.dispose();
        },
      ),
    )..load();

    // 💰 Pre-load Interstitial Ad for the "Save" reward action
    AdHelper.loadInterstitialAd();
  }

  bool _isAdIndex(int index) {
    // Every 4th item is ad
    return (index + 1) % 4 == 0;
  }

  int _realIndex(int index) {
    final adsBefore = (index + 1) ~/ 4;
    return index - adsBefore;
  }

  List<List<T>> _chunkList<T>(List<T> list, int size)
 {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(
          i,
          i + size > list.length ? list.length : i + size,
        ),
      );
    }
    return chunks;
  }



  @override
  void dispose() {
    NativeAdCache.disposeAll();
    _bannerAd?.dispose();
    _gridController.dispose();
    super.dispose();
  }

  void _showSwitchDialog(BuildContext context, WidgetRef ref, WhatsAppType currentApp) {
    final isBusiness = currentApp == WhatsAppType.business;
    final targetApp = isBusiness ? WhatsAppType.whatsapp : WhatsAppType.business;
    final targetName = isBusiness ? "Standard WhatsApp" : "WhatsApp Business";
    final targetColor = isBusiness ? Colors.green : Colors.teal;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Switch to $targetName?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: targetColor, foregroundColor: Colors.white),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              final notifier = ref.read(statusProvider.notifier);
              if (!await StatusService.hasPermission(targetApp)) {
                await StatusService.requestPermission(targetApp);
              }
              notifier.switchApp(targetApp);
            },
            child: const Text("Switch"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final filteredFiles = ref.watch(filteredStatusProvider(widget.isSaved));
    final statusState = ref.watch(statusProvider);
    final statusNotifier = ref.read(statusProvider.notifier);

    // Reset and play animation when the list content changes
    if (filteredFiles.isNotEmpty && !_gridController.isAnimating) {
      _gridController.forward(from: 0.0);
    }
    return RefreshIndicator(
      onRefresh: statusNotifier.loadStatuses,
      color: Colors.green,
      child: Column(
        children: [
          _buildTopControls(context, statusState, statusNotifier, local),

          Expanded(
            child: filteredFiles.isEmpty
                ? _buildEmptyState(
              context,
              local,
              widget.isSaved,
              statusState.currentApp,
            )
                : _buildGridWithAds(filteredFiles),
          ),

          // 💰 Banner Ad Placement
          if (_isBannerAdReady)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );

  }

  Widget _buildGridWithAds(List<FileSystemEntity> files)
 {
    final chunks = _chunkList(files, 4);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        for (int i = 0; i < chunks.length; i++) ...[
          // 🟩 STATUS GRID (2 columns)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final file = chunks[i][index];
                  return StatusTile(
                    key: ValueKey(file.path),
                    file: file,
                    isSaved: widget.isSaved,
                  );
                },
                childCount: chunks[i].length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
            ),
          ),

          // 🟨 FULL-WIDTH NATIVE AD
          if (i != chunks.length - 1)
            SliverToBoxAdapter(
              child: GridNativeAd(index: i),
            ),
        ],
      ],
    );
  }


  Widget _buildTopControls(BuildContext context, StatusState state, StatusNotifier notifier, AppLocalizations local) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _buildSortCapsule(state, notifier, local),
          const SizedBox(width: 12),
          if (!widget.isSaved) _buildAppSwitcher(state),
          const Spacer(),
          _buildFilterIcons(state, notifier),
        ],
      ),
    );
  }

  Widget _buildSortCapsule(StatusState state, StatusNotifier notifier, AppLocalizations local) {
    return PopupMenuButton<SortOrder>(
      onSelected: (order) {
        HapticFeedback.selectionClick();
        notifier.setSortOrder(order);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.sort_rounded, size: 16),
            const SizedBox(width: 6),
            Text(state.sortOrder == SortOrder.recent ? "Recent" : "Oldest",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(value: SortOrder.recent, child: Text("Recent")),
        const PopupMenuItem(value: SortOrder.oldest, child: Text("Oldest")),
      ],
    );
  }

  Widget _buildAppSwitcher(StatusState state) {
    final isBusiness = state.currentApp == WhatsAppType.business;
    return GestureDetector(
      onTap: () => _showSwitchDialog(context, ref, state.currentApp),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (isBusiness ? Colors.teal : Colors.green).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isBusiness ? Colors.teal : Colors.green).withOpacity(0.3)),
        ),
        child: Text(isBusiness ? "Business" : "WhatsApp",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isBusiness ? Colors.teal : Colors.green)),
      ),
    );
  }

  Widget _buildFilterIcons(StatusState state, StatusNotifier notifier) {
    return Row(
      children: MediaType.values.map((type) {
        final isSelected = state.selectedType == type;
        IconData icon;
        switch (type) {
          case MediaType.images: icon = Icons.image_rounded; break;
          case MediaType.videos: icon = Icons.videocam_rounded; break;
          default: icon = Icons.grid_view_rounded;
        }
        return IconButton(
          icon: Icon(icon, color: isSelected ? Colors.green : Colors.grey, size: 22),
          onPressed: () {
            HapticFeedback.lightImpact();
            notifier.setMediaType(type);
          },
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations local, bool isSaved, WhatsAppType app) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(local.noStatusesFound, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          if (!isSaved) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                WhatsAppService.openWhatsApp(context);
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text("Open WhatsApp"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ]
        ],
      ),
    );
  }
}