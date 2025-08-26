import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../widgets/status_tile.dart';
import 'package:statushub/constants/app_colors.dart';
import '../l10n/app_localizations.dart';

enum MediaType { all, images, videos }
enum SortOrder { recent, oldest }

class StatusTab extends StatefulWidget {
  final List<FileSystemEntity> files;
  final bool isSaved;
  final Future<void> Function() onRefresh;

  const StatusTab({
    super.key,
    required this.files,
    required this.isSaved,
    required this.onRefresh,
  });

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  MediaType _selectedType = MediaType.all;
  SortOrder _sortOrder = SortOrder.recent;

  final Map<String, DateTime> _fileModifiedCache = {};

  List<FileSystemEntity> get filteredFiles {
    final filtered = widget.files.where((file) {
      final path = file.path.toLowerCase();
      final isImage = _isImage(path);
      final isVideo = _isVideo(path);

      switch (_selectedType) {
        case MediaType.images:
          return isImage;
        case MediaType.videos:
          return isVideo;
        case MediaType.all:
          return isImage || isVideo;
      }
    }).toList();

    filtered.sort((a, b) {
      final aTime = _getModifiedTime(a);
      final bTime = _getModifiedTime(b);
      return _sortOrder == SortOrder.recent
          ? bTime.compareTo(aTime)
          : aTime.compareTo(bTime);
    });

    return filtered;
  }

  DateTime _getModifiedTime(FileSystemEntity file) {
    return _fileModifiedCache.putIfAbsent(
      file.path,
          () => file.statSync().modified,
    );
  }

  bool _isImage(String path) {
    final ext = p.extension(path);
    return const {'.jpg', '.jpeg', '.png', '.webp'}.contains(ext.toLowerCase());
  }

  bool _isVideo(String path) {
    final ext = p.extension(path);
    return const {'.mp4', '.mov', '.mkv', '.avi', '.3gp'}
        .contains(ext.toLowerCase());
  }

  String _sortLabel(AppLocalizations local) =>
      _sortOrder == SortOrder.recent ? local.sortRecent : local.sortOldest;

  @override
  Widget build(BuildContext context) {
    final files = filteredFiles;
    final local = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Column(
        children: [
          const SizedBox(height: 8),

          /// 🔽 Top filter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // 📌 Sort Button
                PopupMenuButton<SortOrder>(
                  onSelected: (selected) {
                    setState(() => _sortOrder = selected);
                  },
                  color: AppColors.sortMenuBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: SortOrder.recent,
                      child: Text(local.sortRecent,
                          style: const TextStyle(color: AppColors.sortText)),
                    ),
                    PopupMenuItem(
                      value: SortOrder.oldest,
                      child: Text(local.sortOldest,
                          style: const TextStyle(color: AppColors.sortText)),
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
                        Text(_sortLabel(local),
                            style: const TextStyle(color: AppColors.sortText)),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down, color: AppColors.sortText),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 🎞 Media Type Chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: MediaType.values.map((type) {
                        // Use localization instead of hardcoded names
                        String label;
                        final local = AppLocalizations.of(context)!;
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

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: _selectedType == type,
                            onSelected: (_) => setState(() => _selectedType = type),
                            selectedColor: AppColors.chipSelected,
                            checkmarkColor: AppColors.chipCheckmark,
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              ],
            ),
          ),

          const SizedBox(height: 8),

          /// 📁 Grid of Status Files
          Expanded(
            child: files.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_off, size: 60, color: AppColors.emptyIcon),
                  const SizedBox(height: 20),
                  Text(local.noStatusesFound,
                      style: const TextStyle(fontSize: 18)),
                  Text(
                    local.noStatusesHint,
                    style: const TextStyle(fontSize: 14, color: AppColors.emptyText),
                  ),
                ],
              ),
            )
                : GridView.builder(
              key: ValueKey('$_selectedType-$_sortOrder'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: files.length,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final file = files[index];
                return StatusTile(
                  key: ValueKey(file.path),
                  file: file,
                  isSaved: widget.isSaved,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
