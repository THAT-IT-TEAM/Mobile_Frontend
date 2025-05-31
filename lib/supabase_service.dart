import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv

class SupabaseService {
  // TODO: Replace with your Supabase URL and public anon key
  final String supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;

  late final SupabaseClient client;

  Future<void> initialize() async {
    // Ensure Flutter binding is initialized already in main
    // WidgetsFlutterBinding.ensureInitialized();

    // Ensure Supabase is initialized
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    client = Supabase.instance.client;
  }

  // --- Authentication Methods ---

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return client.auth.signUp(
      email: email,
      password: password,
    );
  }

  // --- File Upload Method ---

  Future<String?> uploadFile(File file, String bucketName, String filePath) async {
    try {
      // Upload the file to the specified bucket and path
      // The upload method returns the path of the uploaded file on success
      final String uploadedFilePath = await client.storage
          .from(bucketName)
          .upload(filePath, file, fileOptions: const FileOptions(cacheControl: '3600')); // Added cacheControl

      // If the upload is successful, get the public URL
      // The getPublicUrl method directly returns the URL string
      final String publicUrl = client.storage
          .from(bucketName)
          .getPublicUrl(uploadedFilePath);

      print('Successfully uploaded file to $bucketName/$uploadedFilePath. Public URL: $publicUrl');
      return publicUrl; // Return the public URL string

    } catch (e) {
      // Handle errors during upload or getting public URL
      print('Error uploading file to $bucketName/$filePath: $e');
      return null; // Indicate failure
    }
  }

  // --- Trip Methods ---

  Future<List<Map<String, dynamic>>?> getTripsForCurrentUser() async {
    final User? user = client.auth.currentUser;

    if (user == null) {
      print('No user logged in.');
      return null; // Return null if no user is logged in
    }

    try {
      // Fetch trips for the current user from the 'trips' table
      final List<Map<String, dynamic>> trips = await client
          .from('trips')
          .select('id, name') // Select only id and name for the dropdown
          .eq('user_id', user.id);

      print('Successfully fetched trips for user ${user.id}');
      return trips; // Return the list of trips

    } catch (e) {
      print('Error fetching trips: $e');
      return null; // Indicate failure
    }
  }
} 