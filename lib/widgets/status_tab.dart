import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statushub/l10n/app_localizations.dart';
import 'package:statushub/providers/status_provider.dart';
import '../constants/app_colors.dart';
import 'status_tile.dart';

class StatusTab extends ConsumerWidget {
  final bool isSaved;
  const StatusTab({super.key, required this.isSaved});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = AppLocalizations.of(context)!;
    final filteredFiles = ref.watch(filteredStatusProvider(isSaved));
    final statusState = ref.watch(statusProvider);
    final statusNotifier = ref.read(statusProvider.notifier);

    String _sortLabel() {
      switch (statusState.sortOrder) {
        case SortOrder.recent:
          return local.sortRecent;
        case SortOrder.oldest:
          return local.sortOldest;
      }
    }

    return RefreshIndicator(
      onRefresh: statusNotifier.loadStatuses,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                PopupMenuButton<SortOrder>(
                  onSelected: statusNotifier.setSortOrder,
                  color: AppColors.sortMenuBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: SortOrder.recent,
                      child: Text(local.sortRecent, style: const TextStyle(color: AppColors.sortText)),
                    ),
                    PopupMenuItem(
                      value: SortOrder.oldest,
                      child: Text(local.sortOldest, style: const TextStyle(color: AppColors.sortText)),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.sortMenuBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(_sortLabel(), style: const TextStyle(color: AppColors.sortText)),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down, color: AppColors.sortText),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: MediaType.values.map((type) {
                        String label;
                        switch (type) {
                          case MediaType.all:
                            label = local.all;
                            break;
                          case MediaType.images:
                            label = local.images;
                            break;
                          case MediaType.videos:
                            label = local.videos;
                            break;
                        }
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              label,
                              style: TextStyle(
                                color: statusState.selectedType == type ? Colors.black87 : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                            selected: statusState.selectedType == type,
                            onSelected: (_) => statusNotifier.setMediaType(type),
                            selectedColor: AppColors.chipSelected,
                            checkmarkColor: AppColors.chipCheckmark,
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredFiles.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_off, size: 60, color: AppColors.emptyIcon),
                  const SizedBox(height: 20),
                  Text(local.noStatusesFound, style: const TextStyle(fontSize: 18)),
                  Text(
                    local.noStatusesHint,
                    style: const TextStyle(fontSize: 14, color: AppColors.emptyText),
                  ),
                ],
              ),
            )
                : GridView.builder(
              key: ValueKey('${statusState.selectedType}-${statusState.sortOrder}'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: filteredFiles.length,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final file = filteredFiles[index];
                return StatusTile(
                  key: ValueKey(file.path),
                  file: file,
                  isSaved: isSaved,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}