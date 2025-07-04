import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:smart_civic_app/providers/app_provider.dart';
import 'package:smart_civic_app/screens/home_screen.dart';
import 'package:smart_civic_app/screens/login_screen.dart'; 

class SplashScreen extends StatefulWidget { //stateful because it has a state that can change over time, such as showing a loading indicator or navigating to another screen after a delay.
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// state class for the SplashScreen
class _SplashScreenState extends State<SplashScreen> {
  @override
  //called exactly once when the StatefulWidget is inserted into the widget tree. It's the perfect place to perform one-time setup
  void initState() {
    super.initState();
    _checkAuthStatusAndNavigate();
  }

  void _checkAuthStatusAndNavigate() async {
    // delay to display splash screen
    // Future.delayed: This function allows us to execute a piece of code after a specified duration. It's commonly used for splash screens, simulating network calls, or other time-sensitive operations.
    await Future.delayed(const Duration(seconds: 2)); 

    // Access AppProvider to check login status
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Ensure the token has been loaded (AppProvider's constructor does this)
    // We wait for the initial load process to complete.
    // In AppProvider, _loadAuthToken is async, so we assume it completed.
    // If not, you might need a Future in AppProvider or a loading state for the token.
    // For simplicity, we assume _loadAuthToken completes quickly or before UI is ready.

    // _loadAuthToken assigns true or false to _isLoggedIn based on whether a token exists.
    if (appProvider.isLoggedIn) {
      // Navigator manages a stack of routes (screens).
      // [Navigator.of(context)]: Gets the nearest Navigator in the widget tree. 
      // [pushReplacement()]: Instead of just pushing a new screen on top, pushReplacement replaces the current screen (the splash screen) with the new one (LoginScreen). This prevents the user from going back to the splash screen using the back button.
      // [MaterialPageRoute(builder: (context) => const LoginScreen())]: Defines the route to the LoginScreen. [builder] is a function that returns the widget for the new route.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // You can add your app logo here
            Icon(
              Icons.location_city,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'Smart Civic App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}


