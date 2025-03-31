import 'package:flutter/material.dart';
import '../models/enums.dart';

class ArrowWidget extends StatelessWidget {
  final Direction direction;
  final double? position;
  final bool isHit;
  final bool isTarget;
  final HitRating? hitRating;
  final int? number;
  final bool lastAnswerCorrect;
  final double size;

  const ArrowWidget({
    Key? key,
    required this.direction,
    this.position,
    this.isHit = false,
    this.isTarget = false,
    this.hitRating,
    this.number,
    this.lastAnswerCorrect = true,
    this.size = 70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(size * 0.15),
          border: Border.all(color: Colors.cyan.withOpacity(0.8), width: 3),
        ),
        child: Icon(icon, color: Colors.cyan.withOpacity(0.8), size: size * 0.6),
      );
    }

    // Get color based on hit rating
    Color arrowColor;
    String hitText = "";
    if (isHit) {
      switch (hitRating) {
        case HitRating.perfect:
          arrowColor = lastAnswerCorrect ? Colors.greenAccent : Colors.redAccent;
          hitText = lastAnswerCorrect ? "PERFECT" : "WRONG ANSWER";
          break;
        case HitRating.good:
          arrowColor = lastAnswerCorrect ? Colors.yellowAccent : Colors.redAccent;
          hitText = lastAnswerCorrect ? "GOOD" : "WRONG ANSWER";
          break;
        case HitRating.bad:
          arrowColor = Colors.orangeAccent;
          hitText = lastAnswerCorrect ? "WRONG TIMING" : "WRONG ANSWER";
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(size * 0.15),
              border: Border.all(
                color: arrowColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: arrowColor.withOpacity(0.7),
                  blurRadius: size * 0.2,
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
                        fontSize: size * 0.45, // Larger numbers
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Show hit text for hit arrows
          if (isHit && hitText.isNotEmpty)
            Positioned(
              top: -20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: arrowColor, width: 1),
                ),
                child: Text(
                  hitText,
                  style: TextStyle(
                    color: arrowColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
