import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Difficulty { easy, medium, hard }
enum FirstMove { x, o, winner }

class TicTacToe {
  List<List<String>> board;
  String currentPlayer;
  String winner;
  String lastWinner;
  List<List<bool>> winningCells;

  TicTacToe()
      : board = List.generate(3, (_) => List.filled(3, '')),
        currentPlayer = 'X',
        winner = '',
        lastWinner = '',
        winningCells = List.generate(3, (_) => List.filled(3, false));

  void playMove(int row, int col) {
    if (board[row][col] == '' && winner == '') {
      board[row][col] = currentPlayer;
      checkWinner();
      if (winner == '') {
        switchPlayer();
      } else {
        lastWinner = winner;
      }
    }
  }

  void switchPlayer() {
    currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
  }

  void checkWinner() {
    winningCells = List.generate(3, (_) => List.filled(3, false));

    // Check rows
    for (var i = 0; i < 3; i++) {
      if (board[i][0] == board[i][1] && board[i][1] == board[i][2] && board[i][0] != '') {
        winner = board[i][0];
        winningCells[i][0] = true;
        winningCells[i][1] = true;
        winningCells[i][2] = true;
        return;
      }
    }

    // Check columns
    for (var i = 0; i < 3; i++) {
      if (board[0][i] == board[1][i] && board[1][i] == board[2][i] && board[0][i] != '') {
        winner = board[0][i];
        winningCells[0][i] = true;
        winningCells[1][i] = true;
        winningCells[2][i] = true;
        return;
      }
    }

    // Check diagonals
    if (board[0][0] == board[1][1] && board[1][1] == board[2][2] && board[0][0] != '') {
      winner = board[0][0];
      winningCells[0][0] = true;
      winningCells[1][1] = true;
      winningCells[2][2] = true;
      return;
    }
    if (board[0][2] == board[1][1] && board[1][1] == board[2][0] && board[0][2] != '') {
      winner = board[0][2];
      winningCells[0][2] = true;
      winningCells[1][1] = true;
      winningCells[2][0] = true;
      return;
    }

    // Check for draw
    if (board.every((row) => row.every((cell) => cell != ''))) {
      winner = 'draw';
    }
  }

  void resetBoard({String? firstPlayer}) {
    board = List.generate(3, (_) => List.filled(3, ''));
    winningCells = List.generate(3, (_) => List.filled(3, false));
    currentPlayer = firstPlayer ?? 'X';
    winner = '';
  }
}

class PointManager {
  Future<int> getPlayerXWins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('playerXWins') ?? 0;
  }

  Future<int> getPlayerOWins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('playerOWins') ?? 0;
  }

  Future<int> getDraws() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('draws') ?? 0;
  }

  Future<FirstMove> getFirstMovePref() async {
    final prefs = await SharedPreferences.getInstance();
    return FirstMove.values[prefs.getInt('firstMove') ?? 0];
  }

  Future<String> getPlayerXName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('playerXName') ?? 'Player X';
  }

  Future<String> getPlayerOName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('playerOName') ?? 'Player O';
  }

  Future<bool> getTimerEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('timerEnabled') ?? true;
  }

  Future<void> saveWins(int playerXWins, int playerOWins, int draws) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('playerXWins', playerXWins);
    await prefs.setInt('playerOWins', playerOWins);
    await prefs.setInt('draws', draws);
  }

  Future<void> saveFirstMovePref(FirstMove firstMove) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('firstMove', firstMove.index);
  }

  Future<void> savePlayerNames(String playerXName, String playerOName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playerXName', playerXName);
    await prefs.setString('playerOName', playerOName);
  }

  Future<void> saveTimerEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timerEnabled', enabled);
  }

  Future<void> resetAllScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('playerXWins', 0);
    await prefs.setInt('playerOWins', 0);
    await prefs.setInt('draws', 0);
  }
}

class AI {
  final Difficulty difficulty;

  AI({required this.difficulty});

  int getMove(List<List<String>> board) {
    switch (difficulty) {
      case Difficulty.easy:
        return _getRandomMove(board);
      case Difficulty.medium:
        return _getMediumMove(board);
      case Difficulty.hard:
        return _getHardMove(board);
    }
  }

  int _getRandomMove(List<List<String>> board) {
    List<int> availableMoves = [];
    for (int i = 0; i < 9; i++) {
      int row = i ~/ 3;
      int col = i % 3;
      if (board[row][col] == '') {
        availableMoves.add(i);
      }
    }
    return availableMoves[Random().nextInt(availableMoves.length)];
  }

  int _getMediumMove(List<List<String>> board) {
    // Check for winning move
    for (int i = 0; i < 9; i++) {
      int row = i ~/ 3;
      int col = i % 3;
      if (board[row][col] == '') {
        board[row][col] = 'O';
        TicTacToe tempGame = TicTacToe();
        tempGame.board = board.map((e) => List<String>.from(e)).toList();
        tempGame.checkWinner();
        board[row][col] = '';
        if (tempGame.winner == 'O') {
          return i;
        }
      }
    }

    // Block opponent's winning move
    for (int i = 0; i < 9; i++) {
      int row = i ~/ 3;
      int col = i % 3;
      if (board[row][col] == '') {
        board[row][col] = 'X';
        TicTacToe tempGame = TicTacToe();
        tempGame.board = board.map((e) => List<String>.from(e)).toList();
        tempGame.checkWinner();
        board[row][col] = '';
        if (tempGame.winner == 'X') {
          return i;
        }
      }
    }

    // Take center if available
    if (board[1][1] == '') {
      return 4;
    }

    // Take a random corner
    List<int> corners = [0, 2, 6, 8];
    corners.shuffle();
    for (int corner in corners) {
      int row = corner ~/ 3;
      int col = corner % 3;
      if (board[row][col] == '') {
        return corner;
      }
    }

    // Take any available move
    return _getRandomMove(board);
  }

  int _getHardMove(List<List<String>> board) {
    int bestScore = -1000;
    int bestMove = -1;

    for (int i = 0; i < 9; i++) {
      int row = i ~/ 3;
      int col = i % 3;
      if (board[row][col] == '') {
        board[row][col] = 'O';
        int score = _minimax(board, 0, false);
        board[row][col] = '';
        if (score > bestScore) {
          bestScore = score;
          bestMove = i;
        }
      }
    }
    return bestMove;
  }

  int _minimax(List<List<String>> board, int depth, bool isMaximizing) {
    TicTacToe tempGame = TicTacToe();
    tempGame.board = board.map((e) => List<String>.from(e)).toList();
    tempGame.checkWinner();

    if (tempGame.winner == 'O') return 10 - depth;
    if (tempGame.winner == 'X') return depth - 10;
    if (tempGame.winner == 'draw') return 0;

    if (isMaximizing) {
      int bestScore = -1000;
      for (int i = 0; i < 9; i++) {
        int row = i ~/ 3;
        int col = i % 3;
        if (board[row][col] == '') {
          board[row][col] = 'O';
          int score = _minimax(board, depth + 1, false);
          board[row][col] = '';
          bestScore = max(score, bestScore);
        }
      }
      return bestScore;
    } else {
      int bestScore = 1000;
      for (int i = 0; i < 9; i++) {
        int row = i ~/ 3;
        int col = i % 3;
        if (board[row][col] == '') {
          board[row][col] = 'X';
          int score = _minimax(board, depth + 1, true);
          board[row][col] = '';
          bestScore = min(score, bestScore);
        }
      }
      return bestScore;
    }
  }
}

class TicTacToeScreen extends StatefulWidget {
  @override
  _TicTacToeState createState() => _TicTacToeState();
}

class _TicTacToeState extends State<TicTacToeScreen> with SingleTickerProviderStateMixin {
  late TicTacToe game;
  PointManager pointManager = PointManager();
  late AI ai;
  bool isSinglePlayer = true;
  int playerXWins = 0;
  int playerOWins = 0;
  int draws = 0;
  Difficulty difficulty = Difficulty.medium;
  FirstMove firstMove = FirstMove.x;
  String playerXName = 'Player X';
  String playerOName = 'Player O';
  int moveTimeLeft = 30;
  bool timerEnabled = true;
  late AnimationController _animationController;
  Timer? _moveTimer;
  TextEditingController xNameController = TextEditingController();
  TextEditingController oNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    game = TicTacToe();
    ai = AI(difficulty: difficulty);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _loadPreferences();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _moveTimer?.cancel();
    super.dispose();
  }

  void _loadPreferences() async {
    playerXWins = await pointManager.getPlayerXWins();
    playerOWins = await pointManager.getPlayerOWins();
    draws = await pointManager.getDraws();
    firstMove = await pointManager.getFirstMovePref();
    playerXName = await pointManager.getPlayerXName();
    playerOName = await pointManager.getPlayerOName();
    timerEnabled = await pointManager.getTimerEnabled();
    setState(() {});
    _resetGame();
  }

  void _onCellTapped(int row, int col) async {
    if (game.winner.isNotEmpty) return;

    await HapticFeedback.lightImpact();

    setState(() {
      game.playMove(row, col);
      if (game.winner.isNotEmpty) {
        _updateWins(game.winner);
        _moveTimer?.cancel();
      } else if (isSinglePlayer && game.currentPlayer == 'O') {
        if (timerEnabled && !isSinglePlayer) _startMoveTimer();
        Future.delayed(Duration(milliseconds: 500), () => _aiMove());
      } else {
        if (timerEnabled && !isSinglePlayer) _startMoveTimer();
      }
    });
  }

  void _aiMove() {
    int move = ai.getMove(game.board);
    int row = move ~/ 3;
    int col = move % 3;
    setState(() {
      game.playMove(row, col);
      if (game.winner.isNotEmpty) {
        _updateWins(game.winner);
        _moveTimer?.cancel();
      } else if (timerEnabled && !isSinglePlayer) {
        _startMoveTimer();
      }
    });
  }

  void _resetGame() {
    _moveTimer?.cancel();
    setState(() {
      String? firstPlayer;
      if (firstMove == FirstMove.winner) {
        firstPlayer = game.lastWinner.isNotEmpty ? game.lastWinner : 'X';
      } else {
        firstPlayer = firstMove == FirstMove.x ? 'X' : 'O';
      }
      game.resetBoard(firstPlayer: firstPlayer);

      if (isSinglePlayer && game.currentPlayer == 'O') {
        Future.delayed(Duration(milliseconds: 500), () => _aiMove());
      }

      if (timerEnabled && !isSinglePlayer) {
        _startMoveTimer();
      }
    });
  }

  void _startMoveTimer() {
    _moveTimer?.cancel();
    moveTimeLeft = 30;
    _moveTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (moveTimeLeft > 0) {
        setState(() => moveTimeLeft--);
      } else {
        timer.cancel();
        setState(() {
          game.switchPlayer();
          if (isSinglePlayer && game.currentPlayer == 'O') {
            _aiMove();
          } else if (timerEnabled && !isSinglePlayer) {
            _startMoveTimer();
          }
        });
      }
    });
  }

  void _updateWins(String winner) async {
    if (winner == 'X') {
      playerXWins++;
    } else if (winner == 'O') {
      playerOWins++;
    } else if (winner == 'draw') {
      draws++;
    }

    await pointManager.saveWins(playerXWins, playerOWins, draws);
    setState(() {});
  }

  void _changeDifficulty(Difficulty newDifficulty) {
    setState(() {
      difficulty = newDifficulty;
      ai = AI(difficulty: newDifficulty);
      _resetGame();
    });
  }

  void _changeFirstMove(FirstMove newFirstMove) async {
    await pointManager.saveFirstMovePref(newFirstMove);
    setState(() {
      firstMove = newFirstMove;
      _resetGame();
    });
  }

  void _resetAllScores() async {
    await pointManager.resetAllScores();
    setState(() {
      playerXWins = 0;
      playerOWins = 0;
      draws = 0;
    });
  }

  void _savePlayerNames() async {
    if (xNameController.text.isNotEmpty) {
      playerXName = xNameController.text;
    }
    if (oNameController.text.isNotEmpty) {
      playerOName = oNameController.text;
    }
    await pointManager.savePlayerNames(playerXName, playerOName);
    setState(() {});
  }

  void _toggleTimer(bool value) async {
    await pointManager.saveTimerEnabled(value);
    setState(() {
      timerEnabled = value;
      if (value && !isSinglePlayer && game.winner.isEmpty) {
        _startMoveTimer();
      } else {
        _moveTimer?.cancel();
      }
    });
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset Scores?'),
          content: Text('This will reset all win counts to zero.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _resetAllScores();
                Navigator.pop(context);
              },
              child: Text('Reset', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showNameInputDialog() {
    xNameController.text = playerXName;
    oNameController.text = playerOName;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Player Names'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: xNameController,
                decoration: InputDecoration(
                  labelText: 'Player X Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: oNameController,
                decoration: InputDecoration(
                  labelText: 'Player O Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _savePlayerNames();
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Tic-Tac-Toe', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue),
            onPressed: _resetGame,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.blue),
            onSelected: (value) {
              if (value == 'reset_scores') {
                _showResetConfirmation();
              } else if (value == 'change_names') {
                _showNameInputDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'change_names',
                child: Text('Change Player Names'),
              ),
              PopupMenuItem(
                value: 'reset_scores',
                child: Text('Reset Scores', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Player info header
            _buildPlayerHeader(),
            SizedBox(height: 24),

            // Game board
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(8),
                child: GridView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    int row = index ~/ 3;
                    int col = index % 3;
                    return GestureDetector(
                      onTap: () => _onCellTapped(row, col),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: game.winningCells[row][col]
                              ? Colors.amber[100]
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: game.winningCells[row][col]
                              ? [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                              : null,
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            child: Text(
                              game.board[row][col],
                              key: ValueKey('${row}_${col}_${game.board[row][col]}'),
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: game.board[row][col] == 'X'
                                    ? Colors.blue
                                    : Colors.pink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 24),

            // Game controls
            _buildGameControls(),
            SizedBox(height: 16),

            // Winner announcement
            if (game.winner.isNotEmpty) _buildWinnerAnnouncement(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _PlayerBadge(
          name: playerXName,
          score: playerXWins,
          isActive: game.currentPlayer == 'X' && game.winner.isEmpty,
          isX: true,
        ),
        Column(
          children: [
            Text('VS', style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text('$draws draws', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        _PlayerBadge(
          name: playerOName,
          score: playerOWins,
          isActive: game.currentPlayer == 'O' && game.winner.isEmpty,
          isX: false,
        ),
      ],
    );
  }

  Widget _buildGameControls() {
    return Column(
      children: [
        if (timerEnabled && !isSinglePlayer) ...[
          LinearProgressIndicator(
            value: moveTimeLeft / 30,
            backgroundColor: Colors.grey[200],
            color: Colors.blue,
            minHeight: 6,
          ),
          SizedBox(height: 8),
          Text(
            '$moveTimeLeft seconds left',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 16),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Game mode selector
            _GameOptionChip(
              icon: isSinglePlayer ? Icons.person : Icons.people,
              label: isSinglePlayer ? 'Single' : 'Multi',
              onTap: () {
                setState(() {
                  isSinglePlayer = !isSinglePlayer;
                  _resetGame();
                });
              },
            ),

            // Difficulty selector (only in single player)
            if (isSinglePlayer)
              _GameOptionChip(
                icon: Icons.smart_toy,
                label: difficulty.toString().split('.').last,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: Difficulty.values.map((diff) {
                          return ListTile(
                            title: Text(diff.toString().split('.').last),
                            trailing: difficulty == diff ? Icon(Icons.check) : null,
                            onTap: () {
                              _changeDifficulty(diff);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),

            // First move selector
            _GameOptionChip(
              icon: Icons.swap_horiz,
              label: firstMove == FirstMove.winner
                  ? 'Winner'
                  : firstMove == FirstMove.x
                  ? 'X First'
                  : 'O First',
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: FirstMove.values.map((move) {
                        return ListTile(
                          title: Text(
                            move == FirstMove.winner
                                ? 'Winner First'
                                : move == FirstMove.x
                                ? '$playerXName First'
                                : '$playerOName First',
                          ),
                          trailing: firstMove == move ? Icon(Icons.check) : null,
                          onTap: () {
                            _changeFirstMove(move);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWinnerAnnouncement() {
    return Column(
      children: [
        Text(
          game.winner == 'draw'
              ? "It's a Draw!"
              : "${game.winner == 'X' ? playerXName : playerOName} Wins!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: game.winner == 'X' ? Colors.blue : Colors.pink,
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _resetGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: Text(
            'Play Again',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _PlayerBadge extends StatelessWidget {
  final String name;
  final int score;
  final bool isActive;
  final bool isX;

  const _PlayerBadge({
    required this.name,
    required this.score,
    required this.isActive,
    required this.isX,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? (isX ? Colors.blue[50] : Colors.pink[50]) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? (isX ? Colors.blue : Colors.pink) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isX ? Colors.blue : Colors.pink,
            ),
          ),
          Text(
            '$score wins',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOptionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GameOptionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.blue),
            SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}