import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:it_team_app/auth_service.dart'; // <-- For token management

class ApiService {
  static final String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'https://good-polecat-enormously.ngrok-free.app';

  // Helper to get auth headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Fetch trips from backend
  Future<List<Map<String, dynamic>>> getTrips() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$apiBaseUrl/api/trips'), headers: headers);
    print('Trips API status: ${response.statusCode}');
    print('Trips API body: ${response}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['trips']);
    } else if (response.statusCode == 401) {
      await AuthService().clearToken();
      throw Exception('Unauthorized. Please log in again.');
    } else {
      throw Exception('Failed to fetch trips');
    }
  }

  // Fetch trips from backend for a specific user
  Future<List<Map<String, dynamic>>> getTripsByUser(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$apiBaseUrl/api/trips?userId=$userId'), headers: headers);
    print('Trips API status: ${response.statusCode}');
    print('Trips API body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['trips']);
    } else if (response.statusCode == 401) {
      await AuthService().clearToken();
      throw Exception('Unauthorized. Please log in again.');
    } else {
      throw Exception('Failed to fetch trips');
    }
  }
  // Upload file to backend (multipart/form-data, field name 'file')
  Future<String?> uploadFile(File file) async {
    final token = await AuthService().getToken();
    final uri = Uri.parse('$apiBaseUrl/api/files');
    final request = http.MultipartRequest('POST', uri)
      ..fields['bucket'] = 'images'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final response = await request.send();
    print('Upload status: ${response.statusCode}');
    final respStr = await response.stream.bytesToString();
    print('Upload response: $respStr');

    if (response.statusCode == 201) {
      // Construct the file URL manually
      final fileName = file.path.split('/').last;
      final fileUrl = '$apiBaseUrl/uploads/images/$fileName';
      return fileUrl;
    } else if (response.statusCode == 401) {
      await AuthService().clearToken();
      throw Exception('Unauthorized. Please log in again.');
    }
    return null;
  }

  Future<String?> getUserIdByEmail(String email) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$apiBaseUrl/api/users?email=$email');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Assuming backend returns { users: [...] } or just an array
      final users = data['users'] ?? data;
      if (users is List) {
        final user = users.firstWhere(
          (u) => u['email'] == email,
          orElse: () => null,
        );
        if (user != null) {
          return user['id'] as String;
        }
      }
      throw Exception('User not found with this email');
    } else {
      print('Error fetching user ID by email: ${response.body}');
      throw Exception('User not found with this email');
    }
  }
}