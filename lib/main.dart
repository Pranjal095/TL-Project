import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

enum Direction { up, down, left, right }
enum HitRating { perfect, good, bad, miss }

class Arrow {
  final Direction direction;
  double position = 0.0; // 0.0 = bottom, 1.0 = top target
  bool isHit = false;
  HitRating? hitRating;
  
  Arrow(this.direction);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DDR Simulator',
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

class _DDRSimulatorState extends State<DDRSimulator> with TickerProviderStateMixin {
  Random random = Random();
  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  String currentRating = "Beginner";
  Timer? gameTimer;
  List<Arrow> arrows = [];
  
  // Target zone ranges (percentage of lane height)
  final double perfectZone = 0.05; // ±5% of center
  final double goodZone = 0.10;    // ±10% of center
  final double badZone = 0.15;     // ±15% of center
  
  // Define fixed lane positions for precise alignment
  final Map<Direction, double> lanePositions = {
    Direction.left: 80.0,
    Direction.down: 160.0,
    Direction.up: 240.0,
    Direction.right: 320.0,
  };
  
  // Reference for last Bluetooth inputs
  Direction? lastInput;
  int lastInputTime = 0;

  HitRating? lastHitRating;
  int lastHitTime = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Start game loop - updates 30 times per second
    gameTimer = Timer.periodic(Duration(milliseconds: 33), (timer) {
      updateGame();
    });
    
    // Generate new arrows regularly
    Timer.periodic(Duration(milliseconds: 700), (timer) {
      generateArrow();
    });
    
    // Simulate Bluetooth input
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      simulateBluetoothData();
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }
  
  void generateArrow() {
    setState(() {
      // Random direction
      Direction dir = Direction.values[random.nextInt(Direction.values.length)];
      arrows.add(Arrow(dir));
    });
  }
  
  // Calculate player rating based on score and combo
  String calculateRating() {
    if (score >= 10000 && maxCombo >= 50) {
      return "Champion";
    } else if (score >= 5000 && maxCombo >= 30) {
      return "Master";
    } else if (score >= 2500 && maxCombo >= 20) {
      return "Pro";
    } else if (score >= 1000 && maxCombo >= 10) {
      return "Amateur";
    } else {
      return "Beginner";
    }
  }
  
  // Simulate processing incoming Bluetooth data
  void simulateBluetoothData() {
    // Randomly simulate button presses
    if (random.nextInt(4) > 0) { // 2/3 chance of input
      Direction input = Direction.values[random.nextInt(Direction.values.length)];
      checkHit(input);
    }
  }
  
  // Process a player input (from Bluetooth)
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
        
        // Calculate rating based on timing accuracy
        HitRating rating;
        if (closestDistance < perfectZone) {
          rating = HitRating.perfect;
          score += 100 * (combo + 1);
          combo++;
        } else {
          rating = HitRating.good;
          score += 50 * (combo + 1);
          combo++;
        }
        
        // Update max combo
        if (combo > maxCombo) {
          maxCombo = combo;
        }
        
        // Update player rating
        currentRating = calculateRating();
        
        // Store the hit rating with the arrow
        hitArrow!.hitRating = rating;
        
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
  Widget arrowWidget(Direction direction, {double? position, bool isHit = false, bool isTarget = false, HitRating? hitRating}) {
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
          border: Border.all(
            color: Colors.cyan.withOpacity(0.8), 
            width: 2
          ),
        ),
        child: Icon(icon, color: Colors.cyan.withOpacity(0.8), size: 40),
      );
    }
    
    // Get color based on hit rating
    Color arrowColor;
    if (isHit) {
      switch (hitRating) {
        case HitRating.perfect:
          arrowColor = Colors.greenAccent;
          break;
        case HitRating.good:
          arrowColor = Colors.yellowAccent;
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
        child: Icon(
          icon, 
          size: 40,
          color: arrowColor,
        ),
      ),
    );
  }

  // Rating badge widget
  Widget _buildRatingBadge() {
    Color ratingColor;
    switch (currentRating) {
      case "Champion":
        ratingColor = Colors.deepPurple;
        break;
      case "Master":
        ratingColor = Colors.redAccent;
        break;
      case "Pro":
        ratingColor = Colors.blueAccent;
        break;
      case "Amateur":
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

  @override
  Widget build(BuildContext context) {
    // Calculate if we should show the hit feedback
    bool showHitFeedback = DateTime.now().millisecondsSinceEpoch - lastHitTime < 800;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('DDR Simulator'),
        backgroundColor: Colors.black87,
        elevation: 10,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // DDR dancing screen
            Container(
              width: 400,
              height: 550,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pinkAccent, width: 4),
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.deepPurple.withOpacity(0.3)],
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
                    double left = lanePositions[arrow.direction]! - 32.5;
                    
                    return Positioned(
                      top: top - 32.5, // Center arrow vertically
                      left: left,      // Use fixed lane position
                      child: arrowWidget(
                        arrow.direction, 
                        isHit: arrow.isHit,
                        hitRating: arrow.hitRating
                      ),
                    );
                  }),
                  
                  // Target zones - using the same lane positions for perfect alignment
                  ...Direction.values.map((direction) => 
                    Positioned(
                      top: 90 - 35, // Center the targets on the hit line
                      left: lanePositions[direction]! - 35,
                      child: arrowWidget(direction, isTarget: true)
                    )
                  ),
                  
                  // Hit feedback text
                  if (showHitFeedback && lastHitRating != null)
                    Positioned(
                      top: 130,
                      left: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        opacity: showHitFeedback ? 1.0 : 0.0,
                        duration: Duration(milliseconds: 200),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: lastHitRating == HitRating.perfect 
                                  ? Colors.greenAccent 
                                  : (lastHitRating == HitRating.good 
                                      ? Colors.yellowAccent 
                                      : Colors.redAccent),
                                width: 2
                              ),
                            ),
                            child: Text(
                              lastHitRating == HitRating.perfect 
                                ? 'PERFECT!' 
                                :  'GOOD!',
                              style: TextStyle(
                                fontSize: 22, 
                                fontWeight: FontWeight.bold,
                                color: lastHitRating == HitRating.perfect 
                                  ? Colors.greenAccent 
                                  : Colors.yellowAccent 
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Score and combo display
            Container(
              width: 400,
              margin: EdgeInsets.only(top: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purpleAccent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Score: $score', 
                        style: TextStyle(
                          fontSize: 20, 
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                        )
                      ),
                      Text(
                        'Combo: $combo', 
                        style: TextStyle(
                          fontSize: 20, 
                          color: combo > 10 ? Colors.greenAccent : Colors.white,
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Max Combo: $maxCombo', 
                        style: TextStyle(
                          fontSize: 16, 
                          color: Colors.amberAccent
                        )
                      ),
                      _buildRatingBadge(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void updateGame() {
    setState(() {
      // Move all arrows upward - including hit arrows
      for (var arrow in arrows) {
        // All arrows keep moving - both hit and non-hit
        arrow.position += 0.01; // Move 1% up each frame
      }
      
      // Remove arrows that went off-screen
      arrows.removeWhere((arrow) {
        // Miss condition
        if (arrow.position > 1.2 && !arrow.isHit) {
          combo = 0;
          // Update rating after breaking combo
          currentRating = calculateRating();
          return true;
        }
        
        // Hit arrows still continue upward until they go off-screen
        if (arrow.position > 1.2) {
          return true;
        }
        
        return false;
      });
    });
  }
}