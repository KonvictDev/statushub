import 'dart:math';
import 'package:flutter/material.dart';

class TruthOrDareHome extends StatefulWidget {
  @override
  _TruthOrDareHomeState createState() => _TruthOrDareHomeState();
}

class _TruthOrDareHomeState extends State<TruthOrDareHome>
    with SingleTickerProviderStateMixin {
  final List<String> players = [];
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _angle = 0.0;
  String? selectedPlayer;
  String? challenge;
  bool _isSpinning = false;

  final List<String> truths = [
    "What is your biggest fear?",
    "Have you ever lied to your best friend?",
    "What's the most embarrassing thing you've done?",
    "Who was your first crush?",
    "What secret have you never told anyone?",
    "What's the weirdest dream you've ever had?",
    "Have you ever cheated on a test?",
    "What's the most trouble you've gotten into?",
  ];

  final List<String> dares = [
    "Do 10 push-ups.",
    "Sing a song loudly.",
    "Act like a monkey for 30 seconds.",
    "Dance without music for 1 minute.",
    "Say the alphabet backwards.",
    "Let the group style your hair however they want.",
    "Imitate a famous person until someone guesses who it is.",
    "Speak in an accent for the next 3 rounds.",
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
  }

  void _addPlayer() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        players.add(_controller.text.trim());
        _controller.clear();
      });
    }
  }

  void _removePlayer(String player) {
    setState(() {
      players.remove(player);
      if (selectedPlayer == player) {
        selectedPlayer = null;
        challenge = null;
      }
    });
  }

  void _spinBottle() {
    if (players.isEmpty || _isSpinning) return;

    setState(() {
      _isSpinning = true;
      challenge = null;
    });

    final random = Random();
    final chosenIndex = random.nextInt(players.length);
    final angleStep = (2 * pi) / players.length;

    final targetAngle = chosenIndex * angleStep;
    final randomTurns = random.nextInt(3) + 5; // 5–7 full turns
    final newAngle = (2 * pi * randomTurns) + targetAngle;

    _animation = Tween<double>(begin: _angle, end: newAngle).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.reset();
    _animationController.forward();

    _animationController.addListener(() {
      setState(() {
        _angle = _animation.value;
      });
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          selectedPlayer = players[chosenIndex];
          _isSpinning = false;
        });
      }
    });
  }

  void _pickTruth() {
    final random = Random();
    setState(() {
      challenge = "Truth: ${truths[random.nextInt(truths.length)]}";
    });
  }

  void _pickDare() {
    final random = Random();
    setState(() {
      challenge = "Dare: ${dares[random.nextInt(dares.length)]}";
    });
  }

  void _resetGame() {
    setState(() {
      selectedPlayer = null;
      challenge = null;
      _angle = 0.0;
      _animationController.reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildPlayerCircle(double radius) {
    if (players.isEmpty) {
      return Center(
        child: Text(
          "Add players to start",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final angleStep = (2 * pi) / players.length;
    List<Widget> widgets = [];

    for (int i = 0; i < players.length; i++) {
      final angle = i * angleStep;
      final x = radius * cos(angle);
      final y = radius * sin(angle);

      widgets.add(
        Positioned(
          left: radius + x - 30,
          top: radius + y - 10,
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  players[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _removePlayer(players[i]),
                  child: Icon(Icons.close, size: 16, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(children: widgets);
  }

  Widget _buildBottle() {
    return Container(
      width: 24,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown[700]!, Colors.brown[400]!, Colors.brown[700]!],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double circleRadius = 140;

    return Scaffold(
      appBar: AppBar(
        title: Text("Truth or Dare"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (players.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _resetGame,
              tooltip: "Reset Game",
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple, Colors.deepPurple],
          ),
        ),
        child: SingleChildScrollView( // ✅ prevents overflow
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Add Player
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              labelText: "Enter Player Name",
                              border: InputBorder.none,
                              contentPadding:
                              EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addPlayer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text("Add"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Player list
              if (players.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: players
                            .map((player) => Chip(
                          label: Text(player),
                          deleteIcon: Icon(Icons.close, size: 16),
                          onDeleted: () => _removePlayer(player),
                        ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 16),

              // Circle with players + bottle
              SizedBox(
                height: 300,
                width: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: circleRadius * 2,
                      height: circleRadius * 2,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                    ),
                    _buildPlayerCircle(circleRadius),
                    GestureDetector(
                      onTap: _isSpinning ? null : _spinBottle,
                      child: Transform.rotate(
                        angle: _angle,
                        child: _buildBottle(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              if (_isSpinning)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Spinning...",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

              if (selectedPlayer != null && !_isSpinning) ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "🎉 It's $selectedPlayer's turn!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Truth or Dare buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding:
                        EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _pickTruth,
                      child: Text("Truth", style: TextStyle(fontSize: 16)),
                    ),
                    SizedBox(width: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding:
                        EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _pickDare,
                      child: Text("Dare", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ],

              if (challenge != null) ...[
                SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: EdgeInsets.all(20),
                    child: Text(
                      challenge!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
