import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  late final SupabaseClient client;

  Future<void> initialize() async {
    try {
      final String? supabaseUrl = dotenv.env['SUPABASE_URL'];
      final String? supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseAnonKey == null) {
        throw Exception('Supabase URL or Anon Key is missing from .env file.');
      }

      // Check if Supabase is already initialized by trying to access the client
      try {
        Supabase.instance.client;
        print('[SupabaseService] Supabase already initialized.');
      } catch (_) {
        print('[SupabaseService] Initializing Supabase...');
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        );
        print('[SupabaseService] Supabase initialized successfully.');
      }

      client = Supabase.instance.client;
    } catch (e) {
      print('[SupabaseService] Initialization error: $e');
      rethrow;
    }
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
      final String uploadedFilePath = await client.storage
          .from(bucketName)
          .upload(filePath, file, fileOptions: const FileOptions(cacheControl: '3600'));

      final String publicUrl = client.storage
          .from(bucketName)
          .getPublicUrl(uploadedFilePath);

      print('Successfully uploaded file to $bucketName/$uploadedFilePath. Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading file to $bucketName/$filePath: $e');
      return null;
    }
  }

  // --- Trip Methods ---

  Future<List<Map<String, dynamic>>?> getTripsForCurrentUser() async {
    final User? user = client.auth.currentUser;

    if (user == null) {
      print('No user logged in.');
      return null;
    }

    try {
      final List<Map<String, dynamic>> trips = await client
          .from('trips')
          .select('id, name')
          .eq('user_id', user.id);

      print('Successfully fetched trips for user ${user.id}');
      return trips;
    } catch (e) {
      print('Error fetching trips: $e');
      return null;
    }
  }
}
