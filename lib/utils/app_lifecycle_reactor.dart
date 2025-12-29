import 'package:flutter/material.dart';
import 'app_open_ad_manager.dart';

class AppLifecycleReactor extends WidgetsBindingObserver {
  final AppOpenAdManager appOpenAdManager;

  AppLifecycleReactor({required this.appOpenAdManager});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 🚀 User came back to the app -> Show Ad
      appOpenAdManager.showAdIfAvailable();
    }
  }

  void listenToAppStateChanges() {
    WidgetsBinding.instance.addObserver(this);
  }
}