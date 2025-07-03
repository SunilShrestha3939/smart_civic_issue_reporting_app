import 'package:flutter/material.dart';
import 'package:smart_civic_app/screens/splash_screen.dart';

//entry point of the app
void main() {
  runApp(const MyApp());  //MyApp is the root widget of our application
}

//describers the overall structure and theme of our application.
class MyApp extends StatelessWidget { // stateless because it contains (title, theme, and initial route) that do not change during apps lifecycle.
  const MyApp({super.key});

  // This method is responsible for returning the widget tree that this widget describes. The BuildContext object holds the location of a widget in the widget tree.
  @override
  Widget build(BuildContext context) {  
    return MaterialApp( // it sets up the navigarion stack, theme, and other app-wide settings.
      title: 'Smart Civic App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(), // Our initial screen
    );
  }
}