
import 'package:flutter/material.dart';
import 'package:statushub/router/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:statushub/screens/splash_animation.dart';
import 'package:statushub/screens/splash_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin  {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _moveUpAnimation;

  String _currentText = '';
  bool _showText = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750), // quick and smooth
    );

    // Scale animation: 0 -> 1.2 -> 1.0 (snappy bounce)
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Vertical move: start below and move smoothly to center
    _moveUpAnimation = Tween<double>(begin: 80.0, end: 0.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _startTextSequence();
      }
    });
  }

  Future<void> _startTextSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));

    await _animateText('Status Hub', displayDuration: 500);
    await _animateText('Save Stories', displayDuration: 500);
    await _animateText('Recover Messages', displayDuration: 500);
    await _animateText('Direct Messages', displayDuration: 500);

    setState(() => _showText = false);

    // Smoothly move icon down to exact center
    final endController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _moveUpAnimation = Tween<double>(
      begin: _moveUpAnimation.value, // current offset
      end: 0.0,                      // center
    ).animate(CurvedAnimation(
      parent: endController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: _scaleAnimation.value,
      end: 1.0, // keep size normal
    ).animate(CurvedAnimation(
      parent: endController,
      curve: Curves.easeInOut,
    ));

    endController.forward();

    endController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        endController.dispose();

        // Use fade transition to navigate
        context.pushNamed(
          RouteNames.home,
          extra: const {"fade": true}, // optional flag if you want to detect in router
        );
      }
    });

  }


  Future<void> _animateText(String newText,
      {int displayDuration = 600}) async {
    // Pop-out old text
    setState(() => _currentText = '');
    await Future.delayed(const Duration(milliseconds: 200));

    // Pop-in new text
    setState(() => _currentText = newText);
    await Future.delayed(Duration(milliseconds: displayDuration));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const WhatsAppBackground(),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _moveUpAnimation.value),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/icon.png',
                          width: 150,
                          height: 150,
                        ),
                        if (_showText)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              final curvedAnim = CurvedAnimation(
                                  parent: animation, curve: Curves.easeOutBack);
                              return ScaleTransition(
                                scale: curvedAnim,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              _currentText,
                              key: ValueKey<String>(_currentText),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


