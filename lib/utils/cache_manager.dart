import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CacheManager {
  CacheManager._();
  static final instance = CacheManager._();

  Directory? _cacheDir;
  bool _cleanupDone = false;

  Future<Directory> get cacheDir async {
    _cacheDir ??= await _initCacheDir();
    return _cacheDir!;
  }

  Future<Directory> _initCacheDir() async {
    final dir = await getTemporaryDirectory();
    final cache = Directory('${dir.path}/status_cache');
    if (!cache.existsSync()) {
      cache.createSync(recursive: true);
    }

    if (!_cleanupDone) {
      _cleanupOldCache(cache, maxAgeDays: 7, maxSizeMB: 200);
      _cleanupDone = true;
    }

    return cache;
  }

  Future<void> _cleanupOldCache(
      Directory dir, {
        int maxAgeDays = 7,
        int maxSizeMB = 200,
      }) async {
    final now = DateTime.now();
    final files = dir.listSync().whereType<File>().toList();

    // 1) Delete old files
    for (final f in files) {
      final stat = await f.stat();
      if (now.difference(stat.modified).inDays > maxAgeDays) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }

    // 2) Enforce size limit
    final remaining = dir.listSync().whereType<File>().toList();
    int totalBytes = remaining.fold(0, (sum, f) => sum + f.lengthSync());
    final maxBytes = maxSizeMB * 1024 * 1024;

    if (totalBytes > maxBytes) {
      remaining.sort((a, b) =>
          a.statSync().modified.compareTo(b.statSync().modified));
      for (final f in remaining) {
        if (totalBytes <= maxBytes) break;
        try {
          final len = f.lengthSync();
          f.deleteSync();
          totalBytes -= len;
        } catch (_) {}
      }
    }
  }

  /// 🔥 Manually clear cache (for a "Clear Cache" button)
  Future<void> clearCache() async {
    final dir = await cacheDir;
    try {
      if (dir.existsSync()) {
        for (final f in dir.listSync()) {
          try {
            f.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
