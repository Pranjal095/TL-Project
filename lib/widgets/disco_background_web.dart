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
  
  // Reduce number of lights further for better performance
  final int numberOfLights = 6; // Further reduced from 10 to 6
  final int numberOfFocusLights = 2; // Add 2 focus lights
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    
    // Create animation controller with slower but continuous animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 60), // Much slower animation (was 40)
      vsync: this,
    )..repeat();
    
    // Generate random disco lights
    _discoLights = List.generate(numberOfLights, (_) => DiscoLight(random));
    
    // Generate focus lights
    _focusLights = List.generate(numberOfFocusLights, (_) => FocusLight(random));
    
    // Keep animation continuous but less frequent state updates
    _animationController.addListener(() {
      // Update state every 500ms but keep animation running
      if ((_animationController.value * 6).floor() % 3 == 0) {
        setState(() {
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
        
        // Video layer with low opacity
        if (widget.isVideoInitialized)
          Opacity(
            opacity: 0.3,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain, // Changed to contain as requested
                child: SizedBox(
                  width: widget.videoController.value.size.width,
                  height: widget.videoController.value.size.height,
                  child: VideoPlayer(widget.videoController),
                ),
              ),
            ),
          ),
          
        // Floor grid - optimized with less frequent repainting
        RepaintBoundary(
          child: CustomPaint(
            painter: DiscoFloorPainter(),
            size: Size.infinite,
          ),
        ),
          
        // Disco ball reflection effect - reduced from 3 to 2
        ...List.generate(2, (index) {
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
                    Colors.white.withOpacity(0.2 + random.nextDouble() * 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        }),
        
        // Disco lights - optimized with RepaintBoundary
        RepaintBoundary(
          child: Stack(
            children: _discoLights.map((light) {
              return CustomPaint(
                painter: DiscoLightPainter(light),
                size: Size.infinite,
              );
            }).toList(),
          ),
        ),
        
        // 3D Focus lights - the new feature
        ..._focusLights.map((focusLight) {
          return AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: focusLight.position.dx * size.width - 100,
            top: focusLight.position.dy * size.height - 100,
            width: 200,
            height: 200,
            child: Transform(
              transform: Matrix4.identity()
                ..rotateX(focusLight.rotation.dx)
                ..rotateY(focusLight.rotation.dy),
              alignment: Alignment.center,
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
                    focal: Alignment(
                      focusLight.focalPoint.dx,
                      focusLight.focalPoint.dy,
                    ),
                    focalRadius: 0.1,
                  ),
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

class DiscoLightPainter extends CustomPainter {
  final DiscoLight light;
  
  DiscoLightPainter(this.light);
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = light.x * size.width;
    final centerY = light.y * size.height;
    final radius = size.width * light.radius;
    
    // Create a gradient for the light
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          light.color,
          light.color.withOpacity(0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: radius,
        ),
      );
    
    // Draw the light cone
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius,
      ),
      light.startAngle,
      light.sweepAngle,
      true,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(DiscoLightPainter oldDelegate) {
    return oldDelegate.light != light;
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

class DiscoFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Increase grid size for better performance
    const gridSize = 70.0; // Further increased to 70
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
