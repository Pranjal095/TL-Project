import 'package:flutter/material.dart';
import 'math_equation.dart';
import '../models/enums.dart';

Widget buildMathEquation(int firstNumber, int secondNumber, [MathOperation operation = MathOperation.addition]) {
  return MathEquation(
    firstNumber: firstNumber,
    secondNumber: secondNumber,
    operation: operation,
  );
}

Widget buildCustomMathEquation(String equationText) {
  return MathEquation(
    firstNumber: 0, // These values won't be used
    secondNumber: 0,
    customText: equationText,
  );
}
