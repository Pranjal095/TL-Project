import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart'; // Add this import for audio playback

import '../models/arrow.dart';
import '../models/enums.dart';
import '../widgets/arrow_widget.dart';
import '../widgets/rating_badge_widget.dart';
import '../widgets/video_player_widget.dart';

class DDRSimulator extends StatefulWidget {
  final DifficultyLevel initialDifficulty;
  final GameMode gameMode;

  const DDRSimulator({
    Key? key,
    this.initialDifficulty = DifficultyLevel.easy,
    this.gameMode = GameMode.math,
  }) : super(key: key);

  @override
  _DDRSimulatorState createState() => _DDRSimulatorState();
}

class _DDRSimulatorState extends State<DDRSimulator>
    with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();

  late VideoPlayerController _videoController;
  late AudioPlayer _audioPlayer; // Add AudioPlayer for music
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;
  bool _isMusicPlaying = false;
  double _audioVolume = 0.5;

  double arrowBaseSpeed = 0.01;
  double arrowSpeedMultiplier = 1.0;
  double speedIncreaseRate = 0.05;

  double initialSpeedMultiplier = 1.0;

  Random random = Random();
  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  String currentRating = "Beginner";
  Timer? gameTimer;
  Timer? arrowGenerationTimer;
  List<Arrow> arrows = [];

  late DifficultyLevel currentDifficulty;
  MathOperation currentOperation = MathOperation.addition;

  int firstNumber = 0;
  int secondNumber = 0;
  int correctAnswer = 0;
  String questionText = "";
  bool lastAnswerCorrect = true;
  int arrowsSinceLastCorrect = 0;

  final double perfectZone = 0.05;
  final double goodZone = 0.10;
  final double badZone = 0.15;

  final Map<Direction, double> lanePositions = {
    Direction.left: 80.0,
    Direction.down: 160.0,
    Direction.up: 240.0,
    Direction.right: 320.0,
  };

  Direction? lastInput;
  int lastInputTime = 0;

  HitRating? lastHitRating;
  int lastHitTime = 0;

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  bool get showHitFeedback =>
      DateTime.now().millisecondsSinceEpoch - lastHitTime < 800;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    currentDifficulty = widget.initialDifficulty;

    _initializeSpeedForDifficulty();
    arrowSpeedMultiplier = initialSpeedMultiplier;

    // Initialize video and audio based on game mode
    _initializeVideoAndAudio();

    if (widget.gameMode == GameMode.math) {
      generateMathEquation();
    } else {
      questionText = "CLASSIC MODE";
    }

    gameTimer = Timer.periodic(Duration(milliseconds: 33), (timer) {
      if (mounted) {
        updateGame();
      }
    });

    int arrowInterval = _getArrowIntervalForDifficulty();
    arrowGenerationTimer = Timer.periodic(Duration(milliseconds: arrowInterval), (timer) {
      if (mounted) {
        if (widget.gameMode == GameMode.math) {
          generateArrow();
        } else {
          generateClassicArrow();
        }
      }
    });
  }

  Future<void> _initializeVideoAndAudio() async {
    try {
      final videoOptions = ['dancer.mp4', 'dog.mp4'];
      final selectedVideo = videoOptions[widget.gameMode == GameMode.math 
          ? 1
          : 0];
      
      _videoController = VideoPlayerController.asset('assets/$selectedVideo');

      _videoController.addListener(() {
        if (_videoController.value.isInitialized) {
          setState(() {
            _isVideoInitialized = true;
            _isVideoPlaying = _videoController.value.isPlaying;
          });
        }
      });

      await _videoController.initialize();

      // Initialize audio player
      _audioPlayer = AudioPlayer();
      
      // Select music based on game mode
      final musicTrack = widget.gameMode == GameMode.math 
          ? 'assets/MathematicalVersion.mp3'
          : 'assets/NormalVersion.mp3';
          
      await _audioPlayer.setAsset(musicTrack);
      await _audioPlayer.setVolume(_audioVolume);
      _audioPlayer.setLoopMode(LoopMode.one); // Loop music

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _videoController.setLooping(true);
          _videoController.setVolume(0); // Mute video as we're playing separate music
          _videoController.play();
          
          // Start playing music
          _audioPlayer.play();
          _isMusicPlaying = true;
        });
      }
    } catch (e) {
      print('Failed to initialize media: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    gameTimer?.cancel();
    arrowGenerationTimer?.cancel();
    _focusNode.dispose();
    _videoController.dispose();
    _audioPlayer.dispose(); // Dispose audio player
    super.dispose();
  }

  void _initializeSpeedForDifficulty() {
    switch (currentDifficulty) {
      case DifficultyLevel.easy:
        arrowBaseSpeed = 0.008;
        speedIncreaseRate = 0.03;
        break;
      case DifficultyLevel.medium:
        arrowBaseSpeed = 0.012;
        speedIncreaseRate = 0.05;
        break;
      case DifficultyLevel.hard:
        arrowBaseSpeed = 0.015;
        speedIncreaseRate = 0.08;
        break;
    }
  }

  int _getArrowIntervalForDifficulty() {
    switch (currentDifficulty) {
      case DifficultyLevel.easy:
        return 1800;
      case DifficultyLevel.medium:
        return 1500;
      case DifficultyLevel.hard:
        return 1200;
    }
  }

  double _getMaxSpeedMultiplier() {
    switch (currentDifficulty) {
      case DifficultyLevel.easy:
        return 2.0;
      case DifficultyLevel.medium:
        return 3.0;
      case DifficultyLevel.hard:
        return 5.0;
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
        return;
      }

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

  void generateMathEquation() {
    setState(() {
      Random random = Random();

      switch (currentDifficulty) {
        case DifficultyLevel.easy:
          firstNumber = random.nextInt(9) + 1;
          secondNumber = random.nextInt(9) + 1;

          currentOperation = MathOperation.addition;

          correctAnswer = firstNumber + secondNumber;
          questionText = "$firstNumber + $secondNumber = ?";
          break;

        case DifficultyLevel.medium:
          firstNumber = random.nextInt(90) + 10;
          secondNumber = random.nextInt(90) + 10;

          int opIndex = random.nextInt(4);
          currentOperation = MathOperation.values[opIndex];

          switch (currentOperation) {
            case MathOperation.addition:
              correctAnswer = firstNumber + secondNumber;
              questionText = "$firstNumber + $secondNumber = ?";
              break;
            case MathOperation.subtraction:
              if (firstNumber < secondNumber) {
                int temp = firstNumber;
                firstNumber = secondNumber;
                secondNumber = temp;
              }
              correctAnswer = firstNumber - secondNumber;
              questionText = "$firstNumber - $secondNumber = ?";
              break;
            case MathOperation.multiplication:
              firstNumber = random.nextInt(20) + 5;
              secondNumber = random.nextInt(10) + 2;
              correctAnswer = firstNumber * secondNumber;
              questionText = "$firstNumber × $secondNumber = ?";
              break;
            case MathOperation.division:
              secondNumber = random.nextInt(9) + 2;
              correctAnswer = random.nextInt(10) + 1;
              firstNumber = secondNumber * correctAnswer;
              questionText = "$firstNumber ÷ $secondNumber = ?";
              break;
          }
          break;

        case DifficultyLevel.hard:
          firstNumber = random.nextInt(900) + 100;
          secondNumber = random.nextInt(900) + 100;

          int opIndex = random.nextInt(4);
          currentOperation = MathOperation.values[opIndex];

          switch (currentOperation) {
            case MathOperation.addition:
              correctAnswer = firstNumber + secondNumber;
              questionText = "$firstNumber + $secondNumber = ?";
              break;
            case MathOperation.subtraction:
              if (firstNumber < secondNumber) {
                int temp = firstNumber;
                firstNumber = secondNumber;
                secondNumber = temp;
              }
              correctAnswer = firstNumber - secondNumber;
              questionText = "$firstNumber - $secondNumber = ?";
              break;
            case MathOperation.multiplication:
              firstNumber = random.nextInt(30) + 10;
              secondNumber = random.nextInt(20) + 5;
              correctAnswer = firstNumber * secondNumber;
              questionText = "$firstNumber × $secondNumber = ?";
              break;
            case MathOperation.division:
              secondNumber = random.nextInt(20) + 5;
              correctAnswer = random.nextInt(20) + 5;
              firstNumber = secondNumber * correctAnswer;
              questionText = "$firstNumber ÷ $secondNumber = ?";
              break;
          }
          break;
      }
    });
  }

  void generateArrow() {
    if (!mounted) return;

    setState(() {
      Direction dir = Direction.values[random.nextInt(Direction.values.length)];

      int number;

      if (arrowsSinceLastCorrect >= 3) {
        number = correctAnswer;
        arrowsSinceLastCorrect = 0;
      } else {
        if (random.nextDouble() < 0.3) {
          number = correctAnswer;
          arrowsSinceLastCorrect = 0;
        } else {
          int maxPossible;

          switch (currentDifficulty) {
            case DifficultyLevel.easy:
              maxPossible = 81;
              break;
            case DifficultyLevel.medium:
              maxPossible = 9999;
              break;
            case DifficultyLevel.hard:
              maxPossible = 99999;
              break;
          }

          do {
            int range = (correctAnswer > 100) ? correctAnswer : 100;
            int minVal = max(1, correctAnswer - range ~/ 2);
            int maxVal = correctAnswer + range ~/ 2;
            number = minVal + random.nextInt(maxVal - minVal);
          } while (number == correctAnswer);

          arrowsSinceLastCorrect++;
        }
      }

      arrows.add(Arrow(dir, number));
    });
  }

  void generateClassicArrow() {
    if (!mounted) return;

    setState(() {
      Direction dir = Direction.values[random.nextInt(Direction.values.length)];
      arrows.add(Arrow(dir, 0));
    });
  }

  String calculateRating() {
    String prefix = widget.gameMode == GameMode.math ? "Math " : "Dance ";

    if (score >= 10000 && maxCombo >= 50) {
      return prefix + "Champion";
    } else if (score >= 5000 && maxCombo >= 30) {
      return prefix + "Master";
    } else if (score >= 2500 && maxCombo >= 20) {
      return prefix + "Pro";
    } else if (score >= 1000 && maxCombo >= 10) {
      return prefix + "Amateur";
    } else {
      return prefix + "Beginner";
    }
  }

  void updateGame() {
    if (!mounted) return;

    setState(() {
      final currentSpeed = arrowBaseSpeed * arrowSpeedMultiplier;

      for (var arrow in arrows) {
        if (!arrow.isHit) {
          arrow.position += currentSpeed;
        } else {
          arrow.position += currentSpeed * 3;
        }
      }

      arrows.removeWhere((arrow) {
        if (arrow.position > 1.2 && !arrow.isHit) {
          return true;
        }
        if (arrow.position > 1.2) {
          return true;
        }
        return false;
      });
    });
  }

  void checkHit(Direction input) {
    Arrow? hitArrow;
    double closestDistance = double.infinity;

    for (var arrow in arrows) {
      if (arrow.direction == input && !arrow.isHit) {
        double distance = (arrow.position - 1.0).abs();

        if (distance < badZone && distance < closestDistance) {
          closestDistance = distance;
          hitArrow = arrow;
        }
      }
    }

    if (hitArrow != null) {
      setState(() {
        hitArrow!.isHit = true;

        if (widget.gameMode == GameMode.math) {
          bool isCorrectAnswer = hitArrow.number == correctAnswer;
          lastAnswerCorrect = isCorrectAnswer;

          HitRating rating;
          if (closestDistance < perfectZone) {
            rating = HitRating.perfect;
            if (isCorrectAnswer) {
              score += 100 * (combo + 1);
              combo++;
              arrowSpeedMultiplier *= (1.0 + speedIncreaseRate);
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
              arrowSpeedMultiplier *= (1.0 + (speedIncreaseRate / 2));
              generateMathEquation();
            } else {
              score -= 10;
              combo = 0;
            }
          }
          hitArrow.hitRating = rating;
        } else {
          lastAnswerCorrect = true;

          HitRating rating;
          if (closestDistance < perfectZone) {
            rating = HitRating.perfect;
            score += 100 * (combo + 1);
            combo++;
            arrowSpeedMultiplier *= (1.0 + speedIncreaseRate * 0.8);
          } else {
            rating = HitRating.good;
            score += 50 * (combo + 1);
            combo++;
            arrowSpeedMultiplier *= (1.0 + (speedIncreaseRate / 3));
          }
          hitArrow.hitRating = rating;
        }

        double maxMultiplier = _getMaxSpeedMultiplier();
        if (arrowSpeedMultiplier > maxMultiplier) {
          arrowSpeedMultiplier = maxMultiplier;
        }

        if (score < 0) score = 0;

        if (combo > maxCombo) {
          maxCombo = combo;
        }

        currentRating = calculateRating();

        lastHitRating = hitArrow.hitRating;
        lastHitTime = DateTime.now().millisecondsSinceEpoch;

        lastInput = input;
        lastInputTime = DateTime.now().millisecondsSinceEpoch;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 1000;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('Math DDR Simulator'),
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 0,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline, color: Colors.white70),
              onPressed: () => _showHelpDialog(),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Stack(
                children: [
                  buildBackgroundVideoPlayer(
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
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.deepPurple.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _rotateController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: NeonGridPainter(
                            progress: _rotateController.value,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: isWideScreen
                ? _buildGameModeLayout()
                : _buildNarrowLayout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModeLayout() {
    // Choose layout based on game mode
    return widget.gameMode == GameMode.math
        ? _buildMathModeLayout()
        : _buildStandardModeLayout();
  }

  Widget _buildMathModeLayout() {
    // Wide layout optimized for math mode with wider game area and equation
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left stats panel
        Container(
          width: 280,
          padding: EdgeInsets.all(20),
          child: _buildStatsPanel(),
        ),
        
        // Center area (game + equation) - wider for math mode
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                child: _buildCompactEquation(),
              ),
              Expanded(
                child: _buildGameArea(),
              ),
            ],
          ),
        ),
        
        // Video area - slightly narrower
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.all(20),
            child: _buildFullVideoPlayer(),
          ),
        ),
      ],
    );
  }

  Widget _buildStandardModeLayout() {
    // Layout optimized for standard mode with game area at left and stats at right
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Game area - narrow and at leftmost side
        Container(
          width: 500, // Fixed width makes it narrower
          padding: EdgeInsets.all(20),
          child: _buildGameArea(),
        ),
        
        // Middle spacer to push content to edges
        Expanded(
          child: Container(),
        ),
        
        // Stats section - at rightmost side
        Container(
          width: 300, // Fixed width for stats panel
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Rest of the stats
              Expanded(
                child: _buildStatsPanel(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.gameMode == GameMode.math
                      ? Colors.purpleAccent.withOpacity(0.5)
                      : Colors.blueAccent.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gameMode == GameMode.math
                        ? Colors.purpleAccent.withOpacity(0.3)
                        : Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "HOW TO PLAY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 20),
                  if (widget.gameMode == GameMode.math) ...[
                    _buildHelpItem("Solve the math equation at the top", Icons.calculate),
                    _buildHelpItem("Watch for arrows with the correct answer", Icons.arrow_circle_up),
                  ] else ...[
                    _buildHelpItem("Follow the rhythm of the music", Icons.music_note),
                    _buildHelpItem("Hit arrows as they reach the target line", Icons.arrow_circle_up),
                  ],
                  _buildHelpItem("Press WASD keys when arrows reach the target", Icons.keyboard),
                  _buildHelpItem("Build combos for higher scores", Icons.bolt),
                  _buildHelpItem("Perfect timing = more points", Icons.timer),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.gameMode == GameMode.math
                              ? [Colors.purpleAccent, Colors.pinkAccent]
                              : [Colors.blueAccent, Colors.cyanAccent],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "GOT IT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.purpleAccent, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left stats panel
        Container(
          width: 300,
          padding: EdgeInsets.all(20),
          child: _buildStatsPanel(),
        ),
        
        // Center area (game + equation)
        Expanded(
          flex: 3,
          child: Column(
            children: [
              if (widget.gameMode == GameMode.math)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: _buildCompactEquation(),
                ),
              Expanded(
                child: _buildGameArea(),
              ),
            ],
          ),
        ),
        
        // Video for math mode only - takes full height
        if (widget.gameMode == GameMode.math)
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(20),
              child: _buildFullVideoPlayer(),
            ),
          ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        if (widget.gameMode == GameMode.math)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: _buildCompactEquation(),
          ),
        Expanded(
          flex: 5,
          child: _buildGameArea(),
        ),
        Container(
          height: 100,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _buildCompactStatsRow(),
        ),
      ],
    );
  }

  // Compact equation card for math mode
  Widget _buildCompactEquation() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.withOpacity(0.7),
            Colors.black.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(_glowAnimation.value * 0.2),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Text(
              questionText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.purpleAccent.withOpacity(0.7),
                    blurRadius: 8,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullVideoPlayer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video component
          _isVideoInitialized && _videoController.value.isInitialized
            ? AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              )
            : Center(
                child: CircularProgressIndicator(color: Colors.purpleAccent),
              ),
            
          // Gradient overlay for better blending
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
          
          // Simple video controls
          Positioned(
            bottom: 15,
            left: 0,
            right: 0,
            child: _isVideoInitialized ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isVideoPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  iconSize: 32,
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
                SizedBox(width: 20),
                IconButton(
                  icon: Icon(
                    _audioVolume == 0 
                        ? Icons.volume_off 
                        : (_audioVolume < 0.5 ? Icons.volume_down : Icons.volume_up),
                    color: Colors.white.withOpacity(0.8),
                  ),
                  iconSize: 32,
                  onPressed: () {
                    setState(() {
                      _audioVolume = _audioVolume > 0 ? 0 : 0.5;
                      _audioPlayer.setVolume(_audioVolume);
                    });
                  },
                ),
              ],
            ) : SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        buildRatingBadge(currentRating),
        SizedBox(height: 20),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.purpleAccent.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "STATISTICS",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Divider(color: Colors.white24),
                SizedBox(height: 10),
                _buildStatItem("Score", score.toString()),
                _buildStatItem("Combo", combo.toString()),
                _buildStatItem("Max Combo", maxCombo.toString()),
                SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CONTROLS",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        Divider(color: Colors.white24),
                        SizedBox(height: 10),
                        _buildControlButton(Icons.refresh, "Reset Game", () {
                          setState(() {
                            score = 0;
                            combo = 0;
                            maxCombo = 0;
                            arrowSpeedMultiplier = initialSpeedMultiplier;
                            arrows.clear();
                            if (widget.gameMode == GameMode.math) {
                              generateMathEquation();
                            }
                          });
                        }),
                        SizedBox(height: 15),
                        _buildHorizontalSliderControl(
                          Icons.speed,
                          "Arrow Speed",
                          initialSpeedMultiplier,
                          0.5,
                          2.0,
                          15,
                          (value) {
                            setState(() {
                              initialSpeedMultiplier = value;
                              if (score == 0 && combo == 0) {
                                arrowSpeedMultiplier = initialSpeedMultiplier;
                              }
                            });
                          },
                          "${initialSpeedMultiplier.toStringAsFixed(1)}×",
                        ),
                        SizedBox(height: 15),
                        if (_isVideoInitialized)
                          _buildHorizontalSliderControl(
                            _audioVolume == 0
                                ? Icons.volume_off
                                : (_audioVolume < 0.5 ? Icons.volume_down : Icons.volume_up),
                            "Volume",
                            _audioVolume,
                            0.0,
                            1.0,
                            10,
                            (value) {
                              setState(() {
                                _audioVolume = value;
                                _audioPlayer.setVolume(_audioVolume);
                              });
                            },
                            "${(_audioVolume * 100).toInt()}%",
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard, size: 16, color: Colors.white70),
                        SizedBox(width: 8),
                        Text(
                          "WASD to hit arrows",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSliderControl(
    IconData icon,
    String label,
    double value,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged,
    String valueText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.purpleAccent, size: 18),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                valueText,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            thumbColor: Colors.purpleAccent,
            activeTrackColor: Colors.purpleAccent,
            inactiveTrackColor: Colors.purpleAccent.withOpacity(0.3),
            trackHeight: 4,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCompactStat("Score", score.toString(), Colors.amberAccent),
        _buildCompactStat("Combo", combo.toString(), Colors.greenAccent),
        _buildCompactStat("Max Combo", maxCombo.toString(), Colors.cyanAccent),
        buildRatingBadge(currentRating),
      ],
    );
  }

  Widget _buildCompactStat(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.pinkAccent.withOpacity(0.7),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black,
                Colors.deepPurple.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _rotateController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: GameGridPainter(
                          progress: _rotateController.value,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: constraints.maxHeight * 0.15,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.7),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(_glowAnimation.value * 0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Positioned.fill(
                  child: _buildArrowsContainer(constraints),
                ),
                if (showHitFeedback && lastHitRating != null)
                  Positioned(
                    top: constraints.maxHeight * 0.25,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildHitFeedback(),
                    ),
                  ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white24,
                          width: 1,
                        ),
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
          ),
        );
      },
    );
  }

  Widget _buildArrowsContainer(BoxConstraints constraints) {
    final gameHeight = constraints.maxHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final laneWidth = (totalWidth - 40) / 4;

        final lanePositions = [
          20 + laneWidth * 0.5,
          20 + laneWidth * 1.5,
          20 + laneWidth * 2.5,
          20 + laneWidth * 3.5,
        ];

        return Stack(
          children: [
            ...List.generate(3, (index) {
              return Positioned(
                left: 20 + laneWidth * (index + 1),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1,
                  color: Colors.white10,
                ),
              );
            }),
            ...Direction.values.map((direction) {
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
                top: gameHeight * 0.15 - 35,
                left: lanePositions[index] - 35,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(_glowAnimation.value * 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: buildArrowWidget(
                        direction,
                        isTarget: true,
                      ),
                    );
                  },
                ),
              );
            }).toList(),
            ...arrows.map((arrow) {
              double top = gameHeight - (arrow.position * gameHeight * 0.85);

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
                top: top - 32.5,
                left: lanePositions[index] - 32.5,
                child: buildArrowWidget(
                  arrow.direction,
                  isHit: arrow.isHit,
                  hitRating: arrow.hitRating,
                  number: arrow.number,
                  lastAnswerCorrect: lastAnswerCorrect,
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildHitFeedback() {
    Color feedbackColor;
    String feedbackText;

    if (lastAnswerCorrect) {
      feedbackColor = lastHitRating == HitRating.perfect
          ? Colors.greenAccent
          : Colors.yellowAccent;
      feedbackText = lastHitRating == HitRating.perfect ? "PERFECT!" : "GOOD!";
    } else {
      feedbackColor = Colors.redAccent;
      feedbackText = "WRONG ANSWER!";
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.1),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: feedbackColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: feedbackColor.withOpacity(_glowAnimation.value * 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              feedbackText,
              style: TextStyle(
                color: feedbackColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: feedbackColor.withOpacity(0.7),
                    blurRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class NeonGridPainter extends CustomPainter {
  final double progress;

  NeonGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purpleAccent.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final spacing = 40.0;
    final offset = (progress * spacing * 2) % spacing;

    for (double y = offset; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    for (double x = offset; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GameGridPainter extends CustomPainter {
  final double progress;

  GameGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final dashPaint = Paint()
      ..color = Colors.purpleAccent.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final laneWidth = size.width / 4;
    final dashLength = 10.0;
    final dashSpace = 10.0;
    final offset = (progress * 100) % (dashLength + dashSpace);

    for (double y = offset; y < size.height; y += dashLength + dashSpace) {
      for (int i = 0; i < 4; i++) {
        canvas.drawLine(
          Offset(i * laneWidth, y),
          Offset((i + 1) * laneWidth, y),
          dashPaint,
        );
      }
    }

    for (int i = 1; i < 4; i++) {
      final x = i * laneWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SpeedMeterPainter extends CustomPainter {
  final double progress;
  final Color baseColor;

  SpeedMeterPainter({
    required this.progress,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -pi * 0.75,
      pi * 1.5,
      false,
      bgPaint,
    );

    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          baseColor.withOpacity(0.7),
          baseColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -pi * 0.75,
      pi * 1.5 * progress,
      false,
      progressPaint,
    );

    final tickPaint = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i <= 20; i++) {
      final angle = -pi * 0.75 + (pi * 1.5 * i / 20);
      final outerPoint = Offset(
        center.dx + (radius - 2) * cos(angle),
        center.dy + (radius - 2) * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 8) * cos(angle),
        center.dy + (radius - 8) * sin(angle),
      );

      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}