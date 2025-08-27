import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statushub/service/background_worker.dart';
import 'package:statushub/utils/cache_manager.dart';
import 'package:workmanager/workmanager.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await CacheManager.instance.cacheDir;

  await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}