import 'dart:convert'; // For JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:http/http.dart' as http; // Import http package
import 'package:smart_civic_app/screens/home_screen.dart';
import 'package:smart_civic_app/screens/registration_screen.dart';
import 'package:smart_civic_app/providers/app_provider.dart'; // Import AppProvider
import 'package:smart_civic_app/utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Key to identify the form and validate it. It's essential for validating all [TextFormField] widgets within the form at once.

  //use [TextEditingController] to get the text entered by the user in [TextFormField]. Each [TextFormField] has its own controller.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false; // To manage loading state

  @override
  //to prevent memory leaks, dispose() of [TextEditingControllers] when the [StatefulWidget] is removed from the widget tree 
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async { // Make the function async because of Http requests
    // [_formKey.currentState!.validate()]: This is the magic line that triggers the validator function for every [TextFormField] inside this Form. If all validators return [null], the form is valid, and this method returns [true]. Otherwise, it returns false, and the error messages are displayed.
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading
      });

      // listen: false is used here because _login itself doesn't need to rebuild when AppProvider's state changes; it just needs to call methods on it.
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final url = Uri.parse('${AppConstants.baseUrl}/user/login/'); // Your Django login endpoint

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': _emailController.text,
            'password': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final token = responseData['access']; // must match with your Django backend's response structure
          // You might also get user data here: final user = responseData['user'];

          await appProvider.saveAuthToken(token); // Stores the token in SharedPreferences and updates AppProvider's state.

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login successful!')),
          );

          // Navigate to Home Screen and replace the current route
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['detail'] ?? 'Login failed. Please check your credentials.'; // Adjust based on Django error key
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } catch (e) {
        // Handle network errors or unexpected responses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(  //provides a basic visual structure 
      appBar: AppBar( //top bar of the screen, containing the title
        title: const Text('Login'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView( // This widget makes its child scrollable. Prevents overflow errors and allows the user to scroll to view all fields. Always use this for forms.
            child: Form(  // A container widget that groups TextFormField widgets and allows for collective validation.
              key: _formKey,
              child: Column(  //Arranges children vertically
                mainAxisAlignment: MainAxisAlignment.center,  // centers the children vertically within the available space.
                crossAxisAlignment: CrossAxisAlignment.stretch, // stretch to fill the available horizontal space.
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 100,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 40),
                  //TextFormField:

                    // controller: Links the [TextEditingController] to this input field.

                    // keyboardType: Suggests the type of keyboard to display (e.g., [TextInputType.emailAddress] for email).

                    // obscureText: true: Hides the input characters (useful for passwords).

                    // decoration: An [InputDecoration] object that defines the visual appearance of the input field (label, border, prefix icon, etc.).

                    // validator: A function that's called when [_formKey.currentState!.validate()] is invoked. It takes the current input value as an argument. If the input is valid, it should return null. If invalid, it should return a string containing the error message.
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true, // Hides the input
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      // Navigate to Forgot Password screen (optional, not building for now)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Forgot Password Tapped!')),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton( //text-only button, often used for secondary actions or links like "Register Now".
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                          );
                        },
                        child: const Text(
                          'Register Now',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}