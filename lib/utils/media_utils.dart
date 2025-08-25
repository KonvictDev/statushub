import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class MediaUtils {
  static const _platform = MethodChannel('com.appsbyanandakumar.statushub/media_scanner');

  static bool isVideoFile(String path) => path.toLowerCase().endsWith('.mp4');

  static Future<File> saveToGallery(File file, {required bool isVideo}) async {
    final baseDir = Directory(
        '/storage/emulated/0/Download/StatusSaver/${isVideo ? "Videos" : "Images"}');

    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    final newPath = p.join(baseDir.path, p.basename(file.path));
    final newFile = await file.copy(newPath);

    await _platform.invokeMethod('scanMedia', {'paths': [newFile.path]});
    return newFile;
  }
}
