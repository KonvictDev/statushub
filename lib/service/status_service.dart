import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;

class StatusService {
  static const _basePath = '/storage/emulated/0/Download/StatusSaver';
  static const _imageExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
  static const _videoExtensions = ['.mp4', '.mkv', '.avi', '.mov'];

  static Future<String> _ensureDir(String subPath) async {
    final dir = Directory(p.join(_basePath, subPath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static Future<String> getSavedImagePath() => _ensureDir('Images');
  static Future<String> getSavedVideoPath() => _ensureDir('Videos');

  static Future<bool> hasRequiredPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) return true;
      if (await Permission.photos.isGranted && await Permission.videos.isGranted) return true;
      if (await Permission.storage.isGranted) return true;
    }
    return false;
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isGranted) return true;
      if (await Permission.photos.request().isGranted &&
          await Permission.videos.request().isGranted) {
        return true;
      }
      if (await Permission.storage.request().isGranted) return true;
    }
    return false;
  }

  static Future<Directory?> _getStatusDirectory() async {
    final possiblePaths = [
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
      '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses',
      '/storage/emulated/0/WhatsApp/Media/.Statuses',
      '/storage/emulated/0/WhatsApp Business/Media/.Statuses',
      '/sdcard/WhatsApp/Media/.Statuses',
      '/sdcard/WhatsApp Business/Media/.Statuses',
    ];

    for (final path in possiblePaths) {
      try {
        final dir = Directory(path);
        if (await dir.exists()) return dir;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static Future<List<FileSystemEntity>> getStatuses() async {
    try {
      if (!await hasRequiredPermissions()) return [];

      final dir = await _getStatusDirectory();
      if (dir == null) return [];

      final files = await dir.list().where((f) => f is File).toList();

      return files.where((f) {
        final ext = p.extension(f.path).toLowerCase();
        return _imageExtensions.contains(ext) || _videoExtensions.contains(ext);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<FileSystemEntity>> getSavedStatuses() async {
    try {
      final imageDir = Directory(await getSavedImagePath());
      final videoDir = Directory(await getSavedVideoPath());

      final imageFiles = await imageDir.list().where((f) => f is File).toList();
      final videoFiles = await videoDir.list().where((f) => f is File).toList();

      return [...imageFiles, ...videoFiles];
    } catch (_) {
      return [];
    }
  }

  static Future<bool> saveStatus(File file) async {
    try {
      final ext = p.extension(file.path).toLowerCase();
      final isImage = _imageExtensions.contains(ext);
      final destDir = isImage ? await getSavedImagePath() : await getSavedVideoPath();
      final destPath = p.join(destDir, p.basename(file.path));
      await file.copy(destPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
