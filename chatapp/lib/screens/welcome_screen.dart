import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _animation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: const Offset(0, -0.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    _controller.forward().then((_) {
      Navigator.pushNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange[50],
      body: Stack(
        children: [
          // Welcome Message
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _opacityAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Text(
                    'Welcome to Get-Together',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepOrange[800],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Animated Icon Button
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.15,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _animation,
              child: Column(
                children: [
                  Material(
                    elevation: 8,
                    shape: const CircleBorder(),
                    color: Colors.deepOrange,
                    child: IconButton(
                      icon: Icon(
                        Icons.people_alt, 
                        size: 60, 
                        color: Colors.white,
                      ),
                      onPressed: _navigateToLogin,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
