import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/start_screen.dart';

void main() {
  // Add these lines to improve web performance
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set web renderer to HTML for better compatibility
  // The settings below help with web performance
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) print(details.toString());
  };
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math DDR Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        fontFamily: 'RobotoMono',
        // Disable Material 3 for web compatibility
        useMaterial3: false,
      ),
      home: StartScreen(),
    );
  }
}
