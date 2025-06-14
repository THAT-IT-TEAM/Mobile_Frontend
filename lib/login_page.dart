import 'package:flutter/material.dart';
import 'package:it_team_app/file_upload.dart';
import 'package:it_team_app/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSupabaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSupabase();
  }

  Future<void> _initializeSupabase() async {
    await _supabaseService.initialize();
    setState(() {
      _isSupabaseInitialized = true;
    });
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      final response = await _supabaseService.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null && response.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FileUploadPage()),
        );
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = (e is AuthException)
            ? 'Login failed: ${e.message}'
            : 'An unexpected error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      final response = await _supabaseService.signUp(
        email: email,
        password: password,
      );

      setState(() {
        _errorMessage = (response.session != null && response.user != null)
            ? 'Sign up successful! Please login.'
            : 'Sign up failed. Please try again.';
      });
    } catch (e) {
      setState(() {
        if (e is AuthException) {
          _errorMessage = e.message.contains('User already registered')
              ? 'Account already exists. Please sign in.'
              : 'Sign up failed: ${e.message}';
        } else {
          _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1E1E1E);
    const cardColor = Color(0xFF2C2C2C);
    const textColor = Color(0xFFE0E2DB);

    if (!_isSupabaseInitialized) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: textColor)),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text('Welcome Back', style: TextStyle(color: textColor)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Animate(
            effects: [FadeEffect(), ScaleEffect()],
            child: Container(
              padding: const EdgeInsets.all(24.0),
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: textColor),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: textColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: (!_isSupabaseInitialized || _isLoading) ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: textColor)
                        : const Text('Sign In', style: TextStyle(color: textColor)),
                  ),
                  const SizedBox(height: 12.0),
                  TextButton(
                    onPressed: (!_isSupabaseInitialized || _isLoading) ? null : _signUp,
                    child: const Text('Sign Up', style: TextStyle(color: textColor)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FileUploadPage()),
                      );
                    },
                    child: const Text('Go to File Upload Page', style: TextStyle(color: textColor)),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12.0),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
