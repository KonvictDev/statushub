import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Game2048.dart';
import 'tic_tac_toe_screen.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({Key? key}) : super(key: key);

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
        'title': 'Snake',
        'icon': 'assets/images/game1.png',
        'widget': null,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: games.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final game = games[index];
            return GestureDetector(
              onTap: () {
                if (game['widget'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => game['widget']),
                  );
                }
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  children: [
                    // Expanded icon
                    Expanded(
                      child: Image.asset(
                        game['icon'],
                        fit: BoxFit.cover, // fills the space
                        width: double.infinity,
                      ),
                    ),
                    // Game Title
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        game['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
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
    );
  }
}
