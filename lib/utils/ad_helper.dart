import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // ✅ TEST IDs (Replace these with Real IDs from AdMob Dashboard for Release)
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test Banner ID
    }
    return 'ca-app-pub-3940256099942544/2934735716'; // iOS Test
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test Banner ID
    }
    return 'ca-app-pub-3940256099942544/5224354917'; // iOS Test
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test Interstitial ID
    }
    return 'ca-app-pub-3940256099942544/4411468910'; // iOS Test
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/2247696110'; // Android Native Test ID
    }
    return 'ca-app-pub-3940256099942544/3986624511'; // iOS Native Test ID
  }

  // --- INTERSTITIAL AD LOGIC ---
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;

  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load an interstitial ad: ${err.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  static void showInterstitialAd({required VoidCallback onComplete}) {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitialAd(); // Load the next one
          onComplete();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          loadInterstitialAd();
          onComplete();
        },
      );
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
    } else {
      // If ad isn't ready, just continue
      onComplete();
    }
  }
}