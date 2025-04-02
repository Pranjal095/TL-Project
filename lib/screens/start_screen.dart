import 'dart:math';
import 'package:flutter/material.dart';
import 'ddr_simulator_screen.dart';
import '../models/enums.dart';

class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<DiscoSpot> _discoSpots = [];
  final List<DiscoFlare> _discoFlares = [];
  final List<DiscoBallLightRay> _discoBallRays = [];
  final Random random = Random();
  double _animationValue = 0.0;

  double discoBallAngle = 0.0;

  // Add selected game mode and difficulty state
  GameMode selectedGameMode = GameMode.math; // Default to math mode
  DifficultyLevel selectedDifficulty = DifficultyLevel.easy;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 120),
      vsync: this,
    )..repeat();

    for (int i = 0; i < 25; i++) {
      _discoSpots.add(DiscoSpot(random));
    }

    for (int i = 0; i < 10; i++) {
      _discoFlares.add(DiscoFlare(random));
    }

    for (int i = 0; i < 30; i++) {
      _discoBallRays.add(DiscoBallLightRay(random));
    }

    _controller.addListener(() {
      if (!mounted) return; // Prevent setState calls after dispose
      _animationValue = _controller.value;
      discoBallAngle = _animationValue * 2 * pi * 0.1;

      for (var spot in _discoSpots) {
        spot.update(_animationValue);
      }

      for (var flare in _discoFlares) {
        flare.update(_animationValue);
      }

      for (var ray in _discoBallRays) {
        ray.update(discoBallAngle);
      }

      if ((_controller.value * 10).floor() % 1 == 0) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        height: size.height,
        width: size.width,
        child: Stack(
          children: [
            // Background container
            Container(
              height: size.height,
              width: size.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.deepPurple.shade900.withOpacity(0.5),
                    Colors.black,
                  ],
                ),
              ),
            ),
            
            // Constrained CustomPaint widgets
            SizedBox(
              height: size.height,
              width: size.width, 
              child: CustomPaint(
                painter: DiscoPerspectiveFloorPainter(_animationValue),
              ),
            ),
            SizedBox(
              height: size.height,
              width: size.width,
              child: CustomPaint(
                painter: DiscoBallRaysPainter(_discoBallRays),
              ),
            ),
            SizedBox(
              height: size.height,
              width: size.width,
              child: CustomPaint(
                painter: DiscoFlarePainter(_discoFlares),
              ),
            ),
            SizedBox(
              height: size.height,
              width: size.width,
              child: CustomPaint(
                painter: DiscoSpotsPainter(_discoSpots, _animationValue),
              ),
            ),
            
            // Disco ball and hanging string
            Positioned(
              top: -50,
              left: size.width / 2 - 50,
              child: Transform.rotate(
                angle: discoBallAngle,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Colors.white,
                        Color(0xFFCCCCCC),
                        Color(0xFF999999),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        spreadRadius: 4,
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: DiscoBallFacetsPainter(),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: size.width / 2 - 1,
              width: 2,
              height: 50,
              child: Container(
                color: Colors.grey[600],
              ),
            ),
            
            // Main content - use SingleChildScrollView here
            SingleChildScrollView(
              child: SizedBox(
                width: size.width,
                // Don't constrain the height, let it scroll
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 80), // Add padding at top
                    
                    // Disco ball mini model
                    Transform.rotate(
                      angle: -discoBallAngle,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [
                              Colors.white,
                              Color(0xFFCCCCCC),
                              Color(0xFF999999),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Title elements with Transform
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          "MATH DDR",
                          style: TextStyle(
                            fontSize: 85,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 25
                              ..color = Colors.pinkAccent.withOpacity(0.1),
                          ),
                        ),
                        Text(
                          "MATH DDR",
                          style: TextStyle(
                            fontSize: 82,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 20
                              ..color = Colors.pinkAccent.withOpacity(0.2),
                          ),
                        ),
                        Text(
                          "MATH DDR",
                          style: TextStyle(
                            fontSize: 78,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 15
                              ..color = Colors.pinkAccent.withOpacity(0.3),
                          ),
                        ),
                        Text(
                          "MATH DDR",
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.pinkAccent,
                            shadows: [
                              Shadow(
                                blurRadius: 15.0,
                                color: Colors.pinkAccent.withOpacity(0.7),
                                offset: Offset(0, 0),
                              ),
                              Shadow(
                                blurRadius: 30.0,
                                color: Colors.pinkAccent.withOpacity(0.5),
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          "SIMULATOR",
                          style: TextStyle(
                            fontSize: 58,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 15
                              ..color = Colors.purpleAccent.withOpacity(0.15),
                          ),
                        ),
                        Text(
                          "SIMULATOR",
                          style: TextStyle(
                            fontSize: 55,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 10
                              ..color = Colors.purpleAccent.withOpacity(0.2),
                          ),
                        ),
                        Text(
                          "SIMULATOR",
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.purpleAccent,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.purpleAccent.withOpacity(0.7),
                                offset: Offset(0, 0),
                              ),
                              Shadow(
                                blurRadius: 20.0,
                                color: Colors.purpleAccent.withOpacity(0.5),
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 80),
                    
                    // Game mode selection container
                    Container(
                      width: 400,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.purpleAccent.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Select Game Mode",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildGameModeButton(GameMode.classic, "Classic", Colors.blueAccent),
                              _buildGameModeButton(GameMode.math, "Math", Colors.purpleAccent),
                            ],
                          ),
                          
                          // Only show difficulty selection in math mode
                          if (selectedGameMode == GameMode.math) 
                            Column(
                              children: [
                                SizedBox(height: 25),
                                Text(
                                  "Select Difficulty",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildDifficultyButton(DifficultyLevel.easy, "Easy", Colors.green),
                                    _buildDifficultyButton(DifficultyLevel.medium, "Medium", Colors.amber),
                                    _buildDifficultyButton(DifficultyLevel.hard, "Hard", Colors.redAccent),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 40),
                    
                    // Start game button - updated to pass game mode
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purpleAccent.withOpacity(0.3 + 0.2 * sin(_controller.value * 2 * pi * 0.5)),
                                blurRadius: 15 + 10 * sin(_controller.value * 2 * pi * 0.5),
                                spreadRadius: 3 + 2 * sin(_controller.value * 2 * pi * 0.5),
                              ),
                              BoxShadow(
                                color: Colors.pinkAccent.withOpacity(0.2 + 0.1 * cos(_controller.value * 2 * pi * 0.3)),
                                blurRadius: 20,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => DDRSimulator(
                              initialDifficulty: selectedDifficulty,
                              gameMode: selectedGameMode,
                            )),
                          );
                        },
                        child: Container(
                          width: 220,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                selectedGameMode == GameMode.math ? Colors.purpleAccent : Colors.blueAccent,
                                selectedGameMode == GameMode.math ? Colors.pinkAccent : Colors.cyanAccent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(35),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "START GAME",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 50),
                    // How to play container
                    Container(
                      width: min(500, size.width * 0.9),
                      padding: EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.purpleAccent.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "How to Play:",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.purpleAccent.withOpacity(0.7),
                                  offset: Offset(0, 0),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          // Conditionally show instructions based on selected mode
                          if (selectedGameMode == GameMode.math) ...[
                            _buildInstructionItem("Solve the math equation"),
                            _buildInstructionItem("Hit arrows with the correct answer"),
                            _buildInstructionItem("Use arrow keys to hit targets"),
                            _buildInstructionItem("Perfect timing = more points"),
                            _buildInstructionItem("Wrong answers break your combo"),
                          ] else ...[
                            _buildInstructionItem("Hit the arrows as they reach the target"),
                            _buildInstructionItem("Use arrow keys to hit targets"),
                            _buildInstructionItem("Perfect timing = more points"),
                            _buildInstructionItem("Build combos for higher scores"),
                            _buildInstructionItem("Don't miss to keep your combo"),
                          ],
                          SizedBox(height: 20),
                          Center(
                            child: Text(
                              "Press ESC anytime to return to this screen",
                              style: TextStyle(
                                fontSize: 16, 
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 40), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModeButton(GameMode mode, String label, Color color) {
    bool isSelected = selectedGameMode == mode;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGameMode = mode;
        });
      },
      child: Container(
        width: 160,
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : Colors.black45,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ] : [],
        ),
        child: Column(
          children: [
            Icon(
              mode == GameMode.math ? Icons.calculate : Icons.music_note,
              color: isSelected ? color : Colors.white70,
              size: 32,
            ),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(DifficultyLevel difficulty, String label, Color color) {
    bool isSelected = selectedDifficulty == difficulty;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDifficulty = difficulty;
        });
      },
      child: Container(
        width: 110,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : Colors.black45,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ] : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: Colors.purpleAccent,
            size: 24,
          ),
          SizedBox(width: 15),
          Text(
            text,
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiscoBallRaysPainter extends CustomPainter {
  final List<DiscoBallLightRay> rays;

  DiscoBallRaysPainter(this.rays);

  @override
  void paint(Canvas canvas, Size size) {
    for (var ray in rays) {
      final paint = Paint()
        ..color = ray.color.withOpacity(ray.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ray.width
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(size.width / 2, 50),
        Offset(ray.endX * size.width, ray.endY * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DiscoBallLightRay {
  double endX;
  double endY;
  double width;
  double opacity;
  Color color;
  double angle;

  final Random random;

  DiscoBallLightRay(this.random)
      : endX = random.nextDouble(),
        endY = random.nextDouble(),
        width = 1 + random.nextDouble() * 3,
        opacity = 0.05 + random.nextDouble() * 0.15,
        color = [
          Colors.pinkAccent,
          Colors.purpleAccent,
          Colors.blueAccent,
          Colors.cyanAccent,
          Colors.yellowAccent,
          Colors.greenAccent,
        ][random.nextInt(6)],
        angle = random.nextDouble() * 2 * pi;

  void update(double ballAngle) {
    final rayAngle = angle + ballAngle;
    final distance = 0.5 + random.nextDouble() * 0.5;

    endX = 0.5 + cos(rayAngle) * distance;
    endY = 0.2 + sin(rayAngle) * distance;

    opacity = 0.05 + 0.15 * (0.5 + 0.5 * sin(angle * 5 + ballAngle * 3));
  }
}

class DiscoBallFacetsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += size.height / 10) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (double x = 0; x < size.width; x += size.width / 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DiscoPerspectiveFloorPainter extends CustomPainter {
  final double animationValue;

  DiscoPerspectiveFloorPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final vanishingPointY = size.height * 0.7;
    final vanishingPointX = size.width * 0.5;
    final perspectiveStrength = 0.8;

    final gridOffset = (animationValue * 100) % 40;

    for (double y = gridOffset; y <= size.height; y += 40) {
      final progress = y / size.height;
      final leftX = (progress * size.width * perspectiveStrength) - (size.width * perspectiveStrength * 0.5) + size.width * 0.5;
      final rightX = size.width - leftX + size.width * perspectiveStrength * 0.5;

      canvas.drawLine(
        Offset(leftX, y),
        Offset(rightX, y),
        gridPaint,
      );
    }

    for (double x = 0; x <= size.width + 40; x += 40) {
      final normalizedX = (x - vanishingPointX) / (size.width * 0.5);
      final bottomY = size.height;
      final topY = vanishingPointY - normalizedX * normalizedX * vanishingPointY * 0.2;

      canvas.drawLine(
        Offset(x, topY),
        Offset(x, bottomY),
        gridPaint,
      );
    }

    final shimmerPaint = Paint()..style = PaintingStyle.fill;

    for (double x = 40; x < size.width; x += 40) {
      for (double y = 40; y < size.height; y += 40) {
        final dx = (x / size.width) - 0.5;
        final dy = (y / size.height) - 0.5;
        final distance = sqrt(dx * dx + dy * dy);

        if (sin(distance * 10 + animationValue * 2 * pi) > 0.7) {
          final brightness = 0.1 + 0.1 * sin(distance * 10 + animationValue * 2 * pi);
          shimmerPaint.color = Colors.white.withOpacity(brightness);

          canvas.drawCircle(
            Offset(x, y),
            1.5,
            shimmerPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DiscoSpot {
  double x;
  double y;
  double size;
  Color color;
  double speed;
  double angle;
  double radius;

  final Random random;

  DiscoSpot(this.random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = 5 + random.nextDouble() * 20,
        color = [
          Colors.pinkAccent,
          Colors.purpleAccent,
          Colors.blueAccent,
          Colors.cyanAccent,
          Colors.greenAccent,
          Colors.amberAccent
        ][random.nextInt(6)].withOpacity(0.1 + random.nextDouble() * 0.3),
        speed = 0.3 + random.nextDouble() * 0.7,
        angle = random.nextDouble() * 2 * pi,
        radius = 0.05 + random.nextDouble() * 0.1;

  void update(double animationValue) {
    final newAngle = angle + speed * 0.01;
    angle = newAngle;

    final xOffset = sin(newAngle) * radius;
    final yOffset = sin(newAngle * 1.5) * radius;

    x = 0.1 + (x * 0.8) + xOffset;
    y = 0.1 + (y * 0.8) + yOffset;

    if (x < 0) x = 0;
    if (x > 1) x = 1;
    if (y < 0) y = 0;
    if (y > 1) y = 1;
  }
}

class DiscoFlare {
  double centerX;
  double centerY;
  double angle;
  double length;
  double width;
  Color color;
  double rotationSpeed;

  final Random random;

  DiscoFlare(this.random)
      : centerX = 0.2 + random.nextDouble() * 0.6,
        centerY = 0.2 + random.nextDouble() * 0.6,
        angle = random.nextDouble() * 2 * pi,
        length = 0.3 + random.nextDouble() * 0.5,
        width = 10 + random.nextDouble() * 40,
        color = [
          Colors.pinkAccent,
          Colors.purpleAccent,
          Colors.blueAccent,
          Colors.cyanAccent,
        ][random.nextInt(4)].withOpacity(0.1 + random.nextDouble() * 0.15),
        rotationSpeed = (random.nextDouble() - 0.5) * 0.5;

  void update(double animationValue) {
    angle += rotationSpeed * 0.01;
    if (angle > 2 * pi) angle -= 2 * pi;
    if (angle < 0) angle += 2 * pi;

    width = (10 + random.nextDouble() * 40) * (0.8 + 0.4 * sin(animationValue * 2 * pi));
  }
}

class DiscoFlarePainter extends CustomPainter {
  final List<DiscoFlare> flares;

  DiscoFlarePainter(this.flares);

  @override
  void paint(Canvas canvas, Size size) {
    for (var flare in flares) {
      final startX = flare.centerX * size.width;
      final startY = flare.centerY * size.height;
      final endX = startX + cos(flare.angle) * size.width * flare.length;
      final endY = startY + sin(flare.angle) * size.height * flare.length;

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            flare.color,
            flare.color.withOpacity(0),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(
          Rect.fromLTWH(startX, startY, endX - startX, endY - startY),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = flare.width
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DiscoSpotsPainter extends CustomPainter {
  final List<DiscoSpot> spots;
  final double animationValue;

  DiscoSpotsPainter(this.spots, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var spot in spots) {
      final paint = Paint()
        ..color = spot.color
        ..style = PaintingStyle.fill;

      final pulseSize = spot.size * (0.8 + 0.2 * sin(animationValue * 2 * pi + spot.angle));

      canvas.drawCircle(
        Offset(spot.x * size.width, spot.y * size.height),
        pulseSize,
        paint,
      );
    }

    // Draw shimmer effect
    final shimmerPaint = Paint()..style = PaintingStyle.fill;

    for (double x = 40; x < size.width; x += 40) {
      for (double y = 40; y < size.height; y += 40) {
        final dx = (x / size.width) - 0.5;
        final dy = (y / size.height) - 0.5;
        final distance = sqrt(dx * dx + dy * dy);

        if (sin(distance * 10 + animationValue * 2 * pi) > 0.7) {
          final brightness = 0.1 + 0.1 * sin(distance * 10 + animationValue * 2 * pi);
          shimmerPaint.color = Colors.white.withOpacity(brightness);

          canvas.drawCircle(
            Offset(x, y),
            1.5,
            shimmerPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
