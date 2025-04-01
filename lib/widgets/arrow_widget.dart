import 'package:flutter/material.dart';
import '../models/enums.dart';

Widget buildArrowWidget(Direction direction, {
  double? position,
  bool isHit = false,
  bool isTarget = false,
  HitRating? hitRating,
  int? number,
  bool lastAnswerCorrect = true,
}) {
  // Get icon for direction
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

  // Target zones have 3D effect and glow
  if (isTarget) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.cyan.withOpacity(0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(0.1)
          ..rotateY(-0.1),
        alignment: Alignment.center,
        child: Icon(
          icon, 
          color: Colors.cyan.withOpacity(0.8), 
          size: 40,
          shadows: [
            Shadow(
              color: Colors.cyanAccent.withOpacity(0.5),
              blurRadius: 15,
            ),
          ],
        ),
      ),
    );
  }

  // Get color based on hit rating
  Color arrowColor;
  if (isHit) {
    switch (hitRating) {
      case HitRating.perfect:
        arrowColor = lastAnswerCorrect ? Colors.greenAccent : Colors.redAccent;
        break;
      case HitRating.good:
        arrowColor = lastAnswerCorrect ? Colors.yellowAccent : Colors.redAccent;
        break;
      case HitRating.bad:
        arrowColor = Colors.redAccent;
        break;
      default:
        arrowColor = Colors.green;
    }
  } else {
    // Classic mode uses blue color, Math mode uses pink
    arrowColor = (number == null || number <= 0) ? 
                 Colors.blueAccent : Colors.pinkAccent;
  }

  // Active arrows with 3D effect and neon glow
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
            color: arrowColor.withOpacity(isHit ? 0.3 : 0.7),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Only show number if it's greater than 0 (for math mode)
          if (number != null && number > 0)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: arrowColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  shadows: [
                    Shadow(
                      color: arrowColor.withOpacity(0.8),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
          
          // Arrow icon - make larger for classic mode when no number is shown
          Icon(
            icon, 
            color: arrowColor.withOpacity(0.9),
            size: (number == null || number <= 0) ? 40 : 14,
            shadows: [
              Shadow(
                color: arrowColor.withOpacity(0.8),
                blurRadius: 5,
              ),
            ],
          ),
          
          // Only show small indicator if we're showing a number
          if (number != null && number > 0)
            Positioned(
              bottom: 5,
              right: 5,
              child: Icon(
                icon,
                color: arrowColor.withOpacity(0.7),
                size: 14,
              ),
            ),
        ],
      ),
    ),
  );
}
