import 'dart:io';
import 'dart:typed_data' as typed;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../utils/cache_manager.dart';
import '../utils/media_utils.dart';

// Simple class to hold thumbnail and duration
class MediaMetadata {
  final typed.Uint8List? thumbnail;
  final String? duration;
  const MediaMetadata({this.thumbnail, this.duration});
}

// ✅ Added .autoDispose to clean up when completely unused,
// but we use keepAlive to handle scroll recycling.
final mediaMetadataProvider = FutureProvider.autoDispose.family<MediaMetadata, FileSystemEntity>((ref, file) async {

  // ✅ PERF: Keep this provider alive even if the widget is disposed temporarily (scrolling)
  final link = ref.keepAlive();

  // Optional: Dispose if not used for 5 minutes (Clean up memory)
  // Timer? timer;
  // ref.onDispose(() => timer?.cancel());
  // ref.onCancel(() {
  //   timer = Timer(const Duration(minutes: 5), () => link.close());
  // });
  // ref.onResume(() => timer?.cancel());

  final isVideo = MediaUtils.isVideoFile(file.path);

  if (isVideo) {
    // 1. Check Cache First (Fastest)
    final thumbnailData = await _getCachedThumbnail(file);
    final duration = await _getCachedDuration(file);

    if (thumbnailData != null && duration != null) {
      return MediaMetadata(thumbnail: thumbnailData, duration: duration);
    }

    // 2. Generate if missing
    final newThumbnail = thumbnailData ?? await _generateThumbnail(file);
    final newDuration = duration ?? await _generateDuration(file);

    return MediaMetadata(thumbnail: newThumbnail, duration: newDuration);
  } else {
    // Images don't need generated metadata
    return const MediaMetadata();
  }
});

// --- Helpers ---

Future<typed.Uint8List?> _getCachedThumbnail(FileSystemEntity file) async {
  final cachePath = await CacheManager.instance.getCachedPath('${file.path}_thumb');
  if (cachePath != null) {
    return File(cachePath).readAsBytes();
  }
  return null;
}

Future<String?> _getCachedDuration(FileSystemEntity file) async {
  final cachePath = await CacheManager.instance.getCachedPath('${file.path}_duration');
  if (cachePath != null) {
    return File(cachePath).readAsString();
  }
  return null;
}

Future<typed.Uint8List?> _generateThumbnail(FileSystemEntity file) async {
  try {
    final thumb = await VideoThumbnail.thumbnailData(
      video: file.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 200, // Reduced size for performance
      quality: 50,   // Lower quality is fine for thumbnails
    );
    if (thumb != null) {
      await CacheManager.instance.saveToCache('${file.path}_thumb', thumb);
    }
    return thumb;
  } catch (e) {
    return null;
  }
}

Future<String?> _generateDuration(FileSystemEntity file) async {
  final controller = VideoPlayerController.file(File(file.path));
  try {
    await controller.initialize();
    final duration = controller.value.duration;
    final formatted = _formatDuration(duration);

    // Save duration string as bytes
    await CacheManager.instance.saveToCache('${file.path}_duration', formatted.codeUnits);
    return formatted;
  } catch (e) {
    return null;
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