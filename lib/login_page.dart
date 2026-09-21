import 'package:firebase_auth/firebase_auth.dart'; // used for logging users in
import 'package:flutter/material.dart';
import 'signup_page.dart';

// Login screen widget
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// Handles logic + UI for login page
class _LoginPageState extends State<LoginPage> {

  // Controllers to read input values
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false; // controls loading spinner
  String errorMessage = ""; // stores error messages

  // Function that runs when user presses "Log In"
  Future<void> login() async {

    // check if email is empty
    if (emailController.text.trim().isEmpty) {
      setState(() => errorMessage = "Email is required");
      return;
    }

    // check if password is empty
    if (passwordController.text.trim().isEmpty) {
      setState(() => errorMessage = "Password is required");
      return;
    }
    
    try {
      // start loading and clear old errors
      setState(() {
        isLoading = true;
        errorMessage = "";
      });

      // attempt login using Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword( //signInWithEmailAndPassword is a method provided by FirebaseAuth that takes an email and password as arguments and attempts to sign in the user with those credentials. If the login is successful, Firebase will handle the user session automatically and the auth state will change, which will trigger the AuthGate to show the main navigation instead of the login page.
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // if successful, Firebase handles session automatically

    // catch login errors (wrong password, user not found, etc.)
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "Login failed";
      });

    } finally {
      // stop loading spinner
      setState(() {
        isLoading = false;
      });
    }
  }

  // clean up controllers when widget is removed
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // UI layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // App title
              const Center(
                child: Text(
                  "FiveK",
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 40),

              // Page heading
              const Text(
                "Log In",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // Email input
              const Text("Email:"),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: _inputDecoration("Enter Email Address"),
              ),

              const SizedBox(height: 16),

              // Password input
              const Text("Password:"),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true, // hides password
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: _inputDecoration("Enter Password"),
              ),

              const SizedBox(height: 20),

              // show error message if there is one
              if (errorMessage.isNotEmpty)
                Text(errorMessage, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 12),

              // login button
              Center(
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Log In"),
                ),
              ),

              const SizedBox(height: 12),

              // navigate to sign up page
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  child: const Text("No account yet? Sign up"),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // reusable styling for input fields
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }
}