import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class game2 extends StatelessWidget {
  const game2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purble Pairs',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PurblePairsGame(),
    );
  }
}

class PurblePairsGame extends StatefulWidget {
  const PurblePairsGame({Key? key}) : super(key: key);

  @override
  State<PurblePairsGame> createState() => _PurblePairsGameState();
}

class _PurblePairsGameState extends State<PurblePairsGame> {
  // Game levels
  final List<String> difficultiesName = ['Beginner', 'Intermediate', 'Advanced'];
  final List<int> gridSizes = [5, 6, 8]; // Grid sizes for each level
  final List<int> gridCounts = [1, 2, 4]; // Number of grids for each level
  
  int currentLevel = 0; // 0:Beginner, 1:Intermediate, 2:Advanced
  int currentGrid = 0; // Current grid being played (0 to gridCounts[currentLevel]-1)
  int turns = 0; // Number of turns taken
  int? remainingTime; // Timer for timed levels
  Timer? gameTimer;
  bool gameOver = false;
  
  // Game state
  late List<List<CardItem>> gameBoards;
  List<CardItem?> flippedCards = [];
  bool canFlip = true;
  
  // Special card types
  static const int TYPE_NORMAL = 0;
  static const int TYPE_JESTER = 1;
  static const int TYPE_SHUFFLE = 2;
  static const int TYPE_ADDTIME = 3;
  static const int TYPE_AUTOMATCH = 4;
  
  // Assets needed (you'll need to add these to your pubspec.yaml)
  // These are the filenames you should use for your assets
  final Map<String, String> cardAssets = {
    'back': 'assets/card_back.png',
    'ironman': 'assets/ironman.png',
    'captain': 'assets/captain_america.png',
    'thor': 'assets/thor.png',
    'hulk': 'assets/hulk.png',
    'blackwidow': 'assets/black_widow.png',
    'hawkeye': 'assets/hawkeye.png',
    'spiderman': 'assets/spiderman.png',
    'scarletwitch': 'assets/scarlet_witch.png',
    'vision': 'assets/vision.png',
    'blackpanther': 'assets/black_panther.png',
    'drstrange': 'assets/dr_strange.png',
    'antman': 'assets/antman.png',
    'wasp': 'assets/wasp.png',
    'falcon': 'assets/falcon.png',
    'wintersoldier': 'assets/winter_soldier.png',
    'starlord': 'assets/starlord.png',
    'gamora': 'assets/gamora.png',
    'groot': 'assets/groot.png',
    'rocket': 'assets/rocket.png',
    'drax': 'assets/drax.png',
    'mantis': 'assets/mantis.png',
    'nebula': 'assets/nebula.png',
    'loki': 'assets/loki.png',
    'quicksilver': 'assets/quicksilver.png',
    'captainmarvel': 'assets/captain_marvel.png',
    'warmachine': 'assets/war_machine.png',
    'jester': 'assets/jester.png',
    'shuffle': 'assets/shuffle.png',
    'clock': 'assets/clock.png',
    'chef': 'assets/chef.png',
    'sneakpeek': 'assets/sneak_peek.png',
  };
  
  List<String> normalCardTypes = [
    'ironman', 'captain', 'thor', 'hulk', 'blackwidow', 'hawkeye', 'spiderman',
    'scarletwitch', 'vision', 'blackpanther', 'drstrange', 'antman', 'wasp',
    'falcon', 'wintersoldier', 'starlord', 'gamora', 'groot', 'rocket', 'drax',
    'mantis', 'nebula', 'loki', 'quicksilver', 'captainmarvel', 'warmachine'
  ];
  
  List<String> specialCardTypes = ['jester', 'shuffle', 'clock', 'chef'];
  
  bool sneakPeekAvailable = true;
  bool isSnakePeeking = false;
  
  @override
  void initState() {
    super.initState();
    initGame();
  }
  
  void initGame() {
    // Initialize game board(s) based on current level
    gameBoards = [];
    turns = 0;
    gameOver = false;
    sneakPeekAvailable = true;
    
    final gridSize = gridSizes[currentLevel];
    final numGrids = gridCounts[currentLevel];
    
    // Set up timer for intermediate and advanced levels
    if (currentLevel > 0) {
      remainingTime = 180 - (currentLevel * 30); // 3 minutes for intermediate, 2 minutes for advanced
      startTimer();
    } else {
      remainingTime = null;
    }
    
    // Initialize each grid
    for (int gridIndex = 0; gridIndex < numGrids; gridIndex++) {
      List<CardItem> board = [];
      
      // Calculate how many pairs we need
      int pairsNeeded = (gridSize * gridSize) ~/ 2;
      
      // Add special cards based on level
      int specialCardCount = min(currentLevel * 2, specialCardTypes.length);
      List<String> availableSpecialCards = List.from(specialCardTypes.take(specialCardCount));
      
      // Add special card pairs first
      for (int i = 0; i < min(specialCardCount, pairsNeeded); i++) {
        if (availableSpecialCards.isNotEmpty) {
          String specialType = availableSpecialCards.removeAt(Random().nextInt(availableSpecialCards.length));
          int specialCardTypeIndex = specialCardTypes.indexOf(specialType) + 1; // +1 because TYPE_NORMAL is 0
          
          board.add(CardItem(specialType, false, true, specialCardTypeIndex));
          board.add(CardItem(specialType, false, true, specialCardTypeIndex));
          pairsNeeded--;
        }
      }
      
      // Shuffle normal card types for variety across games
      List<String> shuffledNormalCards = List.from(normalCardTypes)..shuffle();
      
      // Add normal card pairs to fill the rest of the board
      for (int i = 0; i < pairsNeeded; i++) {
        String cardType = shuffledNormalCards[i % shuffledNormalCards.length];
        board.add(CardItem(cardType, false, false, TYPE_NORMAL));
        board.add(CardItem(cardType, false, false, TYPE_NORMAL));
      }
      
      // Shuffle the board
      board.shuffle();
      gameBoards.add(board);
    }
    
    currentGrid = 0; // Start with the first grid
    flippedCards = [];
  }
  
  void startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTime! > 0) {
          remainingTime = remainingTime! - 1;
        } else {
          // Game over due to time
          gameTimer?.cancel();
          gameOver = true;
        }
      });
    });
  }
  
  void addTime() {
    if (remainingTime != null) {
      setState(() {
        remainingTime = remainingTime! + 30; // Add 30 seconds
      });
    }
  }
  
  void flipCard(int index) {
    if (!canFlip || gameBoards[currentGrid][index].isMatched || gameBoards[currentGrid][index].isFlipped || gameOver) {
      return;
    }
    
    setState(() {
      gameBoards[currentGrid][index].isFlipped = true;
      flippedCards.add(gameBoards[currentGrid][index]);
      
      if (flippedCards.length == 2) {
        turns++;
        canFlip = false;
        
        // Check if the cards match
        if (flippedCards[0]!.cardType == flippedCards[1]!.cardType) {
          // Match found
          for (var card in flippedCards) {
            int cardIndex = gameBoards[currentGrid].indexOf(card!);
            gameBoards[currentGrid][cardIndex].isMatched = true;
          }
          
          // Handle special card effects
          handleSpecialCardEffects();
          
          // Clear the flipped cards and allow flipping again
          flippedCards = [];
          canFlip = true;
          
          // Check if the current grid is complete
          if (isGridComplete()) {
            handleGridComplete();
          }
        } else {
          // No match, flip cards back after a delay
          Future.delayed(const Duration(milliseconds: 1000), () {
            setState(() {
              for (var card in flippedCards) {
                int cardIndex = gameBoards[currentGrid].indexOf(card!);
                gameBoards[currentGrid][cardIndex].isFlipped = false;
              }
              flippedCards = [];
              canFlip = true;
            });
          });
        }
      }
    });
  }
  
  void handleSpecialCardEffects() {
    // Get the special card type (if any)
    int? specialType;
    
    for (var card in flippedCards) {
      if (card!.isSpecial) {
        specialType = card.specialType;
        break;
      }
    }
    
    if (specialType != null) {
      switch (specialType) {
        case TYPE_JESTER:
          // Find another pair automatically
          findAnotherPair();
          break;
        case TYPE_SHUFFLE:
          // Shuffle the board
          shuffleRemainingCards();
          break;
        case TYPE_ADDTIME:
          // Add more time
          addTime();
          break;
        case TYPE_AUTOMATCH:
          // Auto-match cake cards (in this case, we'll match a random Avenger)
          autoMatchRandomAvenger();
          break;
      }
    }
  }
  
  void findAnotherPair() {
    // Find a pair of unmatched cards
    List<int> unmatchedIndices = [];
    Map<String, List<int>> cardTypeIndices = {};
    
    for (int i = 0; i < gameBoards[currentGrid].length; i++) {
      if (!gameBoards[currentGrid][i].isMatched && !gameBoards[currentGrid][i].isFlipped) {
        unmatchedIndices.add(i);
        
        String cardType = gameBoards[currentGrid][i].cardType;
        cardTypeIndices[cardType] = cardTypeIndices[cardType] ?? [];
        cardTypeIndices[cardType]!.add(i);
      }
    }
    
    // Find a matching pair
    for (var entry in cardTypeIndices.entries) {
      if (entry.value.length >= 2) {
        // We found a pair
        setState(() {
          for (int i = 0; i < 2; i++) {
            int index = entry.value[i];
            gameBoards[currentGrid][index].isFlipped = true;
            gameBoards[currentGrid][index].isMatched = true;
          }
        });
        
        // Check if the grid is complete after this match
        if (isGridComplete()) {
          handleGridComplete();
        }
        return;
      }
    }
  }
  
  void shuffleRemainingCards() {
    List<CardItem> unmatchedCards = [];
    List<int> unmatchedIndices = [];
    
    // Collect all unmatched cards
    for (int i = 0; i < gameBoards[currentGrid].length; i++) {
      if (!gameBoards[currentGrid][i].isMatched) {
        unmatchedCards.add(gameBoards[currentGrid][i]);
        unmatchedIndices.add(i);
      }
    }
    
    // Shuffle the unmatched cards
    unmatchedCards.shuffle();
    
    // Place the shuffled cards back
    setState(() {
      for (int i = 0; i < unmatchedCards.length; i++) {
        gameBoards[currentGrid][unmatchedIndices[i]] = unmatchedCards[i];
      }
    });
  }
  
  void autoMatchRandomAvenger() {
    // Find a non-special card pair to match
    List<String> availableAvengers = [];
    
    for (int i = 0; i < gameBoards[currentGrid].length; i++) {
      CardItem card = gameBoards[currentGrid][i];
      if (!card.isMatched && !card.isSpecial && !availableAvengers.contains(card.cardType)) {
        // Count how many of this type are still unmatched
        int count = 0;
        for (int j = 0; j < gameBoards[currentGrid].length; j++) {
          if (!gameBoards[currentGrid][j].isMatched && 
              gameBoards[currentGrid][j].cardType == card.cardType) {
            count++;
          }
        }
        
        if (count >= 2) {
          availableAvengers.add(card.cardType);
        }
      }
    }
    
    if (availableAvengers.isNotEmpty) {
      // Pick a random avenger to match
      String avengerToMatch = availableAvengers[Random().nextInt(availableAvengers.length)];
      
      setState(() {
        for (int i = 0; i < gameBoards[currentGrid].length; i++) {
          if (!gameBoards[currentGrid][i].isMatched && 
              gameBoards[currentGrid][i].cardType == avengerToMatch) {
            gameBoards[currentGrid][i].isFlipped = true;
            gameBoards[currentGrid][i].isMatched = true;
          }
        }
      });
      
      // Check if the grid is complete after this match
      if (isGridComplete()) {
        handleGridComplete();
      }
    }
  }
  
  bool isGridComplete() {
    return gameBoards[currentGrid].every((card) => card.isMatched);
  }
  
  void handleGridComplete() {
    if (currentGrid < gridCounts[currentLevel] - 1) {
      // Move to the next grid
      setState(() {
        currentGrid++;
      });
    } else {
      // All grids complete, game won
      gameTimer?.cancel();
      setState(() {
        gameOver = true;
      });
      
      // Show completion dialog
      Future.delayed(const Duration(milliseconds: 500), () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Congratulations!'),
            content: Text('You completed the ${difficultiesName[currentLevel]} level in $turns turns.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Optionally go to next level
                  if (currentLevel < difficultiesName.length - 1) {
                    setState(() {
                      currentLevel++;
                      initGame();
                    });
                  } else {
                    setState(() {
                      currentLevel = 0;
                      initGame();
                    });
                  }
                },
                child: Text(currentLevel < difficultiesName.length - 1 ? 'Next Level' : 'Play Again'),
              ),
            ],
          ),
        );
      });
    }
  }
  
  void useSneakPeek() {
    if (!sneakPeekAvailable || gameOver) {
      return;
    }
    
    setState(() {
      sneakPeekAvailable = false;
      isSnakePeeking = true;
      
      // Flip all cards
      for (int i = 0; i < gameBoards[currentGrid].length; i++) {
        if (!gameBoards[currentGrid][i].isMatched) {
          gameBoards[currentGrid][i].isFlipped = true;
          turns++; // Count each exposed card as a turn
        }
      }
    });
    
    // Flip them back after a delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        for (int i = 0; i < gameBoards[currentGrid].length; i++) {
          if (!gameBoards[currentGrid][i].isMatched) {
            gameBoards[currentGrid][i].isFlipped = false;
          }
        }
        isSnakePeeking = false;
        canFlip = true;
      });
    });
  }
  
  void restartGame() {
    gameTimer?.cancel();
    setState(() {
      initGame();
    });
  }
  
  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    int gridSize = gridSizes[currentLevel];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Purble Pairs - ${difficultiesName[currentLevel]}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: restartGame,
          ),
        ],
      ),
      body: Column(
        children: [
          // Game info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Turns: $turns', style: const TextStyle(fontSize: 18)),
                if (remainingTime != null)
                  Text(
                    'Time: ${remainingTime! ~/ 60}:${(remainingTime! % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 18,
                      color: remainingTime! < 30 ? Colors.red : Colors.black,
                    ),
                  ),
                if (gridCounts[currentLevel] > 1)
                  Text('Grid: ${currentGrid + 1}/${gridCounts[currentLevel]}', style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
          
          // Game grid
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                    ),
                    itemCount: gridSize * gridSize,
                    itemBuilder: (context, index) {
                      if (index < gameBoards[currentGrid].length) {
                        return CardWidget(
                          card: gameBoards[currentGrid][index],
                          onTap: () => flipCard(index),
                          cardAssets: cardAssets,
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: sneakPeekAvailable && !gameOver ? useSneakPeek : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sneakPeekAvailable ? Colors.amber : Colors.grey,
                  ),
                  child: const Text('Sneak Peek'),
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: currentLevel,
                  items: List.generate(difficultiesName.length, (index) {
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(difficultiesName[index]),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        currentLevel = value;
                        restartGame();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CardItem {
  final String cardType;
  bool isFlipped;
  bool isMatched;
  final bool isSpecial;
  final int specialType; // 0: normal, 1: jester, 2: shuffle, 3: addtime, 4: automatch

  CardItem(this.cardType, this.isFlipped, this.isSpecial, this.specialType, {this.isMatched = false});
}

class CardWidget extends StatelessWidget {
  final CardItem card;
  final VoidCallback onTap;
  final Map<String, String> cardAssets;

  const CardWidget({
    Key? key,
    required this.card,
    required this.onTap,
    required this.cardAssets,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3.0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          firstChild: cardBack(),
          secondChild: cardFront(),
          crossFadeState: card.isFlipped ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        ),
      ),
    );
  }

  Widget cardBack() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        image: DecorationImage(
          image: AssetImage(cardAssets['back']!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget cardFront() {
    return Container(
      decoration: BoxDecoration(
        color: card.isMatched ? Colors.green.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: card.isMatched ? Colors.green : Colors.grey,
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          cardAssets[card.cardType]!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}