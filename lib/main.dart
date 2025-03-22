import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

enum Direction { up, down, left, right }

enum HitRating { perfect, good, bad, miss }

class Arrow {
  final Direction direction;
  final int number; // Number displayed on the arrow
  double position = 0.0; // 0.0 = bottom, 1.0 = top target
  bool isHit = false;
  HitRating? hitRating;

  Arrow(this.direction, this.number);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math DDR Simulator',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        fontFamily: 'RobotoMono',
      ),
      home: DDRSimulator(),
    );
  }
}

class DDRSimulator extends StatefulWidget {
  @override
  _DDRSimulatorState createState() => _DDRSimulatorState();
}

class _DDRSimulatorState extends State<DDRSimulator>
    with TickerProviderStateMixin {
  // Add a focus node to capture keyboard input
  final FocusNode _focusNode = FocusNode();

  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  // Add arrow speed control variables
  double arrowBaseSpeed = 0.01; // Base speed that can be adjusted
  double arrowSpeedMultiplier =
      1.0; // Multiplier that increases with perfect hits

  Random random = Random();
  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  String currentRating = "Beginner";
  Timer? gameTimer;
  List<Arrow> arrows = [];

  // Math equation variables
  int firstNumber = 0;
  int secondNumber = 0;
  int correctAnswer = 0;
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

    // Initialize video player with better error handling for Linux
    _videoController = VideoPlayerController.asset('assets/dance.mp4');

    _videoController.initialize().then((_) {
      setState(() {
        _isVideoInitialized = true;
        _videoController.setLooping(true);
        _videoController.play();
        _videoController.setVolume(0.0); // 🔇 Mute the video
      });
    }).catchError((error) {
      print('Video player error: $error');
      setState(() {
        _isVideoInitialized = false;
      });
    });

    // Generate initial math equation
    generateMathEquation();

    // Start game loop - updates 30 times per second
    gameTimer = Timer.periodic(Duration(milliseconds: 33), (timer) {
      updateGame();
    });

    // Generate new arrows
    Timer.periodic(Duration(milliseconds: 1500), (timer) {
      generateArrow();
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _focusNode.dispose();
    _videoController.dispose();
    super.dispose();
  }

  // Handle keyboard input
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
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

  // Generate a new math addition equation
  void generateMathEquation() {
    setState(() {
      firstNumber = random.nextInt(9) + 1; // 1-9
      secondNumber = random.nextInt(9) + 1; // 1-9
      correctAnswer = firstNumber + secondNumber;
    });
  }

  void generateArrow() {
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
          do {
            number = random.nextInt(18) +
                1; // Possible sums of single digits go up to 18 (9+9)
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
            combo++; // Increase speed by 5% for perfect hits with correct answers
            arrowSpeedMultiplier *= 1.05;
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
            // Generate a new equation immediately after correct answer
            generateMathEquation();
          } else {
            score -= 10;
            combo = 0;
          }
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

  // Arrow visuals
  Widget arrowWidget(Direction direction,
      {double? position,
      bool isHit = false,
      bool isTarget = false,
      HitRating? hitRating,
      int? number}) {
    IconData icon;
    switch (direction) {
      case Direction.up:
        icon = Icons.arrow_upward;
        break;
      case Direction.down:
        icon = Icons.arrow_downward;
        break;
      case Direction.left:
        icon = Icons.arrow_back;
        break;
      case Direction.right:
        icon = Icons.arrow_forward;
        break;
    }

    // Target zones are stationary at the top
    if (isTarget) {
      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.cyan.withOpacity(0.8), width: 2),
        ),
        child: Icon(icon, color: Colors.cyan.withOpacity(0.8), size: 40),
      );
    }

    // Get color based on hit rating
    Color arrowColor;
    if (isHit) {
      switch (hitRating) {
        case HitRating.perfect:
          arrowColor =
              lastAnswerCorrect ? Colors.greenAccent : Colors.redAccent;
          break;
        case HitRating.good:
          arrowColor =
              lastAnswerCorrect ? Colors.yellowAccent : Colors.redAccent;
          break;
        case HitRating.bad:
          arrowColor = Colors.redAccent;
          break;
        default:
          arrowColor = Colors.green; // Default hit color
      }
    } else {
      arrowColor = Colors.pinkAccent; // Default non-hit color
    }

    // Active arrows that flow upward
    return AnimatedOpacity(
      opacity: isHit ? 0.7 : 1.0,
      duration: Duration(milliseconds: 200),
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: arrowColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: arrowColor.withOpacity(0.7),
              blurRadius: 12,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Icon(
            //   icon,
            //   size: 40,
            //   color: arrowColor,
            // ),
            if (number != null)
              Container(
                padding: EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Rating badge widget
  Widget _buildRatingBadge() {
    Color ratingColor;
    switch (currentRating) {
      case "Math Champion":
        ratingColor = Colors.deepPurple;
        break;
      case "Math Master":
        ratingColor = Colors.redAccent;
        break;
      case "Math Pro":
        ratingColor = Colors.blueAccent;
        break;
      case "Math Amateur":
        ratingColor = Colors.green;
        break;
      default:
        ratingColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ratingColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ratingColor.withOpacity(0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        currentRating,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // Math equation widget
  Widget _buildMathEquation() {
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
                "$firstNumber + $secondNumber = ?",
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

  void updateGame() {
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
        // Miss condition - arrow passed target without being hit
        if (arrow.position > 1.2 && !arrow.isHit) {
          // Reset combo on miss
          combo = 0;
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

// Video player widget with improved Linux support
  Widget _buildVideoPlayer(
      VideoPlayerController controller, bool isInitialized) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: 300, // Limit height to prevent overflow
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.pinkAccent, width: 4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: (isInitialized && controller.value.isInitialized)
            ? AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              )
            : Container(
                color: Colors.black,
                height: 200, // Fixed height for loading container
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.purpleAccent),
                      SizedBox(height: 16),
                      Text(
                        "Loading video...\nLinux users need codec support",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate if we should show the hit feedback
    bool showHitFeedback =
        DateTime.now().millisecondsSinceEpoch - lastHitTime < 800;

    // Wrap the entire game in a RawKeyboardListener
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Math DDR Simulator'),
          backgroundColor: Colors.black87,
          elevation: 10,
        ),
        body: Row(
          children: [
            // Left panel: DDR game
            Expanded(
              flex: 5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Arrow speed control slider
                    Container(
                      width: 400,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.purpleAccent.withOpacity(0.5),
                            width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Arrow Speed",
                                  style: TextStyle(color: Colors.white)),
                              Text(
                                  "Multiplier: ${arrowSpeedMultiplier.toStringAsFixed(2)}x",
                                  style: TextStyle(color: Colors.amberAccent)),
                            ],
                          ),
                          Slider(
                            value: arrowBaseSpeed,
                            min: 0.005,
                            max: 0.02,
                            divisions: 15,
                            activeColor: Colors.purpleAccent,
                            inactiveColor: Colors.purpleAccent.withOpacity(0.3),
                            onChanged: (value) {
                              setState(() {
                                arrowBaseSpeed = value;
                              });
                            },
                            label:
                                "${(arrowBaseSpeed * 100).toStringAsFixed(1)}%",
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),

                    // DDR dancing screen
                    Container(
                      width: 400,
                      height: 500, // Reduced height to accommodate the slider
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.pinkAccent, width: 4),
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
                            top: 90,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              color: Colors.cyan.withOpacity(0.7),
                            ),
                          ),

                          // Render all flowing arrows
                          ...arrows.map((arrow) {
                            // Calculate vertical position - map from 0.0-1.0 to bottom-top of game area
                            double top = 550 - (arrow.position * 460);

                            // Get fixed position from lanePositions
                            double left =
                                lanePositions[arrow.direction]! - 32.5;

                            return Positioned(
                              top: top - 32.5, // Center arrow vertically
                              left: left,
                              child: arrowWidget(
                                arrow.direction,
                                isHit: arrow.isHit,
                                hitRating: arrow.hitRating,
                                number: arrow.number,
                              ),
                            );
                          }).toList(),

                          // Target zones at top
                          ...Direction.values
                              .map((direction) => Positioned(
                                    top: 90 - 35, // Center on hit line
                                    left: lanePositions[direction]! - 35,
                                    child:
                                        arrowWidget(direction, isTarget: true),
                                  ))
                              .toList(),

                          // Hit feedback text
                          if (showHitFeedback && lastHitRating != null)
                            Positioned(
                              top: 150,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: lastAnswerCorrect
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    lastAnswerCorrect
                                        ? (lastHitRating == HitRating.perfect
                                            ? "PERFECT!"
                                            : "GOOD!")
                                        : "WRONG ANSWER!",
                                    style: TextStyle(
                                      color: lastAnswerCorrect
                                          ? (lastHitRating == HitRating.perfect
                                              ? Colors.greenAccent
                                              : Colors.yellowAccent)
                                          : Colors.redAccent,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
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
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Use arrow keys to hit targets",
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
                    ),

                    // Score display
                    Container(
                      width: 400,
                      margin: EdgeInsets.only(top: 16),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.purpleAccent, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Score: $score',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white)),
                              SizedBox(height: 4),
                              Text('Max Combo: $maxCombo',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.amber)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Combo: $combo',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: combo > 0
                                          ? Colors.greenAccent
                                          : Colors.white)),
                              SizedBox(height: 4),
                              _buildRatingBadge(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Middle panel: Math equation
            Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    left: BorderSide(
                        color: Colors.purple.withOpacity(0.3), width: 2),
                    right: BorderSide(
                        color: Colors.purple.withOpacity(0.3), width: 2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMathEquation(),
                    SizedBox(height: 30),
                    Text(
                      "How to Play",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "• Solve the math equation",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• Hit arrows with the correct answer",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• Press arrow keys when aligned with target",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• Perfect timing = more points",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• Wrong answers break your combo",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right panel: Video player
            Expanded(
              flex: 4,
              child: Container(
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  // Add this to make it scrollable
                  child: Column(
                    children: [
                      Text(
                        "DDR Dance Reference",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildVideoPlayer(_videoController, _isVideoInitialized),
                      SizedBox(height: 20),
                      // Video codec troubleshooting info
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.pinkAccent.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Video not playing?",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            SizedBox(height: 8),
                            Text("Linux users need to install codecs:",
                                style: TextStyle(color: Colors.white70)),
                            SizedBox(height: 4),
                            Text(
                                "sudo apt-get install ubuntu-restricted-extras",
                                style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontFamily: "monospace")),
                          ],
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
    );
  }
}
