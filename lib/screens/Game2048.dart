import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:statushub/utils/ad_helper.dart';

class Game2048 extends StatefulWidget {
  const Game2048({super.key});
  @override
  State<Game2048> createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> with TickerProviderStateMixin {
  // --- AD VARIABLES ---
  BannerAd? _topBannerAd;
  BannerAd? _bottomBannerAd;
  bool _isTopAdReady = false;
  bool _isBottomAdReady = false;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false; // Prevents duplicate load calls

  Timer? _uiTimer;
  DateTime? _adFreeUntil;
  bool _isAdFree = false;
  int _secondsUntilNextInterstitial = 60;

  // --- GAME LOGIC VARIABLES ---
  List<List<int>> grid = List.generate(4, (_) => List.filled(4, 0));
  int score = 0;
  int highScore = 0;
  bool isGameOver = false;

  Point<int>? lastTile;
  List<List<int>>? previousGrid;
  int previousScore = 0;

  int undoCount = 0;
  final int maxUndoCount = 3;
  Set<Point<int>> mergedTiles = {};

  late List<List<AnimationController>> slideControllers;
  late List<List<AnimationController>> popControllers;
  late List<List<Offset>> slideOffsets;

  @override
  void initState() {
    super.initState();
    _checkAdFreeStatus();
    _initAds();
    _startUiTimer();

    slideControllers = List.generate(4, (r) => List.generate(4, (c) => AnimationController(
      vsync: this, duration: const Duration(milliseconds: 100),
    )));
    popControllers = List.generate(4, (r) => List.generate(4, (c) => AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200),
    )));
    slideOffsets = List.generate(4, (_) => List.generate(4, (_) => Offset.zero));
    _loadHighScore();
    _startGame();
  }

  // --- REWARD PROMPT LOGIC ---

  void _showAdFreeUpsellDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEEE4DA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Enjoying 2048?",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Tired of interruptions? Watch one short video to get 30 minutes of Ad-Free gameplay!",
          style: TextStyle(color: Colors.black87, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later", style: TextStyle(color: Color(0xFF8F7A66), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showRewardedAd();
            },
            child: const Text("Go Ad-Free", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- AD & UI TIMER LOGIC ---

  void _startUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_adFreeUntil != null) {
            if (DateTime.now().isAfter(_adFreeUntil!)) {
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
      }
    });
  }

  void _showInterstitial() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
          _showAdFreeUpsellDialog();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  // --- CORE AD METHODS ---

  void _checkAdFreeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // Senior Fix: Handle potential type mismatch by checking key or clearing it
    dynamic storedValue = prefs.get('adFreeUntil');
    int adFreeTimestamp = 0;

    if (storedValue is int) {
      adFreeTimestamp = storedValue;
    } else if (storedValue is String) {
      adFreeTimestamp = int.tryParse(storedValue) ?? 0;
    }

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
        onAdFailedToLoad: (ad, err) { ad.dispose(); },
      ),
    )..load();

    _bottomBannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBottomAdReady = true),
        onAdFailedToLoad: (ad, err) { ad.dispose(); },
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
          debugPrint('Rewarded Ad Load Failed: ${err.message}');
          // Senior Practice: Exponential backoff or simple retry delay for hardware errors
          Future.delayed(const Duration(seconds: 5), () => _loadRewardedAd());
        },
      ),
    );
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
        _rewardedAd = null; // Clear shown ad
        _loadRewardedAd();
      });
    } else {
      _loadRewardedAd(); // Force a reload attempt
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fetching the video, please try again in a few seconds..."),
          backgroundColor: Colors.black87,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // --- GAME LOGIC ---

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('highScore') ?? 0;
    setState(() {});
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      highScore = score;
      await prefs.setInt('highScore', score);
    }
  }

  void _startGame() {
    grid = List.generate(4, (_) => List.filled(4, 0));
    score = 0;
    isGameOver = false;
    lastTile = null;
    mergedTiles.clear();
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        slideControllers[r][c].reset(); popControllers[r][c].reset(); slideOffsets[r][c] = Offset.zero;
      }
    }
    _addNewTile();
    _addNewTile();
    setState(() {});
  }

  void _addNewTile() {
    List<Point<int>> emptyTiles = [];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (grid[r][c] == 0) emptyTiles.add(Point(r, c));
      }
    }
    if (emptyTiles.isEmpty) return;
    final random = Random();
    final chosen = emptyTiles[random.nextInt(emptyTiles.length)];
    grid[chosen.x][chosen.y] = random.nextInt(10) == 0 ? 4 : 2;
    lastTile = chosen;
  }

  Future<void> _handleSwipe(String direction) async {
    if (isGameOver) return;
    mergedTiles.clear();
    previousGrid = grid.map((row) => [...row]).toList();
    previousScore = score;
    _prepareSlideAnimations(direction);
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (slideOffsets[r][c] != Offset.zero) {
          slideControllers[r][c].reset();
          slideControllers[r][c].forward();
        }
      }
    }
    await Future.delayed(const Duration(milliseconds: 100));
    List<List<int>> tempGrid = grid.map((row) => [...row]).toList();
    switch (direction) {
      case 'left': for (int r = 0; r < 4; r++) grid[r] = _mergeLine(grid[r], r, true); break;
      case 'right': for (int r = 0; r < 4; r++) grid[r] = _mergeLine(grid[r].reversed.toList(), r, false).reversed.toList(); break;
      case 'up':
        for (int c = 0; c < 4; c++) {
          List<int> col = [grid[0][c], grid[1][c], grid[2][c], grid[3][c]];
          col = _mergeLine(col, c, true);
          for (int r = 0; r < 4; r++) grid[r][c] = col[r];
        }
        break;
      case 'down':
        for (int c = 0; c < 4; c++) {
          List<int> col = [grid[0][c], grid[1][c], grid[2][c], grid[3][c]];
          col = _mergeLine(col.reversed.toList(), c, false).reversed.toList();
          for (int r = 0; r < 4; r++) grid[r][c] = col[r];
        }
        break;
    }
    if (!_gridsEqual(tempGrid, grid)) _addNewTile();
    if (_isGameOver()) { isGameOver = true; _saveHighScore(); }
    setState(() {});
  }

  List<int> _mergeLine(List<int> line, int rowOrCol, bool isLeftOrUp) {
    List<int> newLine = line.where((val) => val != 0).toList();
    for (int i = 0; i < newLine.length - 1; i++) {
      if (newLine[i] == newLine[i + 1]) {
        newLine[i] *= 2; score += newLine[i]; newLine[i + 1] = 0;
        if (isLeftOrUp) mergedTiles.add(Point(rowOrCol, i)); else mergedTiles.add(Point(rowOrCol, 3 - i));
      }
    }
    newLine = newLine.where((val) => val != 0).toList();
    while (newLine.length < 4) newLine.add(0);
    return newLine;
  }

  void _prepareSlideAnimations(String direction) {
    for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) slideOffsets[r][c] = Offset.zero;
    switch (direction) {
      case 'left':
        for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) if (grid[r][c] != 0) {
          int newCol = _findNewPosition(grid[r], c, direction);
          if (newCol != c) slideOffsets[r][c] = Offset((newCol - c) * -1.0, 0);
        }
        break;
      case 'right':
        for (int r = 0; r < 4; r++) for (int c = 3; c >= 0; c--) if (grid[r][c] != 0) {
          int newCol = _findNewPosition(grid[r], c, direction);
          if (newCol != c) slideOffsets[r][c] = Offset((newCol - c) * 1.0, 0);
        }
        break;
      case 'up':
        for (int c = 0; c < 4; c++) for (int r = 0; r < 4; r++) if (grid[r][c] != 0) {
          int newRow = _findNewPosition([grid[0][c], grid[1][c], grid[2][c], grid[3][c]], r, direction);
          if (newRow != r) slideOffsets[r][c] = Offset(0, (newRow - r) * -1.0);
        }
        break;
      case 'down':
        for (int c = 0; c < 4; c++) for (int r = 3; r >= 0; r--) if (grid[r][c] != 0) {
          int newRow = _findNewPosition([grid[0][c], grid[1][c], grid[2][c], grid[3][c]], r, direction);
          if (newRow != r) slideOffsets[r][c] = Offset(0, (newRow - r) * 1.0);
        }
        break;
    }
  }

  int _findNewPosition(List<int> line, int currentPos, String direction) {
    int newPos = currentPos;
    if (direction == 'left' || direction == 'up') {
      while (newPos > 0 && line[newPos - 1] == 0) newPos--;
    } else {
      while (newPos < line.length - 1 && line[newPos + 1] == 0) newPos++;
    }
    return newPos;
  }

  void _undoMove() {
    if (undoCount < maxUndoCount && previousGrid != null) {
      grid = previousGrid!.map((row) => [...row]).toList();
      score = previousScore; isGameOver = false; lastTile = null; mergedTiles.clear();
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
          slideControllers[r][c].reset(); popControllers[r][c].reset(); slideOffsets[r][c] = Offset.zero;
        }
      }
      undoCount++;
      setState(() {});
    }
  }

  bool _gridsEqual(List<List<int>> a, List<List<int>> b) {
    for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) if (a[r][c] != b[r][c]) return false;
    return true;
  }

  bool _isGameOver() {
    for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) {
      int val = grid[r][c];
      if (val == 0) return false;
      if (r < 3 && val == grid[r + 1][c]) return false;
      if (c < 3 && val == grid[r][c + 1]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final boardSize = min(MediaQuery.of(context).size.width - 40, 280.0);

    return Scaffold(
      backgroundColor: const Color(0xFFD7CEC5),
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
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('2048', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF8F7A66), letterSpacing: 2.0)),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isAdFree && _adFreeUntil != null)
                              Chip(
                                avatar: const Icon(Icons.timer, size: 18, color: Colors.white),
                                backgroundColor: Colors.green,
                                label: Text("Ad-Free: ${_formatDuration(_adFreeUntil!.difference(DateTime.now()))}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              )
                            else
                              Chip(
                                avatar: const Icon(Icons.ad_units, size: 18, color: Colors.white),
                                backgroundColor: const Color(0xFF8F7A66),
                                label: Text("Next Ad in: ${_secondsUntilNextInterstitial}s", style: const TextStyle(color: Colors.white)),
                              ),
                          ],
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _scoreBox('SCORE', score),
                          _scoreBox('BEST', highScore),
                          ElevatedButton(
                            onPressed: _startGame,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8F7A66), foregroundColor: Colors.white),
                            child: const Text('New Game'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onVerticalDragEnd: (details) {
                          if (details.primaryVelocity! < -50) _handleSwipe('up');
                          else if (details.primaryVelocity! > 50) _handleSwipe('down');
                        },
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! < -50) _handleSwipe('left');
                          else if (details.primaryVelocity! > 50) _handleSwipe('right');
                        },
                        child: Container(
                          width: boardSize,
                          height: boardSize,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFFBBADA0), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: List.generate(4, (row) => Expanded(
                              child: Row(
                                children: List.generate(4, (col) {
                                  final value = grid[row][col];
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: _buildAnimatedTile(
                                        value: value, row: row, col: col,
                                        isNew: lastTile?.x == row && lastTile?.y == col,
                                        wasMerged: mergedTiles.contains(Point(row, col)),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            )),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      if (!_isAdFree)
                        ElevatedButton.icon(
                          onPressed: _showRewardedAd,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                          icon: const Icon(Icons.card_giftcard, color: Colors.white),
                          label: const Text("Remove Ads for 30m", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),

                      AnimatedOpacity(
                        opacity: isGameOver ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: Column(
                          children: [
                            const Text('Game Over', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                            ElevatedButton(
                              onPressed: _startGame,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8F7A66), foregroundColor: Colors.white),
                              child: const Text('Restart'),
                            ),
                          ],
                        ),
                      ),
                      if (previousGrid != null)
                        IconButton(
                          onPressed: undoCount < maxUndoCount ? _undoMove : null,
                          icon: const Icon(Icons.undo, size: 32),
                          color: undoCount < maxUndoCount ? const Color(0xFF8F7A66) : Colors.grey,
                        ),
                    ],
                  ),
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

  Widget _scoreBox(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8F7A66))),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFBBADA0), borderRadius: BorderRadius.circular(8)),
          child: Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildAnimatedTile({required int value, required int row, required int col, required bool isNew, required bool wasMerged}) {
    final colorMap = { 0: const Color(0xFFCDC1B4), 2: const Color(0xFFEEE4DA), 4: const Color(0xFFEDE0C8), 8: const Color(0xFFF2B179), 16: const Color(0xFFF59563), 32: const Color(0xFFF67C5F), 64: const Color(0xFFF65E3B), 128: const Color(0xFFEDCF72), 256: const Color(0xFFEDCC61), 512: const Color(0xFFEDC850), 1024: const Color(0xFFEDC53F), 2048: const Color(0xFFEDC22E), };
    final color = colorMap[value] ?? const Color(0xFF3C3A32);
    if ((isNew || wasMerged) && value != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted){ popControllers[row][col].reset(); popControllers[row][col].forward(); } });
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildTileWidget(value, color),
        if (value != 0 && slideOffsets[row][col] != Offset.zero)
          AnimatedBuilder(
            animation: slideControllers[row][col],
            builder: (context, child) => Transform.translate(
                offset: Offset(slideOffsets[row][col].dx * slideControllers[row][col].value, slideOffsets[row][col].dy * slideControllers[row][col].value),
                child: _buildTileWidget(value, color)),
          ),
        if (value != 0 && (isNew || wasMerged))
          ScaleTransition(scale: CurvedAnimation(parent: popControllers[row][col], curve: Curves.easeOutBack), child: _buildTileWidget(value, color)),
      ],
    );
  }

  Widget _buildTileWidget(int value, Color color) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Center(child: Text(value == 0 ? '' : '$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: value <= 4 ? const Color(0xFF865C3E) : Colors.white))),
    );
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _topBannerAd?.dispose();
    _bottomBannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    for (var row in slideControllers) { for (var controller in row) controller.dispose(); }
    for (var row in popControllers) { for (var controller in row) controller.dispose(); }
    super.dispose();
  }
}