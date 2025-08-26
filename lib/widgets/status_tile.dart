import 'dart:io';
import 'dart:typed_data' as typed;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:statushub/constants/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import '../utils/cache_manager.dart';
import '../utils/media_utils.dart';
import 'bottom_sheet/image_preview_bottom_sheet.dart';
import 'bottom_sheet/video_preview_bottom_sheet.dart';

class StatusTile extends StatefulWidget {
  final FileSystemEntity file;
  final bool isSaved;

  const StatusTile({
    super.key,
    required this.file,
    required this.isSaved,
  });

  @override
  State<StatusTile> createState() => _StatusTileState();
}

class _StatusTileState extends State<StatusTile>
    with AutomaticKeepAliveClientMixin {
  // ... (existing code for caching, initState, etc. remains the same)
  static final Map<String, typed.Uint8List> _thumbnailCache = {};
  static final Map<String, String> _durationCache = {};

  late final File mediaFile = File(widget.file.path);
  late final bool isVideo = MediaUtils.isVideoFile(widget.file.path);

  typed.Uint8List? _thumbnail;
  String? _duration;

  @override
  void initState() {
    super.initState();
    if (isVideo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadThumbnail();
        _loadDuration();
      });
    }
  }



  Future<void> _loadThumbnail() async {
    if (_thumbnailCache.containsKey(mediaFile.path)) {
      setState(() => _thumbnail = _thumbnailCache[mediaFile.path]);
      return;
    }

    final cacheDir = await CacheManager.instance.cacheDir;
    final thumbPath =
        '${cacheDir.path}/${mediaFile.path.hashCode}_thumb.jpg';

    if (File(thumbPath).existsSync()) {
      final data = await File(thumbPath).readAsBytes();
      _thumbnailCache[mediaFile.path] = data;
      if (mounted) setState(() => _thumbnail = data);
      return;
    }

    try {
      final thumb = await VideoThumbnail.thumbnailData(
        video: mediaFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200,
        quality: 60,
      );
      if (thumb != null) {
        File(thumbPath).writeAsBytesSync(thumb);
        _thumbnailCache[mediaFile.path] = thumb;
        if (mounted) setState(() => _thumbnail = thumb);
      }
    } catch (_) {}
  }

  Future<void> _loadDuration() async {
    if (_durationCache.containsKey(mediaFile.path)) {
      setState(() => _duration = _durationCache[mediaFile.path]);
      return;
    }

    final cacheDir = await CacheManager.instance.cacheDir;
    final durationPath =
        '${cacheDir.path}/${mediaFile.path.hashCode}_duration.json';

    if (File(durationPath).existsSync()) {
      final stored = await File(durationPath).readAsString();
      _durationCache[mediaFile.path] = stored;
      if (mounted) setState(() => _duration = stored);
      return;
    }

    final controller = VideoPlayerController.file(mediaFile);
    try {
      await controller.initialize();
      final duration = controller.value.duration;
      final formatted = _formatDuration(duration);

      File(durationPath).writeAsStringSync(formatted);
      _durationCache[mediaFile.path] = formatted;
      if (mounted) setState(() => _duration = formatted);
    } catch (_) {
      // ignore
    } finally {
      await controller.dispose();
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    final hours = d.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }


  Future<void> _save(BuildContext context) async {
    try {
      final saved = await MediaUtils.saveToGallery(mediaFile, isVideo: isVideo);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to: ${saved.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ✨ CHANGED: Added a share function
  Future<void> _share() async {
    try {
      await Share.shareXFiles(
        [XFile(mediaFile.path)],
        text: 'Shared from StatusHub!', // Optional: Add your app details
      );
    } catch (e) {
      debugPrint("Error while sharing: $e");
    }
  }


  Future<void> _openViewer(BuildContext context) async {
    HapticFeedback.lightImpact();

    if (isVideo) {
      final thumb = _thumbnailCache[mediaFile.path];
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
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: VideoPreviewBottomSheet(
                file: mediaFile,
                thumbnail: thumb,
                scrollController: scrollController,
                onSave: () => _save(context),
                isSaved: widget.isSaved,
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
            file: mediaFile,
            onSave: () => _save(context),
            isSaved: widget.isSaved,
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _openViewer(context),
      child: Hero(
        tag: mediaFile.path,
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
              // Media content (no changes here)
              if (isVideo)
                _thumbnail != null
                    ? Image.memory(
                  _thumbnail!,
                  fit: BoxFit.cover,
                )
                    : Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.grey[300]),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    mediaFile,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.error, size: 40)),
                  ),
                ),
              // Overlay and other UI elements (no changes here)
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
              if (isVideo)
                Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
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
              if (isVideo && _duration != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _duration!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // ✨ CHANGED: This button is now conditional
              Positioned(
                bottom: 12,
                right: 12,
                child: IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor:
                    theme.colorScheme.primaryContainer.withOpacity(0.8),
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(10),
                    shadowColor: Colors.black26,
                  ),
                  // Conditionally change the icon
                  icon: Icon(
                    widget.isSaved
                        ? Icons.share_rounded
                        : Icons.save_alt_rounded,
                    size: 22,
                  ),
                  // Conditionally change the action
                  onPressed: () =>
                  widget.isSaved ? _share() : _save(context),
                  // Conditionally change the tooltip
                  tooltip: widget.isSaved ? 'Share' : 'Save to gallery',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}