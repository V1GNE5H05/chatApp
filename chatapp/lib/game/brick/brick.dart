import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class Brickstart extends StatefulWidget {
  const Brickstart({super.key});

  @override
  State<Brickstart> createState() => _BrickstartState();
}

class _BrickstartState extends State<Brickstart> {
  // Game settings and constants
  static double ballRadius = 0.02;
  static double playerWidth = 0.4; // Player width (percentage of screen width)
  static double playerHeight = 0.025; // Player height
  static double brickHeight = 0.04; // Brick height
  static int numberOfRows = 3; // Number of brick rows
  static int bricksPerRow = 5; // Bricks per row
  static double brickGap = 0.01; // Gap between bricks
  static double wallGap = 0.06; // Gap from the wall

  // Game state variables
  bool hasGameStarted = false;
  bool isPlayerDead = false;
  double playerX = 0.0; // Initial player horizontal position (centered)
  double ballX = 0.0; // Initial ball horizontal position (centered)
  double ballY = 0.0; // Initial ball vertical position
  double ballXSpeed = 0.01; // How fast the ball moves horizontally
  double ballYSpeed = 0.01; // How fast the ball moves vertically
  String ballDirection = 'down'; // Ball movement direction
  String ballHorizontalDirection = 'right'; // Horizontal direction
  
  // Score tracking
  int currentScore = 0;
  int highScore = 0;

  // Timer for game loop
  Timer? gameTimer;
  
  // Bricks list
  List<Brick> bricks = [];

  // Power-ups list
  List<PowerUp> powerUps = [];
  bool hasPlayerExtension = false; // Player width power-up
  bool hasBallSpeedReduction = false; // Ball speed power-up
  
  @override
  void initState() {
    super.initState();
    resetGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void resetGame() {
    // Reset game state
    setState(() {
      hasGameStarted = false;
      isPlayerDead = false;
      playerX = 0.0;
      ballX = 0.0;
      ballY = 0.0;
      ballDirection = 'down';
      ballHorizontalDirection = 'right';
      ballXSpeed = 0.01;
      ballYSpeed = 0.01;
      
      // Reset player width if it was changed by power-up
      if (hasPlayerExtension) {
        playerWidth = 0.4;
        hasPlayerExtension = false;
      }
      
      // Reset ball speed if it was changed by power-up
      if (hasBallSpeedReduction) {
        ballXSpeed = 0.01;
        ballYSpeed = 0.01;
        hasBallSpeedReduction = false;
      }
      
      // Clear power-ups
      powerUps.clear();
      
      // Reset score (but keep high score)
      if (currentScore > highScore) {
        highScore = currentScore;
      }
      currentScore = 0;
      
      // Initialize bricks
      initializeBricks();
    });
  }
  
  void initializeBricks() {
    bricks.clear();
    
    // Calculate the wall gap dynamically based on other parameters
    wallGap = (2 - (bricksPerRow * brickHeight) - ((bricksPerRow - 1) * brickGap)) / 2;
    
    // Create bricks for multiple rows
    for (int row = 0; row < numberOfRows; row++) {
      for (int i = 0; i < bricksPerRow; i++) {
        // Calculate x position for brick
        double brickX = -1 + wallGap + i * (2 - 2 * wallGap) / bricksPerRow;
        // Calculate y position based on row
        double brickY = -0.9 + (row * (brickHeight + brickGap));
        
        // Assign different colors to different rows
        Color brickColor;
        if (row == 0) {
          brickColor = Colors.red;
        } else if (row == 1) {
          brickColor = Colors.orange;
        } else {
          brickColor = Colors.yellow;
        }
        
        // Add new brick to list
        bricks.add(
          Brick(
            x: brickX,
            y: brickY,
            width: (2 - 2 * wallGap) / bricksPerRow - brickGap,
            height: brickHeight,
            isBroken: false,
            color: brickColor,
          ),
        );
      }
    }
  }

  void startGame() {
    if (!hasGameStarted && !isPlayerDead) {
      setState(() {
        hasGameStarted = true;
      });
      
      // Start game loop
      gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        // Update game state
        moveBall();
        checkForBrokenBricks();
        updatePowerUps();
        checkIfPlayerDead();
        
        // Check if all bricks are broken - level complete
        if (bricks.every((brick) => brick.isBroken)) {
          // Add more bricks and continue game
          setState(() {
            // Increase difficulty by adding more bricks or increasing speed
            ballXSpeed += 0.002;
            ballYSpeed += 0.002;
            initializeBricks();
            // Add bonus points for completing a level
            currentScore += 50;
          });
        }
      });
    }
  }

  void moveBall() {
    setState(() {
      // Handle vertical movement
      if (ballDirection == 'down') {
        ballY += ballYSpeed;
      } else {
        ballY -= ballYSpeed;
      }
      
      // Handle horizontal movement
      if (ballHorizontalDirection == 'right') {
        ballX += ballXSpeed;
      } else {
        ballX -= ballXSpeed;
      }
      
      // Check if ball hits the sides of the screen
      if (ballX >= 1.0) {
        ballHorizontalDirection = 'left';
      } else if (ballX <= -1.0) {
        ballHorizontalDirection = 'right';
      }
      
      // Check if ball hits the top of the screen
      if (ballY <= -1.0) {
        ballDirection = 'down';
      }
      
      // Check if ball hits the player's paddle
      if (ballY >= 0.9 && ballX >= playerX - playerWidth / 2 && ballX <= playerX + playerWidth / 2) {
        ballDirection = 'up';
        
        // Advanced ball physics: direction based on where it hits the paddle
        double hitPosition = (ballX - playerX) / (playerWidth / 2);
        // Adjust horizontal direction and speed based on hit position
        ballXSpeed = 0.01 + (0.01 * hitPosition.abs());
        if (hitPosition < 0) {
          ballHorizontalDirection = 'left';
        } else {
          ballHorizontalDirection = 'right';
        }
      }
    });
  }
  
  // Method to determine which side of a brick was hit
  String findMinimumDistance(double distLeft, double distRight, double distTop, double distBottom) {
    List<double> distances = [distLeft, distRight, distTop, distBottom];
    List<String> directions = ['left', 'right', 'top', 'bottom'];
    
    double minDist = distances[0];
    String minDir = directions[0];
    
    for (int i = 1; i < distances.length; i++) {
      if (distances[i] < minDist) {
        minDist = distances[i];
        minDir = directions[i];
      }
    }
    
    return minDir;
  }

  void checkForBrokenBricks() {
    // Check each brick
    for (int i = 0; i < bricks.length; i++) {
      if (!bricks[i].isBroken) {
        // Calculate brick boundaries
        double brickLeft = bricks[i].x - bricks[i].width / 2;
        double brickRight = bricks[i].x + bricks[i].width / 2;
        double brickTop = bricks[i].y - bricks[i].height / 2;
        double brickBottom = bricks[i].y + bricks[i].height / 2;
        
        // Check if ball is within brick boundaries
        if (ballX >= brickLeft && 
            ballX <= brickRight && 
            ballY >= brickTop && 
            ballY <= brickBottom) {
          
          // Calculate distances to each side of the brick
          double distLeft = (ballX - brickLeft).abs();
          double distRight = (ballX - brickRight).abs();
          double distTop = (ballY - brickTop).abs();
          double distBottom = (ballY - brickBottom).abs();
          
          // Determine bounce direction based on collision side
          String collisionSide = findMinimumDistance(distLeft, distRight, distTop, distBottom);
          
          // Set ball direction based on collision side
          if (collisionSide == 'left' || collisionSide == 'right') {
            ballHorizontalDirection = collisionSide == 'left' ? 'left' : 'right';
          } else {
            ballDirection = collisionSide == 'top' ? 'up' : 'down';
          }
          
          // Mark brick as broken
          setState(() {
            bricks[i].isBroken = true;
            // Increment score
            currentScore += 10;
            
            // Randomly create power-up
            if (Math.random() < 0.2) { // 20% chance
              createPowerUp(bricks[i].x, bricks[i].y);
            }
          });
          
          break;
        }
      }
    }
  }
  
  // Create a power-up at brick position
  void createPowerUp(double x, double y) {
    // Randomly select power-up type (0 = extend paddle, 1 = slow ball)
    int powerUpType = (Math.random() * 2).floor();
    
    setState(() {
      powerUps.add(
        PowerUp(
          x: x,
          y: y,
          type: powerUpType,
          isActive: false,
        ),
      );
    });
  }
  
  // Update power-ups positions and check collisions
  void updatePowerUps() {
    for (int i = 0; i < powerUps.length; i++) {
      setState(() {
        // Move power-up down
        powerUps[i].y += 0.01;
        
        // Check if power-up is collected by player
        if (powerUps[i].y >= 0.9 && 
            powerUps[i].x >= playerX - playerWidth / 2 && 
            powerUps[i].x <= playerX + playerWidth / 2 &&
            !powerUps[i].isActive) {
          
          // Activate power-up
          powerUps[i].isActive = true;
          
          // Apply power-up effect
          if (powerUps[i].type == 0) {
            // Extend paddle
            playerWidth = 0.6;
            hasPlayerExtension = true;
            
            // Schedule to reset after 10 seconds
            Future.delayed(const Duration(seconds: 10), () {
              if (mounted) {
                setState(() {
                  playerWidth = 0.4;
                  hasPlayerExtension = false;
                });
              }
            });
          } else {
            // Slow ball
            ballXSpeed = 0.005;
            ballYSpeed = 0.005;
            hasBallSpeedReduction = true;
            
            // Schedule to reset after 10 seconds
            Future.delayed(const Duration(seconds: 10), () {
              if (mounted) {
                setState(() {
                  ballXSpeed = 0.01;
                  ballYSpeed = 0.01;
                  hasBallSpeedReduction = false;
                });
              }
            });
          }
        }
        
        // Remove power-up if it falls off screen
        if (powerUps[i].y > 1.1) {
          powerUps.removeAt(i);
          i--;
        }
      });
    }
  }

  void checkIfPlayerDead() {
    if (ballY >= 1.0) {
      setState(() {
        isPlayerDead = true;
        hasGameStarted = false;
      });
      gameTimer?.cancel();
    }
  }

  void moveLeft() {
    setState(() {
      if (playerX - 0.2 < -1 + playerWidth / 2) {
        playerX = -1 + playerWidth / 2;
      } else {
        playerX -= 0.2;
      }
    });
  }

  void moveRight() {
    setState(() {
      if (playerX + 0.2 > 1 - playerWidth / 2) {
        playerX = 1 - playerWidth / 2;
      } else {
        playerX += 0.2;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            moveLeft();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            moveRight();
          }
        }
      },
      child: GestureDetector(
        onTap: startGame,
        onHorizontalDragUpdate: (details) {
          // Mobile control - slide finger to move
          if (hasGameStarted) {
            setState(() {
              // Convert drag delta to player movement
              double normalizedDelta = details.delta.dx / MediaQuery.of(context).size.width;
              playerX += normalizedDelta * 2;
              
              // Ensure player stays within bounds
              if (playerX - playerWidth / 2 < -1) {
                playerX = -1 + playerWidth / 2;
              } else if (playerX + playerWidth / 2 > 1) {
                playerX = 1 - playerWidth / 2;
              }
            });
          }
        },
        child: Scaffold(
          backgroundColor: Colors.deepPurple[100],
          body: Center(
            child: Stack(
              children: [
                // Game title
                AnimatedOpacity(
                  opacity: hasGameStarted ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    alignment: const Alignment(0, -0.5),
                    child: Text(
                      'BRICK BREAKER',
                      style: TextStyle(
                        color: Colors.deepPurple[800],
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                
                // Tap to play
                AnimatedOpacity(
                  opacity: hasGameStarted ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    alignment: const Alignment(0, -0.1),
                    child: Text(
                      'Tap to play',
                      style: TextStyle(
                        color: Colors.deepPurple[400],
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                
                // Score display
                Container(
                  alignment: const Alignment(0, -0.95),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Score: $currentScore',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Best: $highScore',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Power-up indicator
                if (hasPlayerExtension || hasBallSpeedReduction)
                  Container(
                    alignment: const Alignment(0, -0.85),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasPlayerExtension) 
                          const Chip(
                            backgroundColor: Colors.green,
                            label: Text('Extended Paddle', style: TextStyle(color: Colors.white)),
                          ),
                        if (hasPlayerExtension && hasBallSpeedReduction)
                          const SizedBox(width: 10),
                        if (hasBallSpeedReduction)
                          const Chip(
                            backgroundColor: Colors.blue,
                            label: Text('Slow Ball', style: TextStyle(color: Colors.white)),
                          ),
                      ],
                    ),
                  ),
                
                // Game over screen
                if (isPlayerDead)
                  GameOverScreen(
                    onTap: resetGame,
                    score: currentScore,
                  ),
                
                // The ball
                if (!isPlayerDead)
                  MyBall(
                    ballX: ballX,
                    ballY: ballY,
                    radius: ballRadius,
                    hasGameStarted: hasGameStarted,
                    hasBallSpeedReduction: hasBallSpeedReduction,
                  ),
                
                // The player
                if (!isPlayerDead)
                  MyBrick(
                    x: playerX,
                    y: 0.9,
                    width: playerWidth,
                    height: playerHeight,
                    color: hasPlayerExtension ? Colors.green : Colors.deepPurple,
                  ),
                
                // The bricks
                if (!isPlayerDead)
                  ...bricks.map((brick) {
                    if (!brick.isBroken) {
                      return MyBrick(
                        x: brick.x,
                        y: brick.y,
                        width: brick.width,
                        height: brick.height,
                        color: brick.color,
                      );
                    } else {
                      return Container(); // Return empty container for broken bricks
                    }
                  }).toList(),
                
                // Power-ups
                if (!isPlayerDead)
                  ...powerUps.map((powerUp) {
                    if (!powerUp.isActive) {
                      return Container(
                        alignment: Alignment(powerUp.x, powerUp.y),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.05,
                          height: MediaQuery.of(context).size.width * 0.05,
                          decoration: BoxDecoration(
                            color: powerUp.type == 0 ? Colors.green : Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              powerUp.type == 0 ? '+' : '↓', 
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Container(); // Return empty container for active power-ups
                    }
                  }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom ball widget
class MyBall extends StatelessWidget {
  final double ballX;
  final double ballY;
  final double radius;
  final bool hasGameStarted;
  final bool hasBallSpeedReduction;

  const MyBall({
    super.key,
    required this.ballX,
    required this.ballY,
    required this.radius,
    required this.hasGameStarted,
    required this.hasBallSpeedReduction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment(ballX, ballY),
      child: Container(
        width: MediaQuery.of(context).size.width * radius,
        height: MediaQuery.of(context).size.width * radius,
        decoration: BoxDecoration(
          color: hasBallSpeedReduction ? Colors.blue : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom brick widget
class MyBrick extends StatelessWidget {
  final double x;
  final double y;
  final double width;
  final double height;
  final Color color;

  const MyBrick({
    super.key,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment(x, y),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: MediaQuery.of(context).size.width * width / 2,
          height: MediaQuery.of(context).size.height * height / 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Game Over Screen widget
class GameOverScreen extends StatelessWidget {
  final Function() onTap;
  final int score;

  const GameOverScreen({
    super.key, 
    required this.onTap,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: const Alignment(0, 0),
        color: Colors.deepPurple.withOpacity(0.8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Score: $score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.deepPurple[400],
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Tap to Play Again',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Brick class for tracking game state
class Brick {
  final double x;
  final double y;
  final double width;
  final double height;
  bool isBroken;
  final Color color;

  Brick({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.isBroken,
    required this.color,
  });
}

// Power-up class
class PowerUp {
  final double x;
  double y;
  final int type; // 0 = extend paddle, 1 = slow ball
  bool isActive;
  
  PowerUp({
    required this.x,
    required this.y,
    required this.type,
    required this.isActive,
  });
}

// Math utility for random numbers
class Math {
  static double random() {
    return DateTime.now().millisecondsSinceEpoch % 100 / 100;
  }
}