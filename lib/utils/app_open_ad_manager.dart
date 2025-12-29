import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';

class AppOpenAdManager {
  // Singleton instance
  static final AppOpenAdManager instance = AppOpenAdManager._internal();

  AppOpenAdManager._internal();

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  // Keep track of load time to expire ads after 4 hours (Google Requirement)
  DateTime? _appOpenLoadTime;

  /// Load an App Open Ad.
  void loadAd() {
    AppOpenAd.load(
      adUnitId: AdHelper.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ App Open Ad Loaded');
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ App Open Ad Failed to Load: ${error.message}');
        },
      ),
    );
  }

  /// Check if ad is available and not expired (4 hours limit)
  bool get isAdAvailable {
    return _appOpenAd != null &&
        _appOpenLoadTime != null &&
        DateTime.now().difference(_appOpenLoadTime!) < const Duration(hours: 4);
  }

  /// Shows the ad if available.
  void showAdIfAvailable() {
    if (!isAdAvailable) {
      debugPrint('⚠️ Tried to show App Open Ad before it was ready.');
      loadAd(); // Load for next time
      return;
    }

    if (_isShowingAd) {
      debugPrint('⚠️ Already showing an ad.');
      return;
    }

    // Set full screen callback
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // 🚀 Pre-load the NEXT ad immediately
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }
}