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
        arrowColor = lastAnswerCorrect ? Colors.greenAccent : Colors.redAccent;
        break;
      case HitRating.good:
        arrowColor = lastAnswerCorrect ? Colors.yellowAccent : Colors.redAccent;
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
