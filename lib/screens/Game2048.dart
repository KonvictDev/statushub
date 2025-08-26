import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Game2048 extends StatefulWidget {
  const Game2048({super.key});
  @override
  State<Game2048> createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> with TickerProviderStateMixin {
  List<List<int>> grid = List.generate(4, (_) => List.filled(4, 0));
  int score = 0;
  int highScore = 0;
  bool isGameOver = false;

  Point<int>? lastTile;
  List<List<int>>? previousGrid;
  int previousScore = 0;

  int undoCount = 0;
  final int maxUndoCount = 3;

  bool showLimitPopup = true;
  Set<Point<int>> mergedTiles = {};

  // Animation controllers
  late List<List<AnimationController>> slideControllers;
  late List<List<AnimationController>> popControllers;
  late List<List<Offset>> slideOffsets;

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers
    slideControllers = List.generate(
      4,
          (r) => List.generate(
        4,
            (c) => AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 100),
        ),
      ),
    );
    popControllers = List.generate(
      4,
          (r) => List.generate(
        4,
            (c) => AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        ),
      ),
    );
    slideOffsets = List.generate(4, (_) => List.generate(4, (_) => Offset.zero));
    _loadHighScore();
    _startGame();
  }

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
    // Reset all animations
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        slideControllers[r][c].reset();
        popControllers[r][c].reset();
        slideOffsets[r][c] = Offset.zero;
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

    // Clear previous merged tiles
    mergedTiles.clear();

    // Save current state
    previousGrid = grid.map((row) => [...row]).toList();
    previousScore = score;

    // Prepare slide animations
    _prepareSlideAnimations(direction);

    // Start slide animations
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (slideOffsets[r][c] != Offset.zero) {
          slideControllers[r][c].reset();
          slideControllers[r][c].forward();
        }
      }
    }

    // Wait for slide animations to complete
    await Future.delayed(const Duration(milliseconds: 100));

    // Perform the actual move
    List<List<int>> tempGrid = grid.map((row) => [...row]).toList();
    switch (direction) {
      case 'left':
        for (int r = 0; r < 4; r++) {
          grid[r] = _mergeLine(grid[r], r, true);
        }
        break;
      case 'right':
        for (int r = 0; r < 4; r++) {
          grid[r] = _mergeLine(grid[r].reversed.toList(), r, false).reversed.toList();
        }
        break;
      case 'up':
        for (int c = 0; c < 4; c++) {
          List<int> col = [grid[0][c], grid[1][c], grid[2][c], grid[3][c]];
          col = _mergeLine(col, c, true);
          for (int r = 0; r < 4; r++) {
            grid[r][c] = col[r];
          }
        }
        break;
      case 'down':
        for (int c = 0; c < 4; c++) {
          List<int> col = [grid[0][c], grid[1][c], grid[2][c], grid[3][c]];
          col = _mergeLine(col.reversed.toList(), c, false).reversed.toList();
          for (int r = 0; r < 4; r++) {
            grid[r][c] = col[r];
          }
        }
        break;
    }

    if (!_gridsEqual(tempGrid, grid)) {
      _addNewTile();
    }

    if (_isGameOver()) {
      isGameOver = true;
      _saveHighScore();
    }

    setState(() {});
  }

  List<int> _mergeLine(List<int> line, int rowOrCol, bool isLeftOrUp) {
    List<int> newLine = line.where((val) => val != 0).toList();
    for (int i = 0; i < newLine.length - 1; i++) {
      if (newLine[i] == newLine[i + 1]) {
        newLine[i] *= 2;
        score += newLine[i];
        newLine[i + 1] = 0;

        // Track merged tiles based on direction
        if (isLeftOrUp) {
          mergedTiles.add(Point(rowOrCol, i));
        } else {
          mergedTiles.add(Point(rowOrCol, 3 - i));
        }
      }
    }
    newLine = newLine.where((val) => val != 0).toList();
    while (newLine.length < 4) {
      newLine.add(0);
    }
    return newLine;
  }

  void _prepareSlideAnimations(String direction) {
    // Reset all offsets
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        slideOffsets[r][c] = Offset.zero;
      }
    }

    // Calculate slide offsets based on direction
    switch (direction) {
      case 'left':
        for (int r = 0; r < 4; r++) {
          for (int c = 0; c < 4; c++) {
            if (grid[r][c] != 0) {
              int newCol = _findNewPosition(grid[r], c, direction);
              if (newCol != c) {
                slideOffsets[r][c] = Offset((newCol - c) * -1.0, 0);
              }
            }
          }
        }
        break;
      case 'right':
        for (int r = 0; r < 4; r++) {
          for (int c = 3; c >= 0; c--) {
            if (grid[r][c] != 0) {
              int newCol = _findNewPosition(grid[r], c, direction);
              if (newCol != c) {
                slideOffsets[r][c] = Offset((newCol - c) * 1.0, 0);
              }
            }
          }
        }
        break;
      case 'up':
        for (int c = 0; c < 4; c++) {
          for (int r = 0; r < 4; r++) {
            if (grid[r][c] != 0) {
              int newRow = _findNewPosition([grid[0][c], grid[1][c], grid[2][c], grid[3][c]], r, direction);
              if (newRow != r) {
                slideOffsets[r][c] = Offset(0, (newRow - r) * -1.0);
              }
            }
          }
        }
        break;
      case 'down':
        for (int c = 0; c < 4; c++) {
          for (int r = 3; r >= 0; r--) {
            if (grid[r][c] != 0) {
              int newRow = _findNewPosition([grid[0][c], grid[1][c], grid[2][c], grid[3][c]], r, direction);
              if (newRow != r) {
                slideOffsets[r][c] = Offset(0, (newRow - r) * 1.0);
              }
            }
          }
        }
        break;
    }
  }

  int _findNewPosition(List<int> line, int currentPos, String direction) {
    if (direction == 'left' || direction == 'up') {
      int newPos = currentPos;
      while (newPos > 0 && line[newPos - 1] == 0) {
        newPos--;
      }
      return newPos;
    } else {
      int newPos = currentPos;
      while (newPos < line.length - 1 && line[newPos + 1] == 0) {
        newPos++;
      }
      return newPos;
    }
  }

  void _undoMove() {
    if (undoCount < maxUndoCount && previousGrid != null) {
      grid = previousGrid!.map((row) => [...row]).toList();
      score = previousScore;
      isGameOver = false;
      lastTile = null;
      mergedTiles.clear();

      // Reset animations
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
          slideControllers[r][c].reset();
          popControllers[r][c].reset();
          slideOffsets[r][c] = Offset.zero;
        }
      }

      undoCount++;

      if (showLimitPopup && undoCount == maxUndoCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only undo 3 times.'),
            duration: Duration(seconds: 2),
          ),
        );
        showLimitPopup = false;
      }

      setState(() {});
    } else if (undoCount >= maxUndoCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Undo limit reached!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool _gridsEqual(List<List<int>> a, List<List<int>> b) {
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (a[r][c] != b[r][c]) return false;
      }
    }
    return true;
  }

  bool _isGameOver() {
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        int val = grid[r][c];
        if (val == 0) return false;
        if (r < 3 && val == grid[r + 1][c]) return false;
        if (c < 3 && val == grid[r][c + 1]) return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final boardSize = min(MediaQuery.of(context).size.width - 40, 280.0);

    return Scaffold(
      backgroundColor: const Color(0xFFD7CEC5),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '2048',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8F7A66),
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _scoreBox('SCORE', score),
                _scoreBox('BEST', highScore),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8F7A66),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('New Game'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < -50) {
                  _handleSwipe('up');
                } else if (details.primaryVelocity! > 50) {
                  _handleSwipe('down');
                }
              },
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < -50) {
                  _handleSwipe('left');
                } else if (details.primaryVelocity! > 50) {
                  _handleSwipe('right');
                }
              },
              child: Container(
                width: boardSize,
                height: boardSize,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFBBADA0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: List.generate(4, (row) {
                    return Expanded(
                      child: Row(
                        children: List.generate(4, (col) {
                          final value = grid[row][col];
                          final isNew = lastTile?.x == row && lastTile?.y == col;
                          final wasMerged = mergedTiles.contains(Point(row, col));
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: _buildAnimatedTile(
                                value: value,
                                row: row,
                                col: col,
                                isNew: isNew,
                                wasMerged: wasMerged,
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedOpacity(
              opacity: isGameOver ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Column(
                children: [
                  const Text(
                    'Game Over',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8F7A66),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Restart'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (previousGrid != null)
              Container(
                decoration: BoxDecoration(
                  color: undoCount < maxUndoCount ? const Color(0xFF8F7A66) : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: undoCount < maxUndoCount ? _undoMove : null,
                  icon: const Icon(Icons.undo, size: 32),
                  color: Colors.white,
                  iconSize: 32,
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(maxWidth: 64, maxHeight: 64),
                  splashRadius: 32,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBox(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFBBADA0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Text(
              key: ValueKey(value),
              '$value',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedTile({
    required int value,
    required int row,
    required int col,
    required bool isNew,
    required bool wasMerged,
  }) {
    final colorMap = {
      0: const Color(0xFFCDC1B4),
      2: const Color(0xFFEEE4DA),
      4: const Color(0xFFEDE0C8),
      8: const Color(0xFFF2B179),
      16: const Color(0xFFF59563),
      32: const Color(0xFFF67C5F),
      64: const Color(0xFFF65E3B),
      128: const Color(0xFFEDCF72),
      256: const Color(0xFFEDCC61),
      512: const Color(0xFFEDC850),
      1024: const Color(0xFFEDC53F),
      2048: const Color(0xFFEDC22E),
    };
    final color = colorMap[value] ?? const Color(0xFF3C3A32);

    // Trigger pop animation if this is a new or merged tile
    if ((isNew || wasMerged) && value != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        popControllers[row][col].reset();
        popControllers[row][col].forward();
      });
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Base tile (always visible)
        _buildTileWidget(value, color),

        // Sliding animation (if needed)
        if (value != 0 && slideOffsets[row][col] != Offset.zero)
          AnimatedBuilder(
            animation: slideControllers[row][col],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  slideOffsets[row][col].dx * slideControllers[row][col].value,
                  slideOffsets[row][col].dy * slideControllers[row][col].value,
                ),
                child: _buildTileWidget(value, color),
              );
            },
          ),

        // Pop animation (for new/merged tiles)
        if (value != 0 && (isNew || wasMerged))
          AnimatedBuilder(
            animation: popControllers[row][col],
            builder: (context, child) {
              return ScaleTransition(
                scale: CurvedAnimation(
                  parent: popControllers[row][col],
                  curve: Curves.easeOutBack,
                ),
                child: _buildTileWidget(value, color),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTileWidget(int value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(2, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Text(
          value == 0 ? '' : '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: value <= 4 ? const Color(0xFF865C3E) : Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var row in slideControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    for (var row in popControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}