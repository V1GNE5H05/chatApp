import 'package:chatapp/game/purple%20pairs/purple_pairs.dart';
import 'package:flutter/material.dart';
import 'brick.dart'; 

class GameApp extends StatelessWidget {
  const GameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Launcher',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:  GameScreen(), // Set HomeScreen as the main screen
    );
  }
}

class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Launcher'),
      ),
      body: GridView.count(
        crossAxisCount: 2, // Two games per row
        padding: const EdgeInsets.all(16),
        children: [
          _buildGameTile(
            context,
            imagePath: 'assets/brick_breaker.png', // Path to your image
            title: "Brick Breaker",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Brickstart()),
              );
            },
          ),
          _buildGameTile(
            context,
            imagePath: 'assets/brick_breaker.png', // Path to your image
            title: "Purple Pairs",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => game2()),
              );
            },
          ),
          // Add more games here
        ],
      ),
    );
  }

  Widget _buildGameTile(BuildContext context,
      {required String imagePath,
      required String title,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}