import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:statushub/firebase_options.dart';
import 'package:statushub/service/background_worker.dart';
import 'package:statushub/service/notification_service.dart';
import 'package:statushub/utils/app_lifecycle_reactor.dart';
import 'package:statushub/utils/app_open_ad_manager.dart';
import 'package:statushub/utils/cache_manager.dart';
import 'package:statushub/utils/update_manager.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await MobileAds.instance.initialize();

  bool updateRequired = await UpdateManager.instance.isUpdateRequired();

  if (updateRequired) {
    runApp(const ForceUpdateApp());
    return;
  }

  // ✅ Initialize Notifications & Subscribe to "all_users"
  await NotificationService.init();

  AppOpenAdManager.instance.loadAd();

  _initApp();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _initApp() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  Future.microtask(() {
    AppLifecycleReactor(
        appOpenAdManager: AppOpenAdManager.instance
    ).listenToAppStateChanges();
  });

  await CacheManager.instance.cacheDir;

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
}