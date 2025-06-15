import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:it_team_app/auth_service.dart';

class ExpenseService {
  final AuthService _authService = AuthService();

  Future<List<dynamic>> getExpensesByEmail() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final email = await _authService.getCurrentUserEmail();
      
      if (email == null) {
        throw Exception('User email not found. Please log in again.');
      }

      final response = await http.post(
        Uri.parse('${AuthService.apiBaseUrl}/api/expenses/by-email'),
        headers: headers,
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('Expenses fetched successfully: ${data['expenses']}');
        return data['expenses'];
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception('Failed to load expenses: ${errorData['error'] ?? response.statusCode}');
      }
    } catch (e) {
      print('Error fetching expenses by email: $e');
      rethrow;
    }
  }
}
