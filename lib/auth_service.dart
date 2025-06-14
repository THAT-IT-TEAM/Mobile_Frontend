import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String apiBaseUrl = 'https://good-polecat-enormously.ngrok-free.app';

  // Helper to build API URL
  String getApiUrl(String path) => '$apiBaseUrl$path';

  // Token Management
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  // User Management
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(userKey);
    return userData != null ? jsonDecode(userData) : null;
  }

  Future<void> setCurrentUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(user));
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  Future<bool> hasRole(String role) async {
    final user = await getCurrentUser();
    return user != null && user['role'] == role;
  }

  // API Calls
  Future<Map<String, dynamic>> login(String email, String password, String walletId) async {
    try {
      final response = await http.post(
        Uri.parse(getApiUrl('/auth/login')),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'walletId': walletId}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['token'] != null) {
        await setToken(data['token']);
        await setCurrentUser(data['user']);
        return {'token': data['token'], 'user': data['user']};
      }
      throw Exception(data['error'] ?? 'Login failed');
    } on SocketException {
      throw Exception("Currently offline, please try again later");
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String walletId, {String? role}) async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await http.post(
        Uri.parse(getApiUrl('/auth/register')),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'walletId': walletId,
          if (role != null) 'role': role,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['user'] != null) {
        // If token is returned (e.g., for admin), store it
        if (data['token'] != null) {
          await setToken(data['token']);
          await setCurrentUser(data['user']);
        }
        return data;
      }
      throw Exception(data['error'] ?? 'Registration failed. Please try again.');
    } on SocketException {
      throw Exception("Currently offline, please try again later");
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await clearToken();
  }

  Future<bool> isAdmin() async {
    final user = await getCurrentUser();
    return user != null && user['role'] == 'admin';
  }

  // Get auth headers for API calls
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}