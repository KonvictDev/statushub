import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:statushub/utils/cache_manager.dart';
import 'app.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await CacheManager.instance.cacheDir;

  runApp(const MyApp());
}
