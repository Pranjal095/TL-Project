import 'package:flutter/material.dart';
import 'screens/start_screen.dart';
import 'models/enums.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math DDR Simulator',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        fontFamily: 'RobotoMono',
      ),
      home: StartScreen(),
    );
  }
}