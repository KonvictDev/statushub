import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:statushub/utils/ad_helper.dart';
import 'package:statushub/screens/truth_or_dare_screen.dart';
import 'Game2048.dart';
import 'tic_tac_toe_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  // 🚀 SENIOR OPTIMIZATION: Click-based Frequency Control
  // This counter is static so it persists even if the user navigates away and back.
  static int _totalGameClicks = 0;
  final int _adTriggerCount = 3; // Show ad every 3rd click

  @override
  void initState() {
    super.initState();
    _loadBannerAd();

    // 💰 Pre-load the Interstitial so it's ready when the 3rd click happens
    AdHelper.loadInterstitialAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isBannerAdReady = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  /// 🎯 CLICK-BASED GATEKEEPER
  void _handleGameEntry(Widget gameWidget) {
    HapticFeedback.mediumImpact();
    _totalGameClicks++; // Increment total session clicks

    // Logic: Every 3rd click triggers an ad
    if (_totalGameClicks % _adTriggerCount == 0) {
      debugPrint("Ad Triggered: Click #$_totalGameClicks");

      AdHelper.showInterstitialAd(onComplete: () {
        _navigateToGame(gameWidget);
      });
    } else {
      debugPrint("Clicks remaining for ad: ${_adTriggerCount - (_totalGameClicks % _adTriggerCount)}");
      _navigateToGame(gameWidget);
    }
  }

  void _navigateToGame(Widget gameWidget) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => gameWidget),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> games = [
      {
        'title': '2048',
        'icon': 'assets/images/game1.png',
        'widget': const Game2048(),
      },
      {
        'title': 'Tic-Tac-Toe',
        'icon': 'assets/images/game2.jpeg',
        'widget': TicTacToeScreen(),
      },
      {
        'title': 'Truth or Dare',
        'icon': 'assets/images/bottle.jpeg',
        'widget': TruthOrDareHome(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Games Hub',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: games.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final game = games[index];
                return GestureDetector(
                  onTap: () => _handleGameEntry(game['widget']),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: Image.asset(game['icon'], fit: BoxFit.cover)),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            game['title'],
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 💰 Persistent Banner
          if (_isBannerAdReady)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}