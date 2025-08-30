import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statushub/service/background_worker.dart';
import 'package:statushub/utils/cache_manager.dart';
import 'package:workmanager/workmanager.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run app immediately
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );

  // Do async initializations in the background
  _initApp();
}

Future<void> _initApp() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await CacheManager.instance.cacheDir;

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
}
