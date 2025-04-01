import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/arrow.dart';
import '../models/enums.dart';
import '../widgets/arrow_widget.dart';
// import '../widgets/math_equation_widget.dart';
import '../widgets/rating_badge_widget.dart';
import '../widgets/video_player_widget.dart';

class DDRSimulator extends StatefulWidget {
  final DifficultyLevel initialDifficulty;

  const DDRSimulator({
    Key? key,
    this.initialDifficulty = DifficultyLevel.easy,
  }) : super(key: key);

  @override
  _DDRSimulatorState createState() => _DDRSimulatorState();
}

class _DDRSimulatorState extends State<DDRSimulator>
    with TickerProviderStateMixin {
  // Add a focus node to capture keyboard input
  final FocusNode _focusNode = FocusNode();

  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;
  double _audioVolume = 0.5;

  // Update arrow speed control variables
  double arrowBaseSpeed = 0.01; // Base speed that can be adjusted
  double arrowSpeedMultiplier = 1.0; // Multiplier that increases with perfect hits
  double speedIncreaseRate = 0.05; // How much the multiplier increases per perfect hit

  Random random = Random();
  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  String currentRating = "Beginner";
  Timer? gameTimer;
  Timer? arrowGenerationTimer; // Add a reference to the arrow generation timer
  List<Arrow> arrows = [];

  // Set difficulty from the passed parameter
  late DifficultyLevel currentDifficulty;
  MathOperation currentOperation = MathOperation.addition;

  // Math equation variables
  int firstNumber = 0;
  int secondNumber = 0;
  int correctAnswer = 0;
  String questionText = "";
  bool lastAnswerCorrect = true;
  int arrowsSinceLastCorrect = 0;

  // Target zone ranges (percentage of lane height)
  final double perfectZone = 0.05; // ±5% of center
  final double goodZone = 0.10; // ±10% of center
  final double badZone = 0.15; // ±15% of center

  // Define fixed lane positions for precise alignment
  final Map<Direction, double> lanePositions = {
    Direction.left: 80.0,
    Direction.down: 160.0,
    Direction.up: 240.0,
    Direction.right: 320.0,
  };

  // Reference for last keyboard inputs
  Direction? lastInput;
  int lastInputTime = 0;

  HitRating? lastHitRating;
  int lastHitTime = 0;

  @override
  void initState() {
    super.initState();

    // Initialize difficulty from widget parameter
    currentDifficulty = widget.initialDifficulty;

    // Set initial speed based on difficulty
    _initializeSpeedForDifficulty();

    // Initialize video player with better web support
    _initializeVideo();

    // Other initialization code
    generateMathEquation();

    gameTimer = Timer.periodic(Duration(milliseconds: 33), (timer) {
      if (mounted) {
        updateGame();
      }
    });

    // Adjust arrow generation interval based on difficulty
    int arrowInterval = _getArrowIntervalForDifficulty();
    arrowGenerationTimer = Timer.periodic(Duration(milliseconds: arrowInterval), (timer) {
      if (mounted) {
        generateArrow();
      }
    });
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/dance.mp4');

      // Add listener for video player state changes
      _videoController.addListener(() {
        if (_videoController.value.isInitialized) {
          setState(() {
            _isVideoInitialized = true;
            _isVideoPlaying = _videoController.value.isPlaying;
          });
        }
      });

      await _videoController.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _videoController.setLooping(true);
          _videoController.setVolume(_audioVolume);
          _videoController.play();
        });
      }
    } catch (e) {
      print('Failed to initialize video: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    gameTimer?.cancel(); // Cancel the game timer
    arrowGenerationTimer?.cancel(); // Cancel the arrow generation timer
    _focusNode.dispose();
    _videoController.dispose();
    super.dispose();
  }

  // Helper method to initialize speed variables based on difficulty
  void _initializeSpeedForDifficulty() {
    switch (currentDifficulty) {
      case DifficultyLevel.easy:
        arrowBaseSpeed = 0.008; // Slower base speed for beginners
        speedIncreaseRate = 0.03; // Gentler speed increase
        break;
      case DifficultyLevel.medium:
        arrowBaseSpeed = 0.012; // Medium base speed
        speedIncreaseRate = 0.05; // Standard speed increase
        break;
      case DifficultyLevel.hard:
        arrowBaseSpeed = 0.015; // Faster base speed for challenge
        speedIncreaseRate = 0.08; // Steeper speed increase for hard mode
        break;
    }
  }

  // Helper method to determine arrow generation interval based on difficulty
  int _getArrowIntervalForDifficulty() {
    switch (currentDifficulty) {
      case DifficultyLevel.easy:
        return 1800; // Slower arrow generation
      case DifficultyLevel.medium:
        return 1500; // Medium arrow generation
      case DifficultyLevel.hard:
        return 1200; // Fast arrow generation
    }
  }

  // Handle keyboard input
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Add escape key handler to return to start screen
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
        return;
      }

      // Map WASD keys to DDR directions
      if (event.logicalKey == LogicalKeyboardKey.keyW) {
        checkHit(Direction.up);
      } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
        checkHit(Direction.down);
      } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
        checkHit(Direction.left);
      } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
        checkHit(Direction.right);
      }
    }
  }

  // Generate a new math equation based on the current difficulty level
  void generateMathEquation() {
    setState(() {
      Random random = Random();

      // Choose numbers and operation based on difficulty level
      switch (currentDifficulty) {
        case DifficultyLevel.easy:
          // Single digit addition or multiplication (1-9)
          firstNumber = random.nextInt(9) + 1;
          secondNumber = random.nextInt(9) + 1;

          // Randomly choose between addition and multiplication for variety
          currentOperation = random.nextBool()
              ? MathOperation.addition
              : MathOperation.multiplication;

          if (currentOperation == MathOperation.addition) {
            correctAnswer = firstNumber + secondNumber;
            questionText = "$firstNumber + $secondNumber = ?";
          } else {
            correctAnswer = firstNumber * secondNumber;
            questionText = "$firstNumber × $secondNumber = ?";
          }
          break;

        case DifficultyLevel.medium:
          // Two-digit arithmetic (10-99)
          firstNumber = random.nextInt(90) + 10;
          secondNumber = random.nextInt(90) + 10;

          // Choose a random operation
          int opIndex = random.nextInt(4);
          currentOperation = MathOperation.values[opIndex];

          // Handle each operation type
          switch (currentOperation) {
            case MathOperation.addition:
              correctAnswer = firstNumber + secondNumber;
              questionText = "$firstNumber + $secondNumber = ?";
              break;
            case MathOperation.subtraction:
              // Ensure positive result by making first number larger
              if (firstNumber < secondNumber) {
                int temp = firstNumber;
                firstNumber = secondNumber;
                secondNumber = temp;
              }
              correctAnswer = firstNumber - secondNumber;
              questionText = "$firstNumber - $secondNumber = ?";
              break;
            case MathOperation.multiplication:
              // Use smaller numbers for multiplication to keep results reasonable
              firstNumber = random.nextInt(20) + 5;
              secondNumber = random.nextInt(10) + 2;
              correctAnswer = firstNumber * secondNumber;
              questionText = "$firstNumber × $secondNumber = ?";
              break;
            case MathOperation.division:
              // Create a clean division problem with no remainder
              secondNumber = random.nextInt(9) + 2; // Divisor between 2-10
              correctAnswer = random.nextInt(10) + 1; // Result between 1-10
              firstNumber = secondNumber * correctAnswer; // Calculate dividend
              questionText = "$firstNumber ÷ $secondNumber = ?";
              break;
          }
          break;

        case DifficultyLevel.hard:
          // Three-digit arithmetic (100-999)
          firstNumber = random.nextInt(900) + 100;
          secondNumber = random.nextInt(900) + 100;

          // Choose a random operation
          int opIndex = random.nextInt(4);
          currentOperation = MathOperation.values[opIndex];

          // Handle each operation type
          switch (currentOperation) {
            case MathOperation.addition:
              correctAnswer = firstNumber + secondNumber;
              questionText = "$firstNumber + $secondNumber = ?";
              break;
            case MathOperation.subtraction:
              // Ensure positive result
              if (firstNumber < secondNumber) {
                int temp = firstNumber;
                firstNumber = secondNumber;
                secondNumber = temp;
              }
              correctAnswer = firstNumber - secondNumber;
              questionText = "$firstNumber - $secondNumber = ?";
              break;
            case MathOperation.multiplication:
              // Use smaller numbers for multiplication to keep results reasonable
              firstNumber = random.nextInt(30) + 10;
              secondNumber = random.nextInt(20) + 5;
              correctAnswer = firstNumber * secondNumber;
              questionText = "$firstNumber × $secondNumber = ?";
              break;
            case MathOperation.division:
              // Create a clean division problem with no remainder
              secondNumber = random.nextInt(20) + 5; // Divisor between 5-24
              correctAnswer = random.nextInt(20) + 5; // Result between 5-24
              firstNumber = secondNumber * correctAnswer; // Calculate dividend
              questionText = "$firstNumber ÷ $secondNumber = ?";
              break;
          }
          break;
      }
    });
  }

  void generateArrow() {
    if (!mounted) return; // Safety check

    setState(() {
      // Random direction
      Direction dir = Direction.values[random.nextInt(Direction.values.length)];

      // Generate a number for the arrow
      int number;

      // Force correct answer if we haven't had one in the last 3 arrows
      if (arrowsSinceLastCorrect >= 3) {
        number = correctAnswer;
        arrowsSinceLastCorrect = 0; // Reset counter
      } else {
        // Otherwise use probability-based approach
        if (random.nextDouble() < 0.3) {
          // 30% chance of correct answer
          number = correctAnswer;
          arrowsSinceLastCorrect = 0; // Reset counter
        } else {
          // Generate a random number that is not the correct answer
          int maxPossible;

          // Set range based on difficulty
          switch (currentDifficulty) {
            case DifficultyLevel.easy:
              maxPossible = 81; // 9*9 maximum possible result
              break;
            case DifficultyLevel.medium:
              maxPossible = 9999; // Large enough for medium difficulty
              break;
            case DifficultyLevel.hard:
              maxPossible = 99999; // Large enough for hard difficulty
              break;
          }

          do {
            // Keep the wrong answers somewhat close to the correct one
            int range = (correctAnswer > 100) ? correctAnswer : 100;
            int minVal = max(1, correctAnswer - range ~/ 2);
            int maxVal = correctAnswer + range ~/ 2;
            number = minVal + random.nextInt(maxVal - minVal);
          } while (number == correctAnswer);

          // Increment counter since we generated an incorrect answer
          arrowsSinceLastCorrect++;
        }
      }

      arrows.add(Arrow(dir, number));
    });
  }

  // Calculate player rating based on score and combo
  String calculateRating() {
    if (score >= 10000 && maxCombo >= 50) {
      return "Math Champion";
    } else if (score >= 5000 && maxCombo >= 30) {
      return "Math Master";
    } else if (score >= 2500 && maxCombo >= 20) {
      return "Math Pro";
    } else if (score >= 1000 && maxCombo >= 10) {
      return "Math Amateur";
    } else {
      return "Math Beginner";
    }
  }

  // Process a player input (from keyboard)
  void checkHit(Direction input) {
    // Find the nearest arrow in the target zone with matching direction
    Arrow? hitArrow;
    double closestDistance = double.infinity;

    for (var arrow in arrows) {
      if (arrow.direction == input && !arrow.isHit) {
        // Calculate distance from target (1.0 is perfect)
        double distance = (arrow.position - 1.0).abs();

        // Only consider arrows near the target
        if (distance < badZone && distance < closestDistance) {
          closestDistance = distance;
          hitArrow = arrow;
        }
      }
    }

    if (hitArrow != null) {
      setState(() {
        hitArrow!.isHit = true;

        // Check if the number on the arrow is the correct answer
        bool isCorrectAnswer = hitArrow.number == correctAnswer;
        lastAnswerCorrect = isCorrectAnswer;

        // Calculate rating based on timing accuracy
        HitRating rating;
        if (closestDistance < perfectZone) {
          rating = HitRating.perfect;
          // Award or penalize based on correctness
          if (isCorrectAnswer) {
            score += 100 * (combo + 1);
            combo++;
            // Use difficulty-specific speed increase rate
            arrowSpeedMultiplier *= (1.0 + speedIncreaseRate);
            // Generate a new equation immediately after correct answer
            generateMathEquation();
          } else {
            score -= 20;
            combo = 0;
          }
        } else {
          rating = HitRating.good;
          if (isCorrectAnswer) {
            score += 50 * (combo + 1);
            combo++;
            // Smaller speed increase for good hits
            arrowSpeedMultiplier *= (1.0 + (speedIncreaseRate / 2));
            // Generate a new equation immediately after correct answer
            generateMathEquation();
          } else {
            score -= 10;
            combo = 0;
          }
        }

        // Cap the speed multiplier to prevent the game from becoming impossible
        double maxMultiplier = _getMaxSpeedMultiplier();
        if (arrowSpeedMultiplier > maxMultiplier) {
          arrowSpeedMultiplier = maxMultiplier;
        }

        // Prevent negative score
        if (score < 0) score = 0;

        // Update max combo
        if (combo > maxCombo) {
          maxCombo = combo;
        }

        // Update player rating
        currentRating = calculateRating();

        // Store the hit rating with the arrow
        hitArrow.hitRating = rating;

        // Store the hit rating to display feedback
        lastHitRating = rating;
        lastHitTime = DateTime.now().millisecondsSinceEpoch;

        // Store last input for visual feedback
        lastInput = input;
        lastInputTime = DateTime.now().millisecondsSinceEpoch;
      });
    }
  }

  // Get maximum speed multiplier based on difficulty
  double _getMaxSpeedMultiplier() {
    switch (currentDifficulty) {
      case DifficultyLevel.easy:
        return 2.0; // Max 2x speed for easy
      case DifficultyLevel.medium:
        return 3.0; // Max 3x speed for medium
      case DifficultyLevel.hard:
        return 5.0; // Max 5x speed for hard
    }
  }

  void updateGame() {
    if (!mounted) return; // Safety check

    setState(() {
      final currentSpeed = arrowBaseSpeed * arrowSpeedMultiplier;

      // Move all arrows upward
      for (var arrow in arrows) {
        // Non-hit arrows move at normal speed
        if (!arrow.isHit) {
          arrow.position += currentSpeed;
        } else {
          // Hit arrows move faster to clear screen
          arrow.position += currentSpeed * 3;
        }
      }

      // Remove arrows that went off-screen
      arrows.removeWhere((arrow) {
        // Remove arrows that passed without being hit
        if (arrow.position > 1.2 && !arrow.isHit) {
          // Don't reset combo on miss anymore
          return true;
        }
        // Remove hit arrows that leave the screen
        if (arrow.position > 1.2) {
          return true;
        }
        return false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate if we should show the hit feedback
    bool showHitFeedback =
        DateTime.now().millisecondsSinceEpoch - lastHitTime < 800;

    final size = MediaQuery.of(context).size;

    // Wrap the entire game in a RawKeyboardListener
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Math DDR Simulator'),
          backgroundColor: Colors.black.withOpacity(0.7),
          elevation: 10,
          // Add back button that returns to start screen
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Stack(
          children: [
            // Video player as background
            Positioned.fill(
              child: buildBackgroundVideoPlayer(
                _videoController,
                _isVideoInitialized,
                _isVideoPlaying,
                () {
                  setState(() {
                    if (_isVideoPlaying) {
                      _videoController.pause();
                    } else {
                      _videoController.play();
                    }
                  });
                },
                () {
                  setState(() {
                    _videoController.seekTo(Duration.zero);
                    _videoController.play();
                  });
                },
              ),
            ),

            // Semi-transparent overlay to make content more visible
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top controls panel
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.black54,
                    child: Row(
                      children: [
                        // Display current difficulty instead of a selector
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.purpleAccent.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text("Difficulty: ",
                                  style: TextStyle(color: Colors.white, fontSize: 14)),
                              SizedBox(width: 8),
                              _buildDifficultyBadge(currentDifficulty),
                            ],
                          ),
                        ),

                        SizedBox(width: 16),

                        // Arrow speed control - now shows current speed
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.purpleAccent.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text("Arrow Speed:",
                                    style: TextStyle(color: Colors.white, fontSize: 14)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: arrowSpeedMultiplier / _getMaxSpeedMultiplier(),
                                    backgroundColor: Colors.purpleAccent.withOpacity(0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "${(arrowSpeedMultiplier).toStringAsFixed(2)}x",
                                  style: TextStyle(
                                      color: Colors.amberAccent, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Audio volume control
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.purpleAccent.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _audioVolume == 0
                                      ? Icons.volume_off
                                      : (_audioVolume < 0.5
                                          ? Icons.volume_down
                                          : Icons.volume_up),
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Slider(
                                    value: _audioVolume,
                                    min: 0.0,
                                    max: 1.0,
                                    activeColor: Colors.purpleAccent,
                                    inactiveColor: Colors.purpleAccent.withOpacity(0.3),
                                    onChanged: (value) {
                                      setState(() {
                                        _audioVolume = value;
                                        _videoController.setVolume(_audioVolume);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main game area
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 1200,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left side: Math equation with compact design
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Use a direct text equation display instead of the widget
                                    buildCustomMathEquation(questionText),
                                    SizedBox(height: 16),

                                    // Score display
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.purpleAccent, width: 2),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Score: $score',
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.white)),
                                              SizedBox(height: 4),
                                              Text('Max Combo: $maxCombo',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.amber)),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text('Combo: $combo',
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: combo > 0
                                                          ? Colors.greenAccent
                                                          : Colors.white)),
                                              SizedBox(height: 4),
                                              buildRatingBadge(currentRating),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    Spacer(),

                                    // Video controls moved to the bottom of left panel
                                    if (_isVideoInitialized)
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text("Video Controls:",
                                                style: TextStyle(
                                                    color: Colors.white70)),
                                            SizedBox(width: 8),
                                            IconButton(
                                              icon: Icon(
                                                _isVideoPlaying
                                                    ? Icons.pause
                                                    : Icons.play_arrow,
                                                color: Colors.white70,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  if (_isVideoPlaying) {
                                                    _videoController.pause();
                                                  } else {
                                                    _videoController.play();
                                                  }
                                                });
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.replay,
                                                color: Colors.white70,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _videoController
                                                      .seekTo(Duration.zero);
                                                  _videoController.play();
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Right Side: Expanded DDR game
                            Expanded(
                              flex: 7,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Calculate game dimensions based on available space
                                      final gameWidth = constraints.maxWidth;
                                      final gameHeight = constraints.maxHeight;

                                      return Container(
                                        width: gameWidth,
                                        height: gameHeight,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.pinkAccent, width: 4),
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black,
                                              Colors.deepPurple.withOpacity(0.3)
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            // Hit line indicator
                                            Positioned(
                                              top: gameHeight * 0.15,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                height: 3,
                                                color: Colors.cyan.withOpacity(0.7),
                                              ),
                                            ),

                                            // Define the arrows container area with fixed width lanes
                                            Positioned.fill(
                                              child: LayoutBuilder(
                                                builder: (context, constraints) {
                                                  final totalWidth =
                                                      constraints.maxWidth;
                                                  // Fixed spacing between arrows
                                                  final laneWidth =
                                                      (totalWidth - 40) /
                                                          4; // 40px for padding

                                                  // Calculate lane center positions
                                                  final lanePositions = [
                                                    20 + laneWidth * 0.5, // Left arrow
                                                    20 + laneWidth * 1.5, // Down arrow
                                                    20 + laneWidth * 2.5, // Up arrow
                                                    20 + laneWidth * 3.5, // Right arrow
                                                  ];

                                                  return Stack(
                                                    children: [
                                                      // Target zones at top
                                                      ...Direction.values.map(
                                                          (direction) {
                                                        int index;
                                                        switch (direction) {
                                                          case Direction.left:
                                                            index = 0;
                                                            break;
                                                          case Direction.down:
                                                            index = 1;
                                                            break;
                                                          case Direction.up:
                                                            index = 2;
                                                            break;
                                                          case Direction.right:
                                                            index = 3;
                                                            break;
                                                        }

                                                        return Positioned(
                                                          top: gameHeight *
                                                                  0.15 -
                                                              35, // Center on hit line
                                                          left: lanePositions[
                                                                  index] -
                                                              35, // Center horizontally
                                                          child: buildArrowWidget(
                                                              direction,
                                                              isTarget: true),
                                                        );
                                                      }).toList(),

                                                      // Render all flowing arrows
                                                      ...arrows.map((arrow) {
                                                        // Calculate vertical position
                                                        double top = gameHeight -
                                                            (arrow.position *
                                                                gameHeight *
                                                                0.85);

                                                        // Determine lane position
                                                        int index;
                                                        switch (arrow.direction) {
                                                          case Direction.left:
                                                            index = 0;
                                                            break;
                                                          case Direction.down:
                                                            index = 1;
                                                            break;
                                                          case Direction.up:
                                                            index = 2;
                                                            break;
                                                          case Direction.right:
                                                            index = 3;
                                                            break;
                                                        }

                                                        return Positioned(
                                                          top: top -
                                                              32.5, // Center arrow vertically
                                                          left: lanePositions[
                                                                  index] -
                                                              32.5, // Center horizontally
                                                          child: buildArrowWidget(
                                                            arrow.direction,
                                                            isHit: arrow.isHit,
                                                            hitRating:
                                                                arrow.hitRating,
                                                            number: arrow.number,
                                                            lastAnswerCorrect:
                                                                lastAnswerCorrect,
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),

                                            // Hit feedback text
                                            if (showHitFeedback &&
                                                lastHitRating != null)
                                              Positioned(
                                                top: gameHeight * 0.25,
                                                left: 0,
                                                right: 0,
                                                child: Center(
                                                  child: Container(
                                                    padding: EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.7),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                        color: lastAnswerCorrect
                                                            ? Colors.greenAccent
                                                            : Colors.redAccent,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      lastAnswerCorrect
                                                          ? (lastHitRating ==
                                                                  HitRating
                                                                      .perfect
                                                              ? "PERFECT!"
                                                              : "GOOD!")
                                                          : "WRONG ANSWER!",
                                                      style: TextStyle(
                                                        color: lastAnswerCorrect
                                                            ? (lastHitRating ==
                                                                    HitRating
                                                                        .perfect
                                                                ? Colors
                                                                    .greenAccent
                                                                : Colors
                                                                    .yellowAccent)
                                                            : Colors.redAccent,
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                            // Key controls reminder
                                            Positioned(
                                              bottom: 10,
                                              left: 0,
                                              right: 0,
                                              child: Center(
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    "Use WASD keys to hit targets",
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to display the difficulty badge
  Widget _buildDifficultyBadge(DifficultyLevel difficulty) {
    String label;
    Color color;

    switch (difficulty) {
      case DifficultyLevel.easy:
        label = "Easy";
        color = Colors.green;
        break;
      case DifficultyLevel.medium:
        label = "Medium";
        color = Colors.amber;
        break;
      case DifficultyLevel.hard:
        label = "Hard";
        color = Colors.redAccent;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // Helper to build a custom math equation display
  Widget buildCustomMathEquation(String questionText) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.purpleAccent,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "SOLVE",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                questionText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
