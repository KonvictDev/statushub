import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:saf/saf.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum to switch between Apps
enum WhatsAppType { whatsapp, business }

class StatusService {
  // --- Constants ---
  static const String _prefPermissionKeyWA = 'perm_granted_whatsapp';
  static const String _prefPermissionKeyWB = 'perm_granted_business';

  // Unified Save Path
  static const String _savedPath = '/storage/emulated/0/Download/StatusHub';

  static const _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp'};
  static const _videoExtensions = {'.mp4', '.mkv', '.avi', '.mov', '.gif', '.3gp'};

  /// --- Path Strategy ---
  static Future<String> _getWhatsAppPath(WhatsAppType type) async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final int sdkInt = androidInfo.version.sdkInt;
    final isBusiness = type == WhatsAppType.business;

    // Android 11+ (API 30+)
    if (sdkInt >= 30) {
      if (isBusiness) {
        return 'Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses';
      } else {
        return 'Android/media/com.whatsapp/WhatsApp/Media/.Statuses';
      }
    }
    // Android 10 and below (Legacy)
    else {
      if (isBusiness) {
        return '/storage/emulated/0/WhatsApp Business/Media/.Statuses';
      } else {
        return '/storage/emulated/0/WhatsApp/Media/.Statuses';
      }
    }
  }

  static String _getPermissionKey(WhatsAppType type) {
    return type == WhatsAppType.business ? _prefPermissionKeyWB : _prefPermissionKeyWA;
  }

  /// --- 1. Permission Management ---

  static Future<bool> hasPermission(WhatsAppType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_getPermissionKey(type)) ?? false;
  }

  // Backwards compatibility
  static Future<bool> hasRequiredPermissions() async {
    return await hasPermission(WhatsAppType.whatsapp);
  }

  static Future<bool> requestPermission(WhatsAppType type) async {
    try {
      final path = await _getWhatsAppPath(type);
      Saf saf = Saf(path);

      bool? isGranted = await saf.getDirectoryPermission(grantWritePermission: true);

      if (isGranted == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_getPermissionKey(type), true);
        await saf.sync();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("StatusHub: Permission request failed: $e");
      return false;
    }
  }

  /// --- 2. Get Live Statuses (Optimized) ---

  static Future<List<FileSystemEntity>> getStatuses(WhatsAppType type) async {
    try {
      final path = await _getWhatsAppPath(type);
      Saf saf = Saf(path);

      await saf.sync();

      List<String>? cachedPaths = await saf.getCachedFilesPath();
      if (cachedPaths == null || cachedPaths.isEmpty) {
        return [];
      }

      List<File> statusFiles = [];
      for (String pth in cachedPaths) {
        if (_isValidExtension(pth)) {
          statusFiles.add(File(pth));
        }
      }

      // ✅ Use Optimized Sorting
      return await _sortByDate(statusFiles);

    } catch (e) {
      debugPrint("StatusHub: Error fetching statuses: $e");
      return [];
    }
  }

  /// --- 3. Get Saved Statuses (Optimized) ---

  static Future<List<FileSystemEntity>> getSavedStatuses() async {
    try {
      final saveDir = Directory(_savedPath);
      if (!await saveDir.exists()) return [];

      final files = saveDir.listSync().where((f) =>
      f is File && _isValidExtension(f.path)
      ).toList();

      // ✅ Use Optimized Sorting
      return await _sortByDate(files.cast<File>());

    } catch (e) {
      return [];
    }
  }

  /// ✅ PERFORMANCE FIX: Fetch metadata in parallel, sort in memory
  static Future<List<File>> _sortByDate(List<File> files) async {
    if (files.isEmpty) return [];

    // Fetch modification times in parallel
    final entries = await Future.wait(files.map((file) async {
      try {
        final stat = await file.stat();
        return MapEntry(file, stat.modified);
      } catch (e) {
        return MapEntry(file, DateTime(1970));
      }
    }));

    // Sort efficiently
    entries.sort((a, b) => b.value.compareTo(a.value));

    // Return sorted files
    return entries.map((e) => e.key).toList();
  }

  static bool _isValidExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    return _imageExtensions.contains(ext) || _videoExtensions.contains(ext);
  }
}