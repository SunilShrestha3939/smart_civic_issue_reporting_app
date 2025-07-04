import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:smart_civic_app/screens/splash_screen.dart';
import 'package:smart_civic_app/providers/app_provider.dart'; 

import 'package:smart_civic_app/screens/login_screen.dart'; 
import 'package:smart_civic_app/screens/home_screen.dart'; 

//entry point of the app
void main() {
  runApp(
    // ChangeNotifierProvider(create: (context) => AppProvider(), child: const MyApp()): This widget makes an instance of AppProvider available to all widgets below it in the widget tree. create is a function that returns the provider instance.
    ChangeNotifierProvider( // Wrap the entire app
      create: (context) => AppProvider(), // Create an instance of our provider
      child: const MyApp(),
    ),
  );
}

//describers the overall structure and theme of our application.
class MyApp extends StatelessWidget { // stateless because it contains (title, theme, and initial route) that do not change during apps lifecycle.
  const MyApp({super.key});

  // This method is responsible for returning the widget tree that this widget describes. The BuildContext object holds the location of a widget in the widget tree.
  @override
  Widget build(BuildContext context) {
    //Consumer<AppProvider>(...): This widget is a way to "listen" to changes in AppProvider. Whenever notifyListeners() is called in AppProvider, the builder function of Consumer will be re-executed, rebuilding only the parts of the UI that depend on the provider's state.
    return Consumer<AppProvider>( // Listen to AppProvider for theme changes
      builder: (context, appProvider, child) {
        return MaterialApp( // it sets up the navigarion stack, theme, and other app-wide 
          title: 'Smart Civic App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light, // Default light theme
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark, // Dark theme
            scaffoldBackgroundColor: Colors.grey[900],
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[850],
            ),
            cardColor: Colors.grey[800],
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              titleLarge: TextStyle(color: Colors.white),
              titleMedium: TextStyle(color: Colors.white),
              displayLarge: TextStyle(color: Colors.white), // Added for larger texts
              displayMedium: TextStyle(color: Colors.white),
              displaySmall: TextStyle(color: Colors.white),
              headlineMedium: TextStyle(color: Colors.white),
              headlineSmall: TextStyle(color: Colors.white),
              titleSmall: TextStyle(color: Colors.white70),
              labelLarge: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white), // Ensure icons are visible
          ),
          themeMode: appProvider.themeMode, // control the themeMode of MaterialApp directly from our AppProvider.
          // Use FutureBuilder to show splash screen while token is loading ie checking if user is logged in based on the stored token.
          // then redirect based on login status
          
          // home: FutureBuilder(
          //   future: appProvider.isLoggedIn ? Future.value(true) : Future.value(false), // This is not ideal, should load token first.
          //   // Let's modify the root to make sure token loading happens correctly.
          //   // A better way is to use a separate widget that handles initial auth check.
          //   builder: (context, snapshot) {
          //     // AppProvider's constructor already loads the token.
          //     // So, we just need to check appProvider.isLoggedIn.
          //     // The splash screen already handles the delay.
          //     // We'll let the splash screen determine the first route based on AppProvider's state.
          //     return const SplashScreen();
          //   },
          // ),

          home: const SplashScreen(), // Show splash screen first
          // Define named routes
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}