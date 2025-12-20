import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class MediaUtils {
  // Channel to communicate with Android native code for media scanning
  static const _platform = MethodChannel('com.appsbyanandakumar.statushub/media_scanner');

  // Helper to check if a file is a video based on extension
  static bool isVideoFile(String path) => path.toLowerCase().endsWith('.mp4');

  /// Saves the file to the public Download/StatusHub folder
  static Future<File> saveToGallery(File file, {required bool isVideo}) async {
    // 1. Unified Path: Matches what StatusService reads
    final baseDir = Directory('/storage/emulated/0/Download/StatusHub');

    // Create the directory if it doesn't exist
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    // 2. Create the destination file path
    final newPath = p.join(baseDir.path, p.basename(file.path));
    final newFile = File(newPath);

    // 3. Copy the file.
    // If the file already exists, we overwrite it to ensure the latest version.
    if (await newFile.exists()) {
      await newFile.delete();
    }

    // Perform the copy
    await file.copy(newFile.path);

    // 4. Trigger Media Scan so it shows up in Gallery apps immediately
    try {
      await _platform.invokeMethod('scanMedia', {'paths': [newFile.path]});
    } catch (e) {
      // Log the error but don't crash the app if scanning fails
      print("Media Scan failed: $e");
    }

    return newFile;
  }
}