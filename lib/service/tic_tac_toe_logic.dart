import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

enum Difficulty { easy, medium, hard }
enum FirstMove { x, o, winner }

class TicTacToeState {
  final List<List<String>> board;
  final String currentPlayer;
  final String winner;
  final List<List<bool>> winningCells;
  final int playerXWins;
  final int playerOWins;
  final int draws;
  final String playerXName;
  final String playerOName;
  final int moveTimeLeft;
  final bool timerEnabled;

  const TicTacToeState({
    required this.board,
    required this.currentPlayer,
    required this.winner,
    required this.winningCells,
    required this.playerXWins,
    required this.playerOWins,
    required this.draws,
    required this.playerXName,
    required this.playerOName,
    required this.moveTimeLeft,
    required this.timerEnabled,
  });

  TicTacToeState copyWith({
    List<List<String>>? board,
    String? currentPlayer,
    String? winner,
    List<List<bool>>? winningCells,
    int? playerXWins,
    int? playerOWins,
    int? draws,
    String? playerXName,
    String? playerOName,
    int? moveTimeLeft,
    bool? timerEnabled,
  }) {
    return TicTacToeState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      winner: winner ?? this.winner,
      winningCells: winningCells ?? this.winningCells,
      playerXWins: playerXWins ?? this.playerXWins,
      playerOWins: playerOWins ?? this.playerOWins,
      draws: draws ?? this.draws,
      playerXName: playerXName ?? this.playerXName,
      playerOName: playerOName ?? this.playerOName,
      moveTimeLeft: moveTimeLeft ?? this.moveTimeLeft,
      timerEnabled: timerEnabled ?? this.timerEnabled,
    );
  }
}

class TicTacToeNotifier extends StateNotifier<TicTacToeState> {
  late AI _ai;
  bool isSinglePlayer = true;
  Difficulty difficulty = Difficulty.medium;
  FirstMove firstMove = FirstMove.x;
  String _lastWinner = '';
  Timer? _moveTimer;

  TicTacToeNotifier()
      : super(
    const TicTacToeState(
      board: [['', '', ''], ['', '', ''], ['', '', '']],
      currentPlayer: 'X',
      winner: '',
      winningCells: [[false, false, false], [false, false, false], [false, false, false]],
      playerXWins: 0,
      playerOWins: 0,
      draws: 0,
      playerXName: 'Player X',
      playerOName: 'Player O',
      moveTimeLeft: 30,
      timerEnabled: true,
    ),
  ) {
    _ai = AI(difficulty: difficulty);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      playerXWins: prefs.getInt('playerXWins') ?? 0,
      playerOWins: prefs.getInt('playerOWins') ?? 0,
      draws: prefs.getInt('draws') ?? 0,
      playerXName: prefs.getString('playerXName') ?? 'Player X',
      playerOName: prefs.getString('playerOName') ?? 'Player O',
      timerEnabled: prefs.getBool('timerEnabled') ?? true,
    );
    resetGame();
  }

  void _saveWins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('playerXWins', state.playerXWins);
    await prefs.setInt('playerOWins', state.playerOWins);
    await prefs.setInt('draws', state.draws);
  }

  void playMove(int row, int col) {
    if (state.board[row][col] != '' || state.winner.isNotEmpty) return;

    final newBoard = state.board.map((e) => List<String>.from(e)).toList();
    newBoard[row][col] = state.currentPlayer;
    final winner = _checkWinner(newBoard);
    _updateState(newBoard, winner);

    if (winner.isEmpty) {
      _switchPlayer();
      if (isSinglePlayer && state.currentPlayer == 'O') {
        Future.delayed(const Duration(milliseconds: 500), _aiMove);
      }
    } else {
      _lastWinner = winner;
    }
  }

  void _switchPlayer() {
    final newPlayer = state.currentPlayer == 'X' ? 'O' : 'X';
    state = state.copyWith(currentPlayer: newPlayer);
    _startMoveTimer();
  }

  void _aiMove() {
    if (state.winner.isNotEmpty) return;
    final move = _ai.getMove(state.board);
    final row = move ~/ 3;
    final col = move % 3;
    playMove(row, col);
  }

  String _checkWinner(List<List<String>> board) {
    // Logic remains the same
    for (var i = 0; i < 3; i++) {
      if (board[i][0] == board[i][1] && board[i][1] == board[i][2] && board[i][0] != '') {
        return board[i][0];
      }
      if (board[0][i] == board[1][i] && board[1][i] == board[2][i] && board[0][i] != '') {
        return board[0][i];
      }
    }
    if (board[0][0] == board[1][1] && board[1][1] == board[2][2] && board[0][0] != '') {
      return board[0][0];
    }
    if (board[0][2] == board[1][1] && board[1][1] == board[2][0] && board[0][2] != '') {
      return board[0][2];
    }
    if (board.every((row) => row.every((cell) => cell != ''))) {
      return 'draw';
    }
    return '';
  }

  void _updateState(List<List<String>> newBoard, String winner) {
    List<List<bool>> winningCells = state.winningCells;
    int playerXWins = state.playerXWins;
    int playerOWins = state.playerOWins;
    int draws = state.draws;

    if (winner.isNotEmpty) {
      _moveTimer?.cancel();
      winningCells = _getWinningCells(newBoard, winner);
      if (winner == 'X') {
        playerXWins++;
      } else if (winner == 'O') {
        playerOWins++;
      } else if (winner == 'draw') {
        draws++;
      }
      _saveWins();
    }
    state = state.copyWith(
      board: newBoard,
      winner: winner,
      winningCells: winningCells,
      playerXWins: playerXWins,
      playerOWins: playerOWins,
      draws: draws,
    );
  }

  List<List<bool>> _getWinningCells(List<List<String>> board, String winner) {
    if (winner == 'draw') return List.generate(3, (_) => List.filled(3, false));
    final winningCells = List.generate(3, (_) => List.filled(3, false));
    for (var i = 0; i < 3; i++) {
      if (board[i][0] == winner && board[i][1] == winner && board[i][2] == winner) {
        winningCells[i][0] = winningCells[i][1] = winningCells[i][2] = true;
      }
      if (board[0][i] == winner && board[1][i] == winner && board[2][i] == winner) {
        winningCells[0][i] = winningCells[1][i] = winningCells[2][i] = true;
      }
    }
    if (board[0][0] == winner && board[1][1] == winner && board[2][2] == winner) {
      winningCells[0][0] = winningCells[1][1] = winningCells[2][2] = true;
    }
    if (board[0][2] == winner && board[1][1] == winner && board[2][0] == winner) {
      winningCells[0][2] = winningCells[1][1] = winningCells[2][0] = true;
    }
    return winningCells;
  }

  void resetGame() {
    _moveTimer?.cancel();
    String firstPlayer = 'X';
    if (firstMove == FirstMove.winner && _lastWinner.isNotEmpty) {
      firstPlayer = _lastWinner;
    } else if (firstMove == FirstMove.o) {
      firstPlayer = 'O';
    }

    state = state.copyWith(
      board: List.generate(3, (_) => List.filled(3, '')),
      currentPlayer: firstPlayer,
      winner: '',
      winningCells: List.generate(3, (_) => List.filled(3, false)),
      moveTimeLeft: 30,
    );
    if (isSinglePlayer && state.currentPlayer == 'O') {
      Future.delayed(const Duration(milliseconds: 500), _aiMove);
    }
    if (state.timerEnabled && !isSinglePlayer) {
      _startMoveTimer();
    }
  }

  void resetAllScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('playerXWins', 0);
    await prefs.setInt('playerOWins', 0);
    await prefs.setInt('draws', 0);
    state = state.copyWith(playerXWins: 0, playerOWins: 0, draws: 0);
  }

  void setSinglePlayer(bool value) {
    isSinglePlayer = value;
    resetGame();
  }

  void setDifficulty(Difficulty newDifficulty) {
    difficulty = newDifficulty;
    _ai = AI(difficulty: newDifficulty);
    resetGame();
  }

  void setFirstMovePref(FirstMove newFirstMove) async {
    firstMove = newFirstMove;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('firstMove', newFirstMove.index);
    resetGame();
  }

  void setPlayerNames(String xName, String oName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playerXName', xName);
    await prefs.setString('playerOName', oName);
    state = state.copyWith(playerXName: xName, playerOName: oName);
  }

  void setTimerEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timerEnabled', enabled);
    state = state.copyWith(timerEnabled: enabled);
    if (enabled && state.winner.isEmpty) {
      _startMoveTimer();
    } else {
      _moveTimer?.cancel();
    }
  }

  void _startMoveTimer() {
    if (!state.timerEnabled || isSinglePlayer) return;
    _moveTimer?.cancel();
    state = state.copyWith(moveTimeLeft: 30);
    _moveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.moveTimeLeft > 0) {
        state = state.copyWith(moveTimeLeft: state.moveTimeLeft - 1);
      } else {
        timer.cancel();
        _switchPlayer();
      }
    });
  }
}

final ticTacToeProvider = StateNotifierProvider<TicTacToeNotifier, TicTacToeState>((ref) {
  return TicTacToeNotifier();
});

class AI {
  final Difficulty difficulty;
  AI({required this.difficulty});

  int getMove(List<List<String>> board) {
    switch (difficulty) {
      case Difficulty.easy: return _getRandomMove(board);
      case Difficulty.medium: return _getMediumMove(board);
      case Difficulty.hard: return _getHardMove(board);
    }
  }
  // All other AI methods remain the same
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
        final winner = _checkBoardWinner(board);
        board[row][col] = '';
        if (winner == 'O') {
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
        final winner = _checkBoardWinner(board);
        board[row][col] = '';
        if (winner == 'X') {
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

  String _checkBoardWinner(List<List<String>> board) {
    for (var i = 0; i < 3; i++) {
      if (board[i][0] == board[i][1] && board[i][1] == board[i][2] && board[i][0] != '') return board[i][0];
      if (board[0][i] == board[1][i] && board[1][i] == board[2][i] && board[0][i] != '') return board[0][i];
    }
    if (board[0][0] == board[1][1] && board[1][1] == board[2][2] && board[0][0] != '') return board[0][0];
    if (board[0][2] == board[1][1] && board[1][1] == board[2][0] && board[0][2] != '') return board[0][2];
    if (board.every((row) => row.every((cell) => cell != ''))) return 'draw';
    return '';
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
    final winner = _checkBoardWinner(board);
    if (winner == 'O') return 10 - depth;
    if (winner == 'X') return depth - 10;
    if (winner == 'draw') return 0;

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