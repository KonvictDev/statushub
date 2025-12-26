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
    if (!await cache.exists()) {
      await cache.create(recursive: true);
    }

    if (!_cleanupDone) {
      // Await here ensures we don't crash, but since it's async I/O
      // it won't freeze the UI thread like listSync() did.
      await _cleanupOldCache(cache, maxAgeDays: 7, maxSizeMB: 200);
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

    // 1) Delete old files (Async)
    // We use a separate list to avoid concurrent modification issues during iteration
    final List<File> files = [];
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          files.add(entity);
        }
      }
    } catch (_) {}

    for (final f in files) {
      try {
        final stat = await f.stat();
        if (now.difference(stat.modified).inDays > maxAgeDays) {
          await f.delete();
        }
      } catch (_) {}
    }

    // 2) Enforce size limit (Async)
    // Re-fetch list in case files were deleted above
    final List<File> remainingFiles = [];
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          remainingFiles.add(entity);
        }
      }
    } catch (_) {}

    // Calculate total size async
    int totalBytes = 0;
    final List<MapEntry<File, DateTime>> fileStats = [];

    for (final f in remainingFiles) {
      try {
        final stat = await f.stat();
        totalBytes += stat.size;
        fileStats.add(MapEntry(f, stat.modified));
      } catch (_) {}
    }

    final maxBytes = maxSizeMB * 1024 * 1024;

    if (totalBytes > maxBytes) {
      // Sort by modification time (oldest first)
      fileStats.sort((a, b) => a.value.compareTo(b.value));

      for (final entry in fileStats) {
        if (totalBytes <= maxBytes) break;
        try {
          final f = entry.key;
          final len = await f.length();
          await f.delete();
          totalBytes -= len;
        } catch (_) {}
      }
    }
  }

  Future<String?> getCachedPath(String key) async {
    final cacheDir = await this.cacheDir;
    final path = '${cacheDir.path}/${key.hashCode}.dat';
    final file = File(path);
    return await file.exists() ? path : null;
  }

  Future<String> saveToCache(String key, List<int> bytes) async {
    final cacheDir = await this.cacheDir;
    final path = '${cacheDir.path}/${key.hashCode}.dat';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  Future<void> clearCache() async {
    final dir = await cacheDir;
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
    } catch (_) {}
  }
}