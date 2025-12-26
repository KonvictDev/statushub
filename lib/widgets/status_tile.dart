import 'dart:io';
import 'dart:typed_data' as typed;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:statushub/utils/ad_helper.dart';
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
    const barrierColor = Colors.black45;

    if (isVideo) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: barrierColor,
        builder: (_) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 1.0,
            expand: false,
            builder: (context, scrollController) {
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: VideoPreviewBottomSheet(
                  file: File(file.path),
                  thumbnail: thumbnail,
                  scrollController: scrollController,
                  isSaved: isSaved,
                ),
              );
            },
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: barrierColor,
        builder: (_) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: ImageViewerBottomSheet(
              file: File(file.path),
              isSaved: isSaved,
            ),
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

    // ✅ FIX: Unique Hero Tag to prevent "There are multiple heroes..." error
    final heroTag = "${file.path}_${isSaved ? 'saved' : 'recent'}";

    return GestureDetector(
      onTap: () => _openViewer(context, mediaMetadata.value?.thumbnail),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: heroTag, // ✅ Used unique tag here
              child: isVideo
                  ? mediaMetadata.when(
                data: (metadata) => metadata.thumbnail != null
                    ? Image.memory(metadata.thumbnail!, fit: BoxFit.cover)
                    : Container(color: Colors.black87),
                loading: () => Shimmer.fromColors(
                  baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                error: (_, __) => Container(color: Colors.black87),
              )
                  : Image.file(
                File(file.path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                  ),
                ),
              ),
            ),

            if (isVideo) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 30, color: Colors.black87),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: mediaMetadata.when(
                  data: (meta) => meta.duration != null
                      ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                    child: Text(meta.duration!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ],

            Positioned(
              bottom: 8,
              right: 8,
              child: IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.white10 : Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.all(8),
                ),
                icon: Icon(
                  isSaved ? Icons.share_rounded : Icons.save_alt_rounded,
                  size: 20,
                  color: isDark ? Colors.white : theme.colorScheme.primary,
                ),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final actions = MediaActions(context, File(file.path), isVideo: isVideo);

                  if (isSaved) {
                    await actions.share();
                  } else {
                    await actions.save();
                    AdHelper.showInterstitialAd(onComplete: () {
                      debugPrint("Post-Save Ad Dismissed");
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}