import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final Color background = const Color(0xFFFFD3AC);
  final Color inputFill = const Color(0xFFCCBEB1);
  final Color buttonColor = const Color(0xFF664C36);
  final Color textDark = const Color(0xFF331C08);

  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
        backgroundColor: buttonColor,
      ),
      backgroundColor: background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField(hint: 'Email', obscureText: false),
                const SizedBox(height: 20),
                _buildTextField(hint: 'Password', obscureText: true),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(color: textDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String hint, required bool obscureText}) {
    return TextField(
      obscureText: obscureText,
      style: TextStyle(color: textDark),
      decoration: InputDecoration(
        filled: true,
        fillColor: inputFill,
        hintText: hint,
        hintStyle: TextStyle(color: textDark.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
