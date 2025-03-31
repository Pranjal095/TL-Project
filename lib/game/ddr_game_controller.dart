import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/arrow.dart';
import '../models/enums.dart';

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
  
  // Hit feedback data
  final ValueNotifier<HitRating?> lastHitRating = ValueNotifier<HitRating?>(null);
  final ValueNotifier<int> lastHitTime = ValueNotifier<int>(0);
  
  // Direction feedback
  final ValueNotifier<Direction?> lastInput = ValueNotifier<Direction?>(null);
  final ValueNotifier<int> lastInputTime = ValueNotifier<int>(0);

  // Target zone ranges (percentage of lane height)
  final double perfectZone = 0.20; // ±20% of center for perfect hits
  final double goodZone = 0.30; // ±30% of center for good hits
  final int maxArrowsWithoutCorrect = 5; // Force correct answer after this many arrows
  final double badZone = 0.2; // ±20% of center for bad hits

  Timer? gameTimer;
  Timer? arrowGenerationTimer;

  // Map of lane positions - we'll use this for hit detection with dynamic layout
  final Map<Direction, int> laneIndices = {
    Direction.left: 0,
    Direction.down: 1,
    Direction.up: 2,
    Direction.right: 3,
  };

  void startGame() {
    // Initialize the game
    generateMathEquation();
    
    // Start the game update timer
    gameTimer = Timer.periodic(Duration(milliseconds: 33), (timer) {
      updateGame();
    });
    
    // Start arrow generation timer
    arrowGenerationTimer = Timer.periodic(Duration(milliseconds: 1500), (timer) {
      generateArrow();
    });
  }

  void stopGame() {
    gameTimer?.cancel();
    arrowGenerationTimer?.cancel();
  }

  void generateMathEquation() {
    // Switch between addition and multiplication (equal chance)
    if (random.nextBool()) {
      operationType.value = MathOperation.addition;
      // For addition: use numbers 1-9
      final newFirstNumber = random.nextInt(9) + 1;
      final newSecondNumber = random.nextInt(9) + 1;
      
      firstNumber.value = newFirstNumber;
      secondNumber.value = newSecondNumber;
      correctAnswer.value = newFirstNumber + newSecondNumber;
    } else {
      operationType.value = MathOperation.multiplication;
      // For multiplication: use smaller numbers to keep answers manageable
      final newFirstNumber = random.nextInt(5) + 1; // 1-5
      final newSecondNumber = random.nextInt(5) + 1; // 1-5
      
      firstNumber.value = newFirstNumber;
      secondNumber.value = newSecondNumber;
      correctAnswer.value = newFirstNumber * newSecondNumber;
    }
  }

  void generateArrow() {
    // Random direction
    Direction dir = Direction.values[random.nextInt(Direction.values.length)];

    // Generate a number for the arrow
    int number;

    // Force correct answer if we haven't had one in the last maxArrowsWithoutCorrect arrows
    if (arrowsSinceLastCorrect >= maxArrowsWithoutCorrect - 1) {
      number = correctAnswer.value;
      arrowsSinceLastCorrect = 0; // Reset counter
    } else {
      // Otherwise use probability-based approach
      if (random.nextDouble() < 0.3) {
        // 30% chance of correct answer
        number = correctAnswer.value;
        arrowsSinceLastCorrect = 0; // Reset counter
      } else {
        // Generate a random number that is not the correct answer
        int maxValue = 25; // Increase max value for multiplication
        
        do {
          number = random.nextInt(maxValue) + 1; // Random number from 1-25
        } while (number == correctAnswer.value);

        // Increment counter since we generated an incorrect answer
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
    // Find the nearest arrow in the target zone with matching direction
    Arrow? hitArrow;
    double closestDistance = double.infinity;

    for (var arrow in arrows.value) {
      if (arrow.direction == input && !arrow.isHit) {
        // Calculate distance from target (1.0 is perfect)
        // This is an important fix: we need to invert position to display position for proper distance calculation
        // Arrow position of 1.0 means it's at the hit line
        double distance = (arrow.position - 1.0).abs();
        
        // Debug the position
        print('Arrow position: ${arrow.position}, distance: $distance');

        // Only consider arrows within the hit window
        if (distance < 0.30 && distance < closestDistance) {
          closestDistance = distance;
          hitArrow = arrow;
        }
      }
    }

    if (hitArrow != null) {
      // Create a copy of the arrows list to modify
      final List<Arrow> updatedArrows = List.from(arrows.value);
      int arrowIndex = updatedArrows.indexOf(hitArrow);
      
      // Update the hit arrow
      hitArrow.isHit = true;

      // Check if the number on the arrow is the correct answer
      bool isCorrectAnswer = hitArrow.number == correctAnswer.value;
      lastAnswerCorrect.value = isCorrectAnswer;
      
      // Debug logs to verify behavior
      print('Hit distance: $closestDistance, perfectZone: $perfectZone, goodZone: $goodZone');
      print('Arrow number: ${hitArrow.number}, correctAnswer: ${correctAnswer.value}');
      print('isCorrectAnswer: $isCorrectAnswer');

      // Calculate rating based on timing accuracy - with even more forgiving perfect zone
      HitRating rating;
      if (closestDistance < perfectZone) {
        rating = HitRating.perfect;
        print('PERFECT HIT!');
        // Award or penalize based on correctness
        if (isCorrectAnswer) {
          score.value += 100 * (combo.value + 1);
          combo.value++;
          arrowSpeedMultiplier.value *= 1.10; // Increased to 10% speed increase for perfect hits
          // Generate a new equation immediately after correct answer
          generateMathEquation();
        } else {
          score.value -= 20;
          combo.value = 0;
        }
      } else if (closestDistance < goodZone) {
        rating = HitRating.good;
        print('GOOD HIT!');
        if (isCorrectAnswer) {
          score.value += 50 * (combo.value + 1);
          combo.value++;
          arrowSpeedMultiplier.value *= 1.02; // 2% increase for good hits
          // Generate a new equation immediately after correct answer
          generateMathEquation();
        } else {
          score.value -= 10;
          combo.value = 0;
        }
      } else {
        // Bad hit - will show as "WRONG TIMING" even if answer is correct
        rating = HitRating.bad;
        print('BAD HIT!');
        // Even with correct answer, don't reward bad timing much
        if (isCorrectAnswer) {
          score.value += 10;  // Small score increase
          // Don't increase combo for bad timing
          generateMathEquation();
        } else {
          score.value -= 5;
          combo.value = 0;
        }
      }

      // Prevent negative score
      if (score.value < 0) score.value = 0;

      // Update max combo
      if (combo.value > maxCombo.value) {
        maxCombo.value = combo.value;
      }

      // Update player rating
      currentRating.value = calculateRating();

      // Store the hit rating with the arrow
      hitArrow.hitRating = rating;
      updatedArrows[arrowIndex] = hitArrow;

      // Store the hit rating to display feedback
      lastHitRating.value = rating;
      lastHitTime.value = DateTime.now().millisecondsSinceEpoch;

      // Store last input for visual feedback
      lastInput.value = input;
      lastInputTime.value = DateTime.now().millisecondsSinceEpoch;
      
      // Update arrows list
      arrows.value = updatedArrows;
    }
  }

  void updateGame() {
    final currentSpeed = arrowBaseSpeed.value * arrowSpeedMultiplier.value;
    final List<Arrow> currentArrows = List.from(arrows.value);
    bool arrowsChanged = false;

    // Move all arrows upward
    for (int i = 0; i < currentArrows.length; i++) {
      Arrow arrow = currentArrows[i];
      // Non-hit arrows move at normal speed
      if (!arrow.isHit) {
        arrow.position += currentSpeed;
      } else {
        // Hit arrows move faster to clear screen
        arrow.position += currentSpeed * 3;
      }
      
      // Mark arrows that passed the hit line without being hit
      if (arrow.position > 1.05 && !arrow.isHit) {
        // If this was the correct answer, penalize the player
        if (arrow.number == correctAnswer.value) {
          combo.value = 0; // Break combo when missing correct answers
        }
      }
      
      currentArrows[i] = arrow;
      arrowsChanged = true;
    }

    // Remove arrows that went off-screen
    List<Arrow> remainingArrows = currentArrows.where((arrow) {
      // Remove arrows that passed without being hit
      if (arrow.position > 1.2 && !arrow.isHit) {
        return false;
      }
      // Remove hit arrows that leave the screen
      if (arrow.position > 1.2) {
        return false;
      }
      return true;
    }).toList();

    if (currentArrows.length != remainingArrows.length) {
      arrowsChanged = true;
    }

    // Only update the value if changes were made
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
