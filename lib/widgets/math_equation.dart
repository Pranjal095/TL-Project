import 'package:flutter/material.dart';
import '../models/enums.dart';

class MathEquation extends StatelessWidget {
  final int firstNumber;
  final int secondNumber;
  final MathOperation operation;

  const MathEquation({
    Key? key,
    required this.firstNumber,
    required this.secondNumber,
    this.operation = MathOperation.addition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get operation symbol
    String operationSymbol = operation == MathOperation.addition ? "+" : "×";
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.purpleAccent,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "SOLVE",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$firstNumber $operationSymbol $secondNumber = ?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 60, // Larger equation text
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
