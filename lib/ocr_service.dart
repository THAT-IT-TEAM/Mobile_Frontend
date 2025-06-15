import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:it_team_app/auth_service.dart';
import 'package:it_team_app/api_service.dart';

class OcrError extends Error {
  final String message;
  final int? statusCode;

  OcrError(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class OcrService {
  final ApiService _apiService = ApiService();
  static final String apiUrl = dotenv.env['API_URL'] ?? '';
  static final String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';

  Future<String> _getCurrentUserId() async {
    final authService = AuthService();
    final email = await authService.getCurrentUserEmail();
    if (email == null) {
      throw OcrError('User email not found. Please log in again.');
    }
    final userId = await _apiService.getUserIdByEmail(email);
    if (userId == null) {
      throw OcrError('User ID not found for email');
    }
    return userId;
  }

  Future<String> callOcrApi({
    required String fileUrl,
    String? userId,
    required String tripId,
  }) async {
    if (apiUrl.isEmpty) {
      throw OcrError('API_URL not configured in environment');
    }

    // Validate inputs
    if (fileUrl.isEmpty) {
      throw OcrError('File URL is required');
    }
    if (tripId.isEmpty) {
      throw OcrError('Trip ID is required');
    }

    // Get userId if not provided
    final String actualUserId = userId ?? await _getCurrentUserId();
    if (actualUserId.isEmpty) {
      throw OcrError('User ID is required');
    }

    final token = await AuthService().getToken();
    if (token == null) {
      throw OcrError('Authentication token not found', statusCode: 401);
    }

    final String ocrEndpoint = '$apiUrl/ocr';

    try {
      print('Calling OCR endpoint: $ocrEndpoint'); // Debug print
      final response = await http.post(
        Uri.parse(ocrEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true', // Add this for ngrok endpoints
        },
        body: jsonEncode(<String, String>{
          'file_url': fileUrl,
          'user_id': actualUserId,
          'trip_id': tripId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Validate OCR response data
        if (responseData == null || responseData is! Map<String, dynamic>) {
          throw OcrError('Invalid OCR response format');
        }

        // Extract expense_id from response
        final expenseId = responseData['expense_id'] as String?;
        if (expenseId == null || expenseId.isEmpty) {
          throw OcrError('Missing expense ID in response');
        }

        return expenseId;
      } else if (response.statusCode == 401) {
        await AuthService().clearToken();
        throw OcrError('Session expired. Please log in again.', statusCode: 401);
      } else {
        throw OcrError(
          'OCR processing failed: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is OcrError) rethrow;
      throw OcrError('Failed to process receipt: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getExpenseDetails(String expenseId) async {
    if (apiBaseUrl.isEmpty) {
      throw OcrError('API_BASE_URL not configured in environment');
    }

    if (expenseId.isEmpty) {
      throw OcrError('Expense ID is required');
    }

    final token = await AuthService().getToken();
    if (token == null) {
      throw OcrError('Authentication token not found', statusCode: 401);
    }
    final endpoint = '$apiBaseUrl/api/expenses';
    try {
      print('Calling endpoint: $endpoint'); // Debug print
      final response = await http.get(
        Uri.parse(endpoint),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      String responseBody = response.body;

      // Check for HTML error page
      if (responseBody.trim().toLowerCase().startsWith('<!doctype html>') ||
          responseBody.trim().toLowerCase().startsWith('<html>')) {
        throw OcrError(
          'Server returned an HTML error page. Please check the API endpoint configuration.',
          statusCode: response.statusCode,
        );
      }
      if (response.statusCode == 200) {
        try {
          final expense = jsonDecode(responseBody);
          if (expense == null || expense is! Map<String, dynamic>) {
            throw OcrError('Invalid expense data format', statusCode: 500);
          }

          return expense;
        } catch (e) {
          if (e is OcrError) rethrow;
          throw OcrError(
            'Invalid JSON response: ${e.toString()}\nResponse body: ${responseBody.substring(0, 100)}...',
          );
        }
      } else if (response.statusCode == 401) {
        await AuthService().clearToken();
        throw OcrError('Session expired. Please log in again.', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw OcrError('Expense details not found', statusCode: 404);
      } else {
        throw OcrError(
          'Failed to fetch expense details (Status ${response.statusCode}): $responseBody',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is OcrError) rethrow;
      throw OcrError('Failed to fetch expense details: ${e.toString()}');
    }
  }

  Future<void> updateExpenseDetails(String expenseId, Map<String, dynamic> updates) async {
    final token = await AuthService().getToken();
    if (token == null) {
      print('[updateExpenseDetails] Authentication token not found');
      throw OcrError('Authentication token not found', statusCode: 401);
    }

    final endpoint = '$apiBaseUrl/api/expenses';
    print('[updateExpenseDetails] PATCH $endpoint');
    print('[updateExpenseDetails] Updates: $updates');

    try {
      final response = await http.patch(
        Uri.parse(endpoint),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      );

      print('[updateExpenseDetails] Response status: ${response.statusCode}');
      print('[updateExpenseDetails] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('[updateExpenseDetails] Expense updated successfully');
        return;
      } else if (response.statusCode == 401) {
        await AuthService().clearToken();
        print('[updateExpenseDetails] Session expired. Clearing token.');
        throw OcrError('Session expired. Please log in again.', statusCode: 401);
      } else {
        print('[updateExpenseDetails] Failed to update expense details: ${response.body}');
        throw OcrError(
          'Failed to update expense details: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('[updateExpenseDetails] Exception: $e');
      if (e is OcrError) rethrow;
      throw OcrError('Failed to update expense details: ${e.toString()}');
    }
  }
}