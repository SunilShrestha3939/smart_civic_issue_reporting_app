import 'package:flutter/material.dart';
import 'package:smart_civic_app/screens/registration_screen.dart'; // We'll create this next
import 'package:smart_civic_app/screens/home_screen.dart'; // We'll create this next

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

  @override
  //to prevent memory leaks, dispose() of [TextEditingControllers] when the [StatefulWidget] is removed from the widget tree 
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    // [_formKey.currentState!.validate()]: This is the magic line that triggers the validator function for every [TextFormField] inside this Form. If all validators return [null], the form is valid, and this method returns [true]. Otherwise, it returns false, and the error messages are displayed.
    if (_formKey.currentState!.validate()) {
 
      print('Logging in with:');
      print('Email: ${_emailController.text}');
      print('Password: ${_passwordController.text}');

      // Simulate a successful login (replace with actual API call later)
      Future.delayed(const Duration(seconds: 1), () { // Simulate network delay
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()), // Navigate to our new HomeScreen
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
      });
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