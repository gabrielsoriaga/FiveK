import 'package:firebase_auth/firebase_auth.dart'; // handles user authentication (sign up, login, etc.)
import 'package:cloud_firestore/cloud_firestore.dart'; // lets us store extra user data in Firestore
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'login_page.dart';

// This is the main sign up screen widget
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

// State class where all the logic and UI lives
class _SignUpPageState extends State<SignUpPage> {

  // Controllers to get text from input fields
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false; // used to show loading spinner
  String errorMessage = ""; // stores any error messages to display

  // Function that runs when user presses "Create"
  Future<void> signUp() async {

    // Basic validation to check if fields are empty
    if (usernameController.text.trim().isEmpty) {
      setState(() => errorMessage = "Username is required");
      return;
    }
    if (emailController.text.trim().isEmpty) {
      setState(() => errorMessage = "Email is required");
      return;
    }
    if (passwordController.text.trim().isEmpty) {
      setState(() => errorMessage = "Password is required");
      return;
    }

    try {
      // show loading and clear old errors
      setState(() {
        isLoading = true;
        errorMessage = "";
      });

      // create user using Firebase Auth
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword( // Firebase auth basically handles everything here which makes it easy.
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user;

      // just in case something went wrong
      if (user == null) {
        setState(() {
          errorMessage = "User creation failed";
        });
        return;
      }

      // save extra user info in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({ //Set default values for a newly created user in the Firestore database, this will be used to store the user's profile information, points, streaks, and other data that is needed for the app to function properly. The 'createdAt' field is set to the server timestamp to keep track of when the user was created.
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'bio': '',
        'totalPoints': 0,
        'streakDays': 0,
        'createdAt': FieldValue.serverTimestamp(), // auto timestamp
      });

      // make sure widget still exists before navigating
      if (!mounted) return;

      // go to main app screen after successful signup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );

    // handle Firebase auth errors (like email already used, weak password, etc.)
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "Sign up failed";
      });

    // handle Firestore/database errors
    } on FirebaseException catch (e) {
      setState(() {
        errorMessage = e.message ?? "Database error";
      });

    // catch any other unexpected errors
    } catch (e) {
      setState(() {
        errorMessage = "Something went wrong: $e";
      });

    } finally {
      // stop loading spinner
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // clean up controllers when widget is removed
  @override
  void dispose() {
    usernameController.dispose();
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
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Page heading
              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // Username input
              const Text("Username:", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: _inputDecoration("Enter Username"),
              ),

              const SizedBox(height: 16),

              // Email input
              const Text("Email:", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: _inputDecoration("user123@email.com"),
              ),

              const SizedBox(height: 16),

              // Password input
              const Text("Password:", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true, // hides password
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: _inputDecoration(""),
              ),

              const SizedBox(height: 20),

              // Show error message if exists
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 12),

              // Create account button
              Center(
                child: ElevatedButton(
                  onPressed: isLoading ? null : signUp,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Create"),
                ),
              ),

              const SizedBox(height: 12),

              // Switch to login page
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text("Already have an account? Log in"),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable input field styling
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