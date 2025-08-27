import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/tic_tac_toe_logic.dart';

class TicTacToeScreen extends ConsumerStatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  ConsumerState<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends ConsumerState<TicTacToeScreen> {
  final TextEditingController xNameController = TextEditingController();
  final TextEditingController oNameController = TextEditingController();

  @override
  void dispose() {
    xNameController.dispose();
    oNameController.dispose();
    super.dispose();
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Scores?'),
          content: const Text('This will reset all win counts to zero.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(ticTacToeProvider.notifier).resetAllScores();
                Navigator.pop(context);
              },
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showNameInputDialog() {
    final state = ref.read(ticTacToeProvider);
    xNameController.text = state.playerXName;
    oNameController.text = state.playerOName;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Player Names'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: xNameController,
                decoration: const InputDecoration(
                  labelText: 'Player X Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: oNameController,
                decoration: const InputDecoration(
                  labelText: 'Player O Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
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
        );
      },
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: notifier.resetGame,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.blue),
            onSelected: (value) {
              if (value == 'reset_scores') {
                _showResetConfirmation();
              } else if (value == 'change_names') {
                _showNameInputDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'change_names',
                child: Text('Change Player Names'),
              ),
              const PopupMenuItem(
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
            _buildPlayerHeader(state),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
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
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: state.winningCells[row][col]
                              ? Colors.amber[100]
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: state.winningCells[row][col]
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
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              state.board[row][col],
                              key: ValueKey('${row}_${col}_${state.board[row][col]}'),
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: state.board[row][col] == 'X'
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
            const SizedBox(height: 24),
            _buildGameControls(state, notifier),
            const SizedBox(height: 16),
            if (state.winner.isNotEmpty) _buildWinnerAnnouncement(state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeader(TicTacToeState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _PlayerBadge(
          name: state.playerXName,
          score: state.playerXWins,
          isActive: state.currentPlayer == 'X' && state.winner.isEmpty,
          isX: true,
        ),
        Column(
          children: [
            const Text('VS', style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text('${state.draws} draws', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        _PlayerBadge(
          name: state.playerOName,
          score: state.playerOWins,
          isActive: state.currentPlayer == 'O' && state.winner.isEmpty,
          isX: false,
        ),
      ],
    );
  }

  Widget _buildGameControls(TicTacToeState state, TicTacToeNotifier notifier) {
    return Column(
      children: [
        if (state.timerEnabled && !notifier.isSinglePlayer) ...[
          LinearProgressIndicator(
            value: state.moveTimeLeft / 30,
            backgroundColor: Colors.grey[200],
            color: Colors.blue,
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text(
            '${state.moveTimeLeft} seconds left',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _GameOptionChip(
              icon: notifier.isSinglePlayer ? Icons.person : Icons.people,
              label: notifier.isSinglePlayer ? 'Single' : 'Multi',
              onTap: () {
                notifier.setSinglePlayer(!notifier.isSinglePlayer);
              },
            ),
            if (notifier.isSinglePlayer)
              _GameOptionChip(
                icon: Icons.smart_toy,
                label: notifier.difficulty.toString().split('.').last,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: Difficulty.values.map((diff) {
                          return ListTile(
                            title: Text(diff.toString().split('.').last),
                            trailing: notifier.difficulty == diff ? const Icon(Icons.check) : null,
                            onTap: () {
                              notifier.setDifficulty(diff);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            _GameOptionChip(
              icon: Icons.swap_horiz,
              label: notifier.firstMove == FirstMove.winner
                  ? 'Winner'
                  : notifier.firstMove == FirstMove.x
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
                                ? '${state.playerXName} First'
                                : '${state.playerOName} First',
                          ),
                          trailing: notifier.firstMove == move ? const Icon(Icons.check) : null,
                          onTap: () {
                            notifier.setFirstMovePref(move);
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

  Widget _buildWinnerAnnouncement(TicTacToeState state, TicTacToeNotifier notifier) {
    return Column(
      children: [
        Text(
          state.winner == 'draw'
              ? "It's a Draw!"
              : "${state.winner == 'X' ? state.playerXName : state.playerOName} Wins!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: state.winner == 'X' ? Colors.blue : Colors.pink,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: notifier.resetGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text(
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            style: const TextStyle(
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
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
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}