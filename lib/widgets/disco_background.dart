import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class DiscoBackground extends StatefulWidget {
  final VideoPlayerController videoController;
  final bool isVideoInitialized;

  const DiscoBackground({
    Key? key,
    required this.videoController,
    required this.isVideoInitialized,
  }) : super(key: key);

  @override
  _DiscoBackgroundState createState() => _DiscoBackgroundState();
}

class _DiscoBackgroundState extends State<DiscoBackground> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<DiscoLight> _discoLights;
  late List<FocusLight> _focusLights;
  
  // Further reduce number of lights for better web performance
  final int numberOfLights = 4; // Reduced from 6 to 4
  final int numberOfFocusLights = 1; // Reduced from 2 to 1
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    
    // Create animation controller with slower animation for better web performance
    _animationController = AnimationController(
      duration: const Duration(seconds: 90), // Even slower animation
      vsync: this,
    )..repeat();
    
    // Generate random disco lights
    _discoLights = List.generate(numberOfLights, (_) => DiscoLight(random));
    
    // Generate focus lights
    _focusLights = List.generate(numberOfFocusLights, (_) => FocusLight(random));
    
    // Use more efficient animation listener
    _animationController.addListener(() {
      // Update state less frequently for web
      if ((_animationController.value * 5).floor() % 5 == 0) {
        if (mounted) setState(() {
          // Update lights with slower movement
          for (var light in _discoLights) {
            light.update(_animationController.value);
          }
          
          // Update focus lights with slower movement
          for (var light in _focusLights) {
            light.update(_animationController.value);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background color
        Container(
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
        
        // Video layer with low opacity - changed to contain as requested
        if (widget.isVideoInitialized)
          Opacity(
            opacity: 0.3,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain, // Changed back to contain as requested
                child: SizedBox(
                  width: widget.videoController.value.size.width,
                  height: widget.videoController.value.size.height,
                  child: VideoPlayer(widget.videoController),
                ),
              ),
            ),
          ),
          
        // Floor grid - using RepaintBoundary for performance
        RepaintBoundary(
          child: CustomPaint(
            painter: DiscoFloorPainter(),
            size: Size.infinite,
          ),
        ),
          
        // Simplified disco effects for web
        ...List.generate(1, (index) {
          return Positioned(
            left: random.nextDouble() * size.width,
            top: random.nextDouble() * size.height,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        }),
        
        // Disco lights with fewer elements
        ..._discoLights.map((light) {
          return Positioned(
            left: light.x * size.width - 100,
            top: light.y * size.height - 100,
            width: 200,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    light.color,
                    light.color.withOpacity(0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.2, 1.0],
                ),
              ),
            ),
          );
        }).toList(),
        
        // One focus light for subtle effect
        ..._focusLights.map((focusLight) {
          return Positioned(
            left: focusLight.position.dx * size.width - 100,
            top: focusLight.position.dy * size.height - 100,
            width: 200,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    focusLight.color.withOpacity(0.7),
                    focusLight.color.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

// Existing DiscoLight class
class DiscoLight {
  double x = 0;
  double y = 0;
  double radius = 0;
  Color color = Colors.white;
  double startAngle = 0;
  double sweepAngle = 0;
  double speed = 0;
  
  final Random random;
  
  DiscoLight(this.random) {
    _initialize();
  }
  
  void _initialize() {
    // Generate random starting position at the edges
    int edge = random.nextInt(4);
    switch (edge) {
      case 0: // top
        x = random.nextDouble();
        y = 0;
        break;
      case 1: // right
        x = 1.0;
        y = random.nextDouble();
        break;
      case 2: // bottom
        x = random.nextDouble();
        y = 1.0;
        break;
      case 3: // left
        x = 0;
        y = random.nextDouble();
        break;
    }
    
    radius = 0.1 + random.nextDouble() * 0.2;
    startAngle = random.nextDouble() * 2 * pi;
    sweepAngle = (pi / 4) + random.nextDouble() * (pi / 4);
    speed = 0.002 + random.nextDouble() * 0.008; // Reduced from 0.005-0.02
    
    // Random color
    final colors = [
      Colors.pinkAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
      Colors.amberAccent,
      Colors.cyanAccent
    ];
    color = colors[random.nextInt(colors.length)].withOpacity(0.2 + random.nextDouble() * 0.3);
  }
  
  void update(double animationValue) {
    // Move the light
    startAngle += speed;
    if (startAngle > 2 * pi) {
      startAngle -= 2 * pi;
    }
    
    // Occasionally change direction
    if (random.nextDouble() < 0.01) {
      speed = 0.002 + random.nextDouble() * 0.008; // Reduced from 0.005-0.02
      speed *= random.nextBool() ? 1 : -1;
    }
  }
}

// Modify FocusLight class for slower movement
class FocusLight {
  Offset position = Offset.zero;
  Offset rotation = Offset.zero;
  Offset focalPoint = Offset.zero;
  Color color = Colors.white;
  double speed = 0.005; // Initialize with a default value, then update in _initialize
  
  final Random random;
  
  FocusLight(this.random) {
    _initialize();
  }
  
  void _initialize() {
    position = Offset(
      0.2 + random.nextDouble() * 0.6, // Keep away from edges
      0.2 + random.nextDouble() * 0.6,
    );
    
    rotation = Offset(
      random.nextDouble() * 0.3 - 0.15,
      random.nextDouble() * 0.3 - 0.15,
    );
    
    focalPoint = Offset(
      random.nextDouble() * 1.0 - 0.5,
      random.nextDouble() * 1.0 - 0.5,
    );
    
    // Pick a bright color for the spotlight
    final colors = [
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.blueAccent,
      Colors.cyanAccent,
    ];
    color = colors[random.nextInt(colors.length)];
    
    // Set random movement speed - fixed from the field initializer
    speed = 0.005 + random.nextDouble() * 0.01; // Reduced from 0.01-0.02
  }
  
  void update(double animationValue) {
    // Move the focus light in a slower pattern
    double angle = animationValue * 2 * pi * 0.5; // Slow down by multiplying by 0.5
    double radius = 0.2;
    
    // Create a flowing pattern movement
    position = Offset(
      0.5 + cos(angle) * radius + sin(angle * 2.7) * radius * 0.3,
      0.5 + sin(angle) * radius + cos(angle * 3.1) * radius * 0.2,
    );
    
    // Rotate the light for 3D effect
    rotation = Offset(
      sin(angle * 1.5) * 0.1,
      cos(angle * 1.2) * 0.1,
    );
    
    // Update focal point for dynamic light effect
    focalPoint = Offset(
      sin(angle * 2) * 0.4,
      cos(angle * 3) * 0.4,
    );
  }
}

// Simplified DiscoFloorPainter - using simple grid and no animation for better web performance
class DiscoFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Much larger grid size for better web performance
    const gridSize = 100.0; 
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
