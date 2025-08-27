import 'dart:io';
import 'dart:typed_data' as typed;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../utils/cache_manager.dart';
import '../utils/media_utils.dart';

// A simple class to hold both the thumbnail and duration
class MediaMetadata {
  final typed.Uint8List? thumbnail;
  final String? duration;
  const MediaMetadata({this.thumbnail, this.duration});
}

final mediaMetadataProvider = FutureProvider.family<MediaMetadata, FileSystemEntity>((ref, file) async {
  final isVideo = MediaUtils.isVideoFile(file.path);

  if (isVideo) {
    // Check if thumbnail and duration are already cached
    final thumbnailData = await _getCachedThumbnail(file);
    final duration = await _getCachedDuration(file);

    if (thumbnailData != null && duration != null) {
      return MediaMetadata(thumbnail: thumbnailData, duration: duration);
    }

    // Generate thumbnail if not cached
    final newThumbnail = thumbnailData ?? await _generateThumbnail(file);

    // Get duration if not cached
    final newDuration = duration ?? await _generateDuration(file);

    return MediaMetadata(thumbnail: newThumbnail, duration: newDuration);
  } else {
    // No special metadata for images
    return const MediaMetadata();
  }
});

// Helper functions for the provider

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
      maxWidth: 200,
      quality: 60,
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