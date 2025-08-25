import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../widgets/status_tile.dart';

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

  /// Cached file stats to avoid repeated statSync calls
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

  /// Cache file modified time to avoid expensive I/O
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

  String get _sortLabel =>
      _sortOrder == SortOrder.recent ? 'Recent' : 'Oldest';

  @override
  Widget build(BuildContext context) {
    final files = filteredFiles;

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
                  color: Colors.green.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: SortOrder.recent,
                      child: Text('Recent', style: TextStyle(color: Colors.black)),
                    ),
                    PopupMenuItem(
                      value: SortOrder.oldest,
                      child: Text('Oldest', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.green.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(_sortLabel, style: const TextStyle(color: Colors.black)),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down, color: Colors.black),
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
                        final label =
                            type.name[0].toUpperCase() + type.name.substring(1);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: _selectedType == type,
                            onSelected: (_) =>
                                setState(() => _selectedType = type),
                            selectedColor: Colors.green.shade100,
                            checkmarkColor: Colors.green,
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
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off, size: 60, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('No statuses found',
                      style: TextStyle(fontSize: 18)),
                  Text(
                    'Make sure you have viewed or saved statuses',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
                : GridView.builder(
              key: ValueKey('$_selectedType-$_sortOrder'),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              itemCount: files.length,
              physics: const BouncingScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final file = files[index];

                // ✅ StatusTile should internally cache thumbnails
                return StatusTile(
                  key: ValueKey(file.path), // helps Flutter skip rebuilds
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
