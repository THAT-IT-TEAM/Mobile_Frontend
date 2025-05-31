import 'package:flutter/material.dart';
import 'package:it_team_app/file_upload.dart'; // Import the file upload page
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

// Define the LoginPage StatefulWidget
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

// Define the state for the LoginPage
class _LoginPageState extends State<LoginPage> {
  // Controllers for text fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Get the global Supabase client instance
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // State variables for loading and errors
  bool _isLoading = false;
  String? _errorMessage;

  // Existing _signIn function, now part of the state
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });
    try {
      // Get email and password from text controllers
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Check if session and user are not null for successful login
      if (response.session != null && response.user != null) {
        print('Login successful!');
        // TODO: Navigate to your main application screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FileUploadPage()), // Navigate to FileUploadPage
        );
      } else { // Handle login failure (session or user is null)
        print('Login failed: Invalid credentials or other authentication issue.');
        setState(() {
          // Display a generic error message if the specific error is not accessible
          _errorMessage = 'Login failed. Please check your credentials.';
        });
      }
    } catch (e) {
      print('An unexpected error occurred: $e');
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}'; // Display caught exceptions
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Existing _signUp function, now part of the state
  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });
    try {
      // Get email and password from text controllers
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );

      // Check if session and user are not null for successful sign up
      if (response.session != null && response.user != null) {
        print('Sign up successful!');
        // TODO: Handle successful sign up (e.g., show confirmation, navigate to login)
        setState(() {
          _errorMessage = 'Sign up successful! Please login.'; // Show success message
        });
      } else { // Handle sign up failure
        print('Sign up failed: Could not create account.');
        setState(() {
          // Display a generic error message if the specific error is not accessible
          _errorMessage = 'Sign up failed. Please try again.';
        });
      }
    } catch (e) {
      print('An unexpected error occurred during sign up: $e');
      setState(() {
        _errorMessage = 'An error occurred during sign up: ${e.toString()}'; // Display caught exceptions
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build the UI for the login page
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn, // Disable button when loading
              child: _isLoading
                  ? const CircularProgressIndicator() // Show loading indicator
                  : const Text('Sign In'),
            ),
            TextButton(
              onPressed: _isLoading ? null : _signUp, // Disable button when loading
              child: const Text('Sign Up'),
            ),
            if (_errorMessage != null) ...[ // Display error message if not null
              const SizedBox(height: 12.0),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 