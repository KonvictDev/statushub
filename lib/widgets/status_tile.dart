import 'dart:io';
import 'dart:typed_data' as typed;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/media_actions.dart';
import '../utils/media_utils.dart';
import '../providers/thumbnail_provider.dart';
import 'bottom_sheet/image_preview_bottom_sheet.dart';
import 'bottom_sheet/video_preview_bottom_sheet.dart';

class StatusTile extends ConsumerWidget {
  final FileSystemEntity file;
  final bool isSaved;

  const StatusTile({
    super.key,
    required this.file,
    required this.isSaved,
  });

  Future<void> _openViewer(BuildContext context, typed.Uint8List? thumbnail) async {
    HapticFeedback.lightImpact();
    final isVideo = MediaUtils.isVideoFile(file.path);

    if (isVideo) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          expand: false,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: VideoPreviewBottomSheet(
                file: File(file.path),
                thumbnail: thumbnail,
                scrollController: scrollController,
                isSaved: isSaved,
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
        builder: (_) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ImageViewerBottomSheet(
            file: File(file.path),
            isSaved: isSaved,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVideo = MediaUtils.isVideoFile(file.path);
    final mediaMetadata = ref.watch(mediaMetadataProvider(file));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _openViewer(context, mediaMetadata.value?.thumbnail),
      child: Hero(
        tag: file.path,
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.black26,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media content
              if (isVideo)
                mediaMetadata.when(
                  data: (metadata) => metadata.thumbnail != null
                      ? Image.memory(
                    metadata.thumbnail!,
                    fit: BoxFit.cover,
                  )
                      : const Center(child: Icon(Icons.error, size: 40)),
                  loading: () => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.grey[300]),
                  ),
                  error: (_, __) => const Center(child: Icon(Icons.error, size: 40)),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.error, size: 40)),
                  ),
                ),
              // Overlay and other UI elements
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              if (isVideo) ...[
                Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 32,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: mediaMetadata.when(
                    data: (metadata) => metadata.duration != null
                        ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        metadata.duration!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ],
              Positioned(
                bottom: 12,
                right: 12,
                child: IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? theme.colorScheme.surfaceVariant.withOpacity(0.7)
                        : theme.colorScheme.primaryContainer.withOpacity(0.8),
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(10),
                    shadowColor: Colors.black26,
                  ),
                  icon: Icon(
                    isSaved ? Icons.share_rounded : Icons.save_alt_rounded,
                    size: 22,
                  ),
                  onPressed: isSaved
                      ? MediaActions(context, File(file.path), isVideo: isVideo).share
                      : () async {
                    final actions = MediaActions(context, File(file.path), isVideo: isVideo);
                    await actions.save();
                  },
                  tooltip: isSaved ? 'Share' : 'Save to gallery',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}