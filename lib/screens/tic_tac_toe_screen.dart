import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/tic_tac_toe_logic.dart';
import '../utils/ad_helper.dart';

class TicTacToeScreen extends ConsumerStatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  ConsumerState<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends ConsumerState<TicTacToeScreen> {
  final TextEditingController xNameController = TextEditingController();
  final TextEditingController oNameController = TextEditingController();

  // --- AD VARIABLES ---
  BannerAd? _topBannerAd;
  BannerAd? _bottomBannerAd;
  bool _isTopAdReady = false;
  bool _isBottomAdReady = false;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;

  Timer? _uiTimer;
  DateTime? _adFreeUntil;
  bool _isAdFree = false;
  int _secondsUntilNextInterstitial = 60;

  @override
  void initState() {
    super.initState();
    _checkAdFreeStatus();
    _initAds();
    _startUiTimer();
  }

  @override
  void dispose() {
    xNameController.dispose();
    oNameController.dispose();
    _uiTimer?.cancel();
    _topBannerAd?.dispose();
    _bottomBannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  // --- AD & UI TIMER LOGIC ---

  void _startUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_adFreeUntil != null) {
          final remaining = _adFreeUntil!.difference(DateTime.now());

          // Vibration warning for the last 5 seconds
          if (remaining.inSeconds > 0 && remaining.inSeconds <= 5) {
            HapticFeedback.vibrate();
          }

          if (remaining.isNegative) {
            _isAdFree = false;
            _adFreeUntil = null;
          }
        }

        if (!_isAdFree) {
          if (_secondsUntilNextInterstitial <= 1) {
            _showInterstitial();
            _secondsUntilNextInterstitial = 60;
          } else {
            _secondsUntilNextInterstitial--;
          }
        }
      });
    });
  }

  void _showAdFreeUpsellDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Go Ad-Free?",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: const Text("Tired of ads? Watch a short video to enjoy 30 minutes of uninterrupted gameplay!",
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later", style: TextStyle(color: Color(0xFF8F7A66), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () {
              Navigator.pop(context);
              _showRewardedAd();
            },
            child: const Text("Unlock 30m", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- CORE AD METHODS ---

  void _checkAdFreeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    dynamic storedValue = prefs.get('adFreeUntil');
    int adFreeTimestamp = 0;

    if (storedValue is int) adFreeTimestamp = storedValue;
    else if (storedValue is String) adFreeTimestamp = int.tryParse(storedValue) ?? 0;

    if (adFreeTimestamp > DateTime.now().millisecondsSinceEpoch) {
      setState(() {
        _isAdFree = true;
        _adFreeUntil = DateTime.fromMillisecondsSinceEpoch(adFreeTimestamp);
      });
    }
  }

  void _initAds() {
    _topBannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isTopAdReady = true),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();

    _bottomBannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBottomAdReady = true),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();

    _loadInterstitialAd();
    _loadRewardedAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (err) => _interstitialAd = null,
      ),
    );
  }

  void _loadRewardedAd() {
    if (_isLoadingRewarded) return;
    _isLoadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
        },
        onAdFailedToLoad: (err) {
          _rewardedAd = null;
          _isLoadingRewarded = false;
          Future.delayed(const Duration(seconds: 10), () => _loadRewardedAd());
        },
      ),
    );
  }

  void _showInterstitial() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
          _showAdFreeUpsellDialog();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
    }
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        final prefs = await SharedPreferences.getInstance();
        final expiry = DateTime.now().add(const Duration(minutes: 30));
        await prefs.setInt('adFreeUntil', expiry.millisecondsSinceEpoch);
        setState(() {
          _isAdFree = true;
          _adFreeUntil = expiry;
        });
        _rewardedAd = null;
        _loadRewardedAd();
      });
    } else {
      _loadRewardedAd();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fetching the reward video... try again in 5s")));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  // --- UI DIALOGS ---

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Reset Scores?'),
        content: const Text('This will reset all win counts to zero.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(ticTacToeProvider.notifier).resetAllScores();
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNameInputDialog() {
    final state = ref.read(ticTacToeProvider);
    xNameController.text = state.playerXName;
    oNameController.text = state.playerOName;

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Change Player Names'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: xNameController, decoration: const InputDecoration(labelText: 'Player X Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: oNameController, decoration: const InputDecoration(labelText: 'Player O Name', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(ticTacToeProvider.notifier).setPlayerNames(
                xNameController.text.isNotEmpty ? xNameController.text : state.playerXName,
                oNameController.text.isNotEmpty ? oNameController.text : state.playerOName,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ticTacToeProvider);
    final notifier = ref.read(ticTacToeProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tic-Tac-Toe', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.blue), onPressed: notifier.resetGame),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.blue),
            onSelected: (value) {
              if (value == 'reset_scores') _showResetConfirmation();
              else if (value == 'change_names') _showNameInputDialog();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'change_names', child: Text('Change Player Names')),
              const PopupMenuItem(value: 'reset_scores', child: Text('Reset Scores', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isTopAdReady && !_isAdFree)
              Container(
                alignment: Alignment.center,
                width: _topBannerAd!.size.width.toDouble(),
                height: _topBannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _topBannerAd!),
              ),

            Expanded(
              child: SingleChildScrollView( // Senior Fix: Prevents RenderFlex overflow
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- AD STATUS UI ---
                    _isAdFree
                        ? Chip(
                      backgroundColor: Colors.green,
                      avatar: const Icon(Icons.timer, color: Colors.white, size: 16),
                      label: Text("Ad-Free: ${_formatDuration(_adFreeUntil!.difference(DateTime.now()))}", style: const TextStyle(color: Colors.white)),
                    )
                        : Chip(
                      backgroundColor: Colors.blue[100],
                      avatar: const Icon(Icons.ad_units, color: Colors.blue, size: 16),
                      label: Text("Next Ad in: ${_secondsUntilNextInterstitial}s", style: const TextStyle(color: Colors.blue)),
                    ),
                    const SizedBox(height: 12),

                    _buildPlayerHeader(state),
                    const SizedBox(height: 16),

                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, crossAxisSpacing: 8.0, mainAxisSpacing: 8.0,
                          ),
                          itemCount: 9,
                          itemBuilder: (context, index) {
                            final row = index ~/ 3;
                            final col = index % 3;
                            return GestureDetector(
                              onTap: () async {
                                await HapticFeedback.lightImpact();
                                notifier.playMove(row, col);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: state.winningCells[row][col] ? Colors.amber[100] : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    state.board[row][col],
                                    style: TextStyle(
                                      fontSize: 42, fontWeight: FontWeight.bold,
                                      color: state.board[row][col] == 'X' ? Colors.blue : Colors.pink,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!_isAdFree)
                      TextButton.icon( // Used TextButton to save vertical space
                        onPressed: _showRewardedAd,
                        icon: const Icon(Icons.video_library, color: Colors.orange),
                        label: const Text("Unlock 30m Ad-Free", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ),

                    const SizedBox(height: 14),
                    _buildGameControls(state, notifier),
                    const SizedBox(height: 16),
                    if (state.winner.isNotEmpty) _buildWinnerAnnouncement(state, notifier),
                  ],
                ),
              ),
            ),

            if (_isBottomAdReady && !_isAdFree)
              Container(
                alignment: Alignment.center,
                width: _bottomBannerAd!.size.width.toDouble(),
                height: _bottomBannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bottomBannerAd!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeader(TicTacToeState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _PlayerBadge(name: state.playerXName, score: state.playerXWins, isActive: state.currentPlayer == 'X' && state.winner.isEmpty, isX: true),
        Column(
          children: [
            const Text('VS', style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text('${state.draws} draws', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        _PlayerBadge(name: state.playerOName, score: state.playerOWins, isActive: state.currentPlayer == 'O' && state.winner.isEmpty, isX: false),
      ],
    );
  }

  Widget _buildGameControls(TicTacToeState state, TicTacToeNotifier notifier) {
    return Column(
      children: [
        if (state.timerEnabled && !notifier.isSinglePlayer) ...[
          LinearProgressIndicator(value: state.moveTimeLeft / 30, backgroundColor: Colors.grey[200], color: Colors.blue, minHeight: 6),
          const SizedBox(height: 8),
          Text('${state.moveTimeLeft} seconds left', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _GameOptionChip(icon: notifier.isSinglePlayer ? Icons.person : Icons.people, label: notifier.isSinglePlayer ? 'Single' : 'Multi', onTap: () => notifier.setSinglePlayer(!notifier.isSinglePlayer)),
            if (notifier.isSinglePlayer)
              _GameOptionChip(icon: Icons.smart_toy, label: notifier.difficulty.toString().split('.').last, onTap: () {
                showModalBottomSheet(context: context, builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: Difficulty.values.map((diff) => ListTile(title: Text(diff.toString().split('.').last), trailing: notifier.difficulty == diff ? const Icon(Icons.check) : null, onTap: () { notifier.setDifficulty(diff); Navigator.pop(context); })).toList()));
              }),
          ],
        ),
      ],
    );
  }

  Widget _buildWinnerAnnouncement(TicTacToeState state, TicTacToeNotifier notifier) {
    return Column(
      children: [
        Text(state.winner == 'draw' ? "It's a Draw!" : "${state.winner == 'X' ? state.playerXName : state.playerOName} Wins!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: state.winner == 'X' ? Colors.blue : Colors.pink)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: notifier.resetGame, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Play Again', style: TextStyle(color: Colors.white))),
      ],
    );
  }
}

class _PlayerBadge extends StatelessWidget {
  final String name;
  final int score;
  final bool isActive;
  final bool isX;
  const _PlayerBadge({required this.name, required this.score, required this.isActive, required this.isX});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isActive ? (isX ? Colors.blue[50] : Colors.pink[50]) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? (isX ? Colors.blue : Colors.pink) : Colors.transparent, width: 2)), child: Column(children: [Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isX ? Colors.blue : Colors.pink)), Text('$score wins', style: const TextStyle(fontSize: 12, color: Colors.grey))]));
  }
}

class _GameOptionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GameOptionChip({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: Colors.blue), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 12))])));
  }
}