import 'package:flutter/material.dart';
import '../models/enums.dart';

class MathEquation extends StatelessWidget {
  final int firstNumber;
  final int secondNumber;
  final MathOperation operation;
  final String? customText;

  const MathEquation({
    Key? key,
    required this.firstNumber,
    required this.secondNumber,
    this.operation = MathOperation.addition,
    this.customText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If customText is provided, use that instead of generating from numbers
    String displayText = customText ?? _getEquationText();
    
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _getEquationText() {
    String operationSymbol;
    
    switch (operation) {
      case MathOperation.addition:
        operationSymbol = "+";
        break;
      case MathOperation.subtraction:
        operationSymbol = "-";
        break;
      case MathOperation.multiplication:
        operationSymbol = "×";
        break;
      case MathOperation.division:
        operationSymbol = "÷";
        break;
    }
    
    return "$firstNumber $operationSymbol $secondNumber = ?";
  }
}
