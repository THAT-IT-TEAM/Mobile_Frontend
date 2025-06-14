import 'package:flutter/material.dart';
import 'package:it_team_app/file_upload.dart';
import 'package:it_team_app/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:it_team_app/dashboard.dart';

class LandingLoginPage extends StatefulWidget {
  const LandingLoginPage({super.key});

  @override
  State<LandingLoginPage> createState() => _LandingLoginPageState();
}

class _LandingLoginPageState extends State<LandingLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();

  bool _showLogin = false;
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
          MaterialPageRoute(builder: (context) => const DashboardPage()),
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
    const backgroundColor = Color(0xFF121212);
    const textColor = Colors.white;
    const cardColor = Color(0xFF1E1E1E);

    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Arrow Panel (Landing Page)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
            top: _showLogin ? -height : height * 0.25,
            left: 0,
            right: 0,
            height: height,
            child: Stack(
              children: [
                CustomPaint(
                  painter: ArrowPainter(),
                  size: Size(double.infinity, height),
                ),
                Center(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, 200),
                        painter: ArrowPainter(),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 1.0, end: _showLogin ? 2.0 : 1.0),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _showLogin = true);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(color: Colors.white, width: 2),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.arrow_upward_rounded,
                                        color: Colors.white, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Log In',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Login Panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
            top: _showLogin ? 0 : height,
            left: 0,
            right: 0,
            height: height,
            child: Center(
              child: SingleChildScrollView(
                child: Animate(
                  effects: [
                    FadeEffect(duration: 300.ms),
                    SlideEffect(begin: const Offset(0, 0.1))
                  ],
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24.0),
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Welcome Back',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white),
                              onPressed: () =>
                                  setState(() => _showLogin = false),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: textColor),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: textColor),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: textColor),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: textColor),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
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
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: textColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: (!_isSupabaseInitialized || _isLoading)
                              ? null
                              : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: textColor)
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                      color: textColor, fontSize: 16),
                                ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: (!_isSupabaseInitialized || _isLoading)
                              ? null
                              : _signUp,
                          child: const Text(
                            'Don\'t have an account? Sign Up',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style:
                                const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter for the arrow
class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E1E1E) // dark grey fill
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start from top-left
    path.moveTo(0, 100);

    // Top curve
    path.quadraticBezierTo(size.width / 2, 0, size.width, 100);

    // Right edge down
    path.lineTo(size.width, size.height);

    // Bottom edge left
    path.lineTo(0, size.height);

    // Left edge up
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
