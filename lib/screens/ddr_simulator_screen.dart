import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/arrow.dart';
import '../models/enums.dart';
import '../widgets/arrow_widget.dart';
import '../widgets/math_equation.dart';
import '../widgets/rating_badge.dart';
import '../widgets/disco_background.dart';

// Define the DDRGameController class inline to avoid import issues
class DDRGameController {
  final Random random = Random();
  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> combo = ValueNotifier<int>(0);
  final ValueNotifier<int> maxCombo = ValueNotifier<int>(0);
  final ValueNotifier<String> currentRating = ValueNotifier<String>("Beginner");
  final ValueNotifier<List<Arrow>> arrows = ValueNotifier<List<Arrow>>([]);
  final ValueNotifier<bool> lastAnswerCorrect = ValueNotifier<bool>(true);

  // Math equation variables
  final ValueNotifier<int> firstNumber = ValueNotifier<int>(0);
  final ValueNotifier<int> secondNumber = ValueNotifier<int>(0);
  final ValueNotifier<int> correctAnswer = ValueNotifier<int>(0);
  final ValueNotifier<MathOperation> operationType = ValueNotifier<MathOperation>(MathOperation.addition);
  int arrowsSinceLastCorrect = 0;

  // Arrow speed control variables
  final ValueNotifier<double> arrowBaseSpeed = ValueNotifier<double>(0.01);
  final ValueNotifier<double> arrowSpeedMultiplier = ValueNotifier<double>(1.0);
  
  // Speed control constants
  final double maxSpeedMultiplier = 2.0;
  final double perfectSpeedIncrease = 1.05;
  final double goodSpeedIncrease = 1.01;
  
  // Hit feedback data
  final ValueNotifier<HitRating?> lastHitRating = ValueNotifier<HitRating?>(null);
  final ValueNotifier<int> lastHitTime = ValueNotifier<int>(0);
  
  // Direction feedback
  final ValueNotifier<Direction?> lastInput = ValueNotifier<Direction?>(null);
  final ValueNotifier<int> lastInputTime = ValueNotifier<int>(0);

  // Target zone ranges (percentage of lane height) - reduced sizes
  final double perfectZone = 0.15; // Decreased from 0.20 for more precision
  final double goodZone = 0.25; // Decreased from 0.30 for more precision
  final int maxArrowsWithoutCorrect = 5;

  Timer? gameTimer;
  Timer? arrowGenerationTimer;

  void startGame() {
    generateMathEquation();
    gameTimer = Timer.periodic(Duration(milliseconds: 33), (timer) {
      updateGame();
    });
    arrowGenerationTimer = Timer.periodic(Duration(milliseconds: 1500), (timer) {
      generateArrow();
    });
  }

  void stopGame() {
    gameTimer?.cancel();
    arrowGenerationTimer?.cancel();
  }

  void generateMathEquation() {
    if (random.nextBool()) {
      operationType.value = MathOperation.addition;
      final newFirstNumber = random.nextInt(9) + 1;
      final newSecondNumber = random.nextInt(9) + 1;
      firstNumber.value = newFirstNumber;
      secondNumber.value = newSecondNumber;
      correctAnswer.value = newFirstNumber + newSecondNumber;
    } else {
      operationType.value = MathOperation.multiplication;
      final newFirstNumber = random.nextInt(5) + 1;
      final newSecondNumber = random.nextInt(5) + 1;
      firstNumber.value = newFirstNumber;
      secondNumber.value = newSecondNumber;
      correctAnswer.value = newFirstNumber * newSecondNumber;
    }
  }

  void generateArrow() {
    Direction dir = Direction.values[random.nextInt(Direction.values.length)];
    int number;
    if (arrowsSinceLastCorrect >= maxArrowsWithoutCorrect - 1) {
      number = correctAnswer.value;
      arrowsSinceLastCorrect = 0;
    } else {
      if (random.nextDouble() < 0.3) {
        number = correctAnswer.value;
        arrowsSinceLastCorrect = 0;
      } else {
        int maxValue = 25;
        do {
          number = random.nextInt(maxValue) + 1;
        } while (number == correctAnswer.value);
        arrowsSinceLastCorrect++;
      }
    }
    final List<Arrow> currentArrows = List.from(arrows.value);
    currentArrows.add(Arrow(dir, number));
    arrows.value = currentArrows;
  }

  String calculateRating() {
    if (score.value >= 10000 && maxCombo.value >= 50) {
      return "Math Champion";
    } else if (score.value >= 5000 && maxCombo.value >= 30) {
      return "Math Master";
    } else if (score.value >= 2500 && maxCombo.value >= 20) {
      return "Math Pro";
    } else if (score.value >= 1000 && maxCombo.value >= 10) {
      return "Math Amateur";
    } else {
      return "Math Beginner";
    }
  }

  void checkHit(Direction input) {
    Arrow? hitArrow;
    double closestDistance = double.infinity;

    for (var arrow in arrows.value) {
      if (arrow.direction == input && !arrow.isHit) {
        double distance = (arrow.position - 0.4).abs();
        if (distance < 0.30 && distance < closestDistance) {
          closestDistance = distance;
          hitArrow = arrow;
        }
      }
    }

    if (hitArrow != null) {
      final List<Arrow> updatedArrows = List.from(arrows.value);
      int arrowIndex = updatedArrows.indexOf(hitArrow);
      hitArrow.isHit = true;
      bool isCorrectAnswer = hitArrow.number == correctAnswer.value;
      lastAnswerCorrect.value = isCorrectAnswer;
      HitRating rating;
      if (closestDistance < perfectZone) {
        rating = HitRating.perfect;
        if (isCorrectAnswer) {
          score.value += 100 * (combo.value + 1);
          combo.value++;
          arrowSpeedMultiplier.value *= perfectSpeedIncrease;
          if (arrowSpeedMultiplier.value > maxSpeedMultiplier) {
            arrowSpeedMultiplier.value = maxSpeedMultiplier;
          }
          generateMathEquation();
        } else {
          score.value -= 20;
          combo.value = 0;
        }
      } else if (closestDistance < goodZone) {
        rating = HitRating.good;
        if (isCorrectAnswer) {
          score.value += 50 * (combo.value + 1);
          combo.value++;
          arrowSpeedMultiplier.value *= goodSpeedIncrease;
          if (arrowSpeedMultiplier.value > maxSpeedMultiplier) {
            arrowSpeedMultiplier.value = maxSpeedMultiplier;
          }
          generateMathEquation();
        } else {
          score.value -= 10;
          combo.value = 0;
        }
      } else {
        rating = HitRating.bad;
        if (isCorrectAnswer) {
          score.value += 10;
          generateMathEquation();
        } else {
          score.value -= 5;
          combo.value = 0;
        }
      }

      if (score.value < 0) score.value = 0;
      if (combo.value > maxCombo.value) {
        maxCombo.value = combo.value;
      }
      currentRating.value = calculateRating();

      hitArrow.hitRating = rating;
      updatedArrows[arrowIndex] = hitArrow;

      lastHitRating.value = rating;
      lastHitTime.value = DateTime.now().millisecondsSinceEpoch;

      lastInput.value = input;
      lastInputTime.value = DateTime.now().millisecondsSinceEpoch;

      arrows.value = updatedArrows;
    }
  }

  void updateGame() {
    final currentSpeed = arrowBaseSpeed.value * arrowSpeedMultiplier.value;
    final List<Arrow> currentArrows = List.from(arrows.value);
    bool arrowsChanged = false;

    for (int i = 0; i < currentArrows.length; i++) {
      Arrow arrow = currentArrows[i];
      if (!arrow.isHit) {
        arrow.position += currentSpeed;
      } else {
        arrow.position += currentSpeed * 3;
      }
      if (arrow.position > 1.05 && !arrow.isHit) {
        if (arrow.number == correctAnswer.value) {
          combo.value = 0;
        }
        arrowsChanged = true;
      }
      currentArrows[i] = arrow;
    }

    List<Arrow> remainingArrows = currentArrows.where((arrow) {
      if (arrow.position > 1.2) return false;
      return true;
    }).toList();

    if (currentArrows.length != remainingArrows.length) {
      arrowsChanged = true;
    }

    if (arrowsChanged) {
      arrows.value = remainingArrows;
    }
  }

  void updateArrowSpeed(double newSpeed) {
    arrowBaseSpeed.value = newSpeed;
  }

  void dispose() {
    stopGame();
  }
}

// Create a simple loading screen widget
class LoadingScreen extends StatelessWidget {
  final String message;
  
  const LoadingScreen({Key? key, this.message = "Loading..."}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
            ),
            SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DDRSimulator extends StatefulWidget {
  @override
  _DDRSimulatorState createState() => _DDRSimulatorState();
}

class _DDRSimulatorState extends State<DDRSimulator> with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;
  bool _isLoading = true;
  double videoVolume = 0.5;
  late DDRGameController gameController;

  @override
  void initState() {
    super.initState();
    gameController = DDRGameController();
    _initializeVideo();
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        gameController.startGame();
      }
    });
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/dance.mp4');
      _videoController.setVolume(videoVolume);
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

  void _updateVolume(double value) {
    setState(() {
      videoVolume = value;
      _videoController.setVolume(value);
    });
  }

  @override
  void dispose() {
    gameController.dispose();
    _videoController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyW) {
        gameController.checkHit(Direction.up);
      } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
        gameController.checkHit(Direction.down);
      } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
        gameController.checkHit(Direction.left);
      } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
        gameController.checkHit(Direction.right);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingScreen();
    }

    bool showHitFeedback = DateTime.now().millisecondsSinceEpoch - gameController.lastHitTime.value < 800;
    final screenSize = MediaQuery.of(context).size;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Math DDR Simulator'),
          backgroundColor: Colors.black87,
          elevation: 10,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Stack(
          children: [
            DiscoBackground(
              videoController: _videoController,
              isVideoInitialized: _isVideoInitialized,
            ),
            Positioned.fill(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildArrowSpeedControl(),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildScoreDisplay(),
                        ),
                        Expanded(
                          flex: 1,
                          child: _buildVolumeControl(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          right: screenSize.width * 0.3,
                          top: 0,
                          bottom: 0,
                          child: _buildGameScreen(showHitFeedback),
                        ),
                        Positioned(
                          right: 0,
                          width: screenSize.width * 0.3,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              border: const Border(
                                left: BorderSide(
                                  width: 2,
                                  color: Color(0x80800080),
                                ),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ValueListenableBuilder<int>(
                                  valueListenable: gameController.firstNumber,
                                  builder: (context, firstNumber, child) {
                                    return ValueListenableBuilder<int>(
                                      valueListenable: gameController.secondNumber,
                                      builder: (context, secondNumber, child) {
                                        return ValueListenableBuilder<MathOperation>(
                                          valueListenable: gameController.operationType,
                                          builder: (context, operation, child) {
                                            return MathEquation(
                                              firstNumber: firstNumber,
                                              secondNumber: secondNumber,
                                              operation: operation,
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isVideoPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
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
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _videoController.seekTo(Duration.zero);
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildArrowSpeedControl() {
    return ValueListenableBuilder<double>(
      valueListenable: gameController.arrowBaseSpeed,
      builder: (context, arrowBaseSpeed, child) {
        return ValueListenableBuilder<double>(
          valueListenable: gameController.arrowSpeedMultiplier,
          builder: (context, arrowSpeedMultiplier, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.purpleAccent.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Arrow Speed", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: arrowBaseSpeed,
                          min: 0.005,
                          max: 0.02,
                          divisions: 15,
                          activeColor: Colors.purpleAccent,
                          inactiveColor: Colors.purpleAccent.withOpacity(0.3),
                          onChanged: (value) {
                            gameController.updateArrowSpeed(value);
                          },
                        ),
                      ),
                      Text(
                        "${arrowSpeedMultiplier.toStringAsFixed(2)}x",
                        style: const TextStyle(color: Colors.amberAccent),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildGameScreen(bool showHitFeedback) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.pinkAccent, width: 4),
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.12),
            Colors.deepPurple.withOpacity(0.08),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gameHeight = constraints.maxHeight;
          final gameWidth = constraints.maxWidth;
          
          final hitLineY = gameHeight * 0.2;
          final perfectZoneStart = hitLineY - (gameHeight * gameController.perfectZone * 0.5);
          final perfectZoneEnd = hitLineY + (gameHeight * gameController.perfectZone * 0.5);
          final goodZoneStart = hitLineY - (gameHeight * gameController.goodZone * 0.5);
          final goodZoneEnd = hitLineY + (gameHeight * gameController.goodZone * 0.5);
          
          return Stack(
            children: [
              Positioned(
                top: goodZoneStart,
                left: 0,
                right: 0,
                height: goodZoneEnd - goodZoneStart,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.yellow.withOpacity(0.3),
                        Colors.yellow.withOpacity(0.2),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: perfectZoneStart,
                left: 0,
                right: 0,
                height: perfectZoneEnd - perfectZoneStart,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.6),
                        Colors.green.withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.green.withOpacity(0.7), width: 2),
                      bottom: BorderSide(color: Colors.green.withOpacity(0.7), width: 2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 3,
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                top: hitLineY,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent,
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                ),
              ),
              ValueListenableBuilder<List<Arrow>>(
                valueListenable: gameController.arrows,
                builder: (context, arrows, child) {
                  return Stack(
                    children: arrows.map((arrow) {
                      double top = gameHeight - (arrow.position * gameHeight);
                      double laneWidth = gameWidth / 4;

                      double left;
                      Direction arrowDirection = arrow.direction;
                      
                      switch(arrowDirection) {
                        case Direction.left:
                          left = laneWidth * 0 + (laneWidth - 80) / 2;
                          break;
                        case Direction.down:
                          left = laneWidth * 1 + (laneWidth - 80) / 2;
                          break;
                        case Direction.up:
                          left = laneWidth * 2 + (laneWidth - 80) / 2;
                          break;
                        case Direction.right:
                          left = laneWidth * 3 + (laneWidth - 80) / 2;
                          break;
                      }

                      return Positioned(
                        top: top - 40,
                        left: left,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: gameController.lastAnswerCorrect,
                          builder: (context, lastAnswerCorrect, child) {
                            return ArrowWidget(
                              direction: arrow.direction,
                              isHit: arrow.isHit,
                              hitRating: arrow.hitRating,
                              number: arrow.number,
                              lastAnswerCorrect: lastAnswerCorrect,
                              size: 80,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              Positioned(
                top: hitLineY - 40,
                left: gameWidth * 0.0 + (gameWidth / 4 - 80) / 2,
                child: ArrowWidget(
                  direction: Direction.left,
                  isTarget: true,
                  size: 80,
                ),
              ),
              Positioned(
                top: hitLineY - 40,
                left: gameWidth * 0.25 + (gameWidth / 4 - 80) / 2,
                child: ArrowWidget(
                  direction: Direction.down,
                  isTarget: true,
                  size: 80,
                ),
              ),
              Positioned(
                top: hitLineY - 40,
                left: gameWidth * 0.5 + (gameWidth / 4 - 80) / 2,
                child: ArrowWidget(
                  direction: Direction.up,
                  isTarget: true,
                  size: 80,
                ),
              ),
              Positioned(
                top: hitLineY - 40,
                left: gameWidth * 0.75 + (gameWidth / 4 - 80) / 2,
                child: ArrowWidget(
                  direction: Direction.right,
                  isTarget: true,
                  size: 80,
                ),
              ),
              if (showHitFeedback)
                ValueListenableBuilder<HitRating?>(
                  valueListenable: gameController.lastHitRating,
                  builder: (context, lastHitRating, child) {
                    if (lastHitRating == null) return const SizedBox.shrink();
                    return ValueListenableBuilder<bool>(
                      valueListenable: gameController.lastAnswerCorrect,
                      builder: (context, lastAnswerCorrect, child) {
                        String feedbackText;
                        Color feedbackColor;
                        if (lastAnswerCorrect) {
                          if (lastHitRating == HitRating.perfect) {
                            feedbackText = "PERFECT!";
                            feedbackColor = Colors.greenAccent;
                          } else if (lastHitRating == HitRating.good) {
                            feedbackText = "GOOD!";
                            feedbackColor = Colors.yellowAccent;
                          } else {
                            feedbackText = "WRONG TIMING!";
                            feedbackColor = Colors.orangeAccent;
                          }
                        } else {
                          feedbackText = "WRONG ANSWER!";
                          feedbackColor = Colors.redAccent;
                        }
                        
                        return Positioned(
                          top: hitLineY + 60,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: feedbackColor,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                feedbackText,
                                style: TextStyle(
                                  color: feedbackColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Use WASD to hit targets",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: gameController.score,
            builder: (context, score, child) {
              return ValueListenableBuilder<int>(
                valueListenable: gameController.maxCombo,
                builder: (context, maxCombo, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score: $score',
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Max Combo: $maxCombo',
                        style: const TextStyle(fontSize: 14, color: Colors.amber),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: gameController.combo,
            builder: (context, combo, child) {
              return ValueListenableBuilder<String>(
                valueListenable: gameController.currentRating,
                builder: (context, currentRating, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Combo: $combo',
                        style: TextStyle(
                          fontSize: 18,
                          color: combo > 0 ? Colors.greenAccent : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RatingBadge(rating: currentRating),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildVolumeControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            children: [
              Icon(
                videoVolume == 0 
                  ? Icons.volume_off 
                  : (videoVolume < 0.5 ? Icons.volume_down : Icons.volume_up),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 5),
              const Text(
                "Volume", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          Slider(
            value: videoVolume,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            activeColor: Colors.purpleAccent,
            inactiveColor: Colors.purpleAccent.withOpacity(0.3),
            onChanged: _updateVolume,
          ),
        ],
      ),
    );
  }
}
