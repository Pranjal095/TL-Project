import 'package:flutter/material.dart';

Widget buildRatingBadge(String currentRating) {
  Color ratingColor;
  switch (currentRating) {
    case "Math Champion":
      ratingColor = Colors.deepPurple;
      break;
    case "Math Master":
      ratingColor = Colors.redAccent;
      break;
    case "Math Pro":
      ratingColor = Colors.blueAccent;
      break;
    case "Math Amateur":
      ratingColor = Colors.green;
      break;
    default:
      ratingColor = Colors.grey;
  }

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: ratingColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: ratingColor.withOpacity(0.6),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Text(
      currentRating,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  );
}
