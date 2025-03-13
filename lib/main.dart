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
  Timer? gameTimer;
  List<Arrow> arrows = [];
  
  // Target zone ranges (percentage of lane height)
  final double perfectZone = 0.05; // ±5% of center
  final double goodZone = 0.10;    // ±10% of center
  final double badZone = 0.15;     // ±15% of center
  
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
  
  // Simulate processing incoming Bluetooth data
  void simulateBluetoothData() {
    // Randomly simulate button presses
    if (random.nextInt(3) > 0) { // 2/3 chance of input
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
        
        // Calculate rating based on timing accuracy - only PERFECT or GOOD
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double arrowSpacing = 80.0;
    
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
                    
                    // Calculate horizontal position based on direction
                    double left;
                    switch (arrow.direction) {
                      case Direction.left:
                        left = 400/2 - arrowSpacing*1.5;
                        break;
                      case Direction.down:
                        left = 400/2 - arrowSpacing/2;
                        break;
                      case Direction.up:
                        left = 400/2 + arrowSpacing/2;
                        break;
                      case Direction.right:
                        left = 400/2 + arrowSpacing*1.5;
                        break;
                    }
                    
                    return Positioned(
                      top: top - 32.5, // Center arrow vertically
                      left: left - 32.5, // Center arrow horizontally
                      child: arrowWidget(
                        arrow.direction, 
                        isHit: arrow.isHit,
                        hitRating: arrow.hitRating
                      ),
                    );
                  }),
                  
                  // Target zones at top - exact same positioning
                  Positioned(
                    top: 90 - 35, // Center the targets on the hit line
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        arrowWidget(Direction.left, isTarget: true),
                        SizedBox(width: arrowSpacing - 70),
                        arrowWidget(Direction.down, isTarget: true),
                        SizedBox(width: arrowSpacing - 70),
                        arrowWidget(Direction.up, isTarget: true),
                        SizedBox(width: arrowSpacing - 70),
                        arrowWidget(Direction.right, isTarget: true),
                      ],
                    ),
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
                  
                  // Rest of UI elements remain unchanged
                  
                  // ...existing code...
                ],
              ),
            ),
            
            // Score and combo display remain unchanged
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