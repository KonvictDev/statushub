// main.dart (Updated)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 Import Riverpod
import 'package:statushub/utils/cache_manager.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await CacheManager.instance.cacheDir;

  // Wrap your root widget with ProviderScope
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}