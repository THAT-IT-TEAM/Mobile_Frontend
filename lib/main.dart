import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:it_team_app/file_upload.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:it_team_app/landing_page.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load the .env file
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IT Team App',
      theme: ThemeData(
        fontFamily: 'EudoxusSans', // Set default font
      ),
      home: LandingLoginPage(),
    );
  }
}