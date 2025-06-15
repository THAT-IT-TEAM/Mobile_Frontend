import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:it_team_app/auth_service.dart';

class OcrService {
  static final String apiBaseUrl = dotenv.env['API_URL'] ?? '';

  Future<void> callOcrApi({
    required String fileUrl,
    required String userId,
    required String tripId,
  }) async {
    if (apiBaseUrl.isEmpty) {
      print('Error: API_BASE_URL not found in .env file.');
      return;
    }
    final token = await AuthService().getToken();
    final String ocrEndpoint = '$apiBaseUrl/ocr';

    try {
      final response = await http.post(
        Uri.parse(ocrEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String?>{
          'file_url': fileUrl,
          'user_id': userId,
          'trip_id': tripId,
        }),
      );

      if (response.statusCode == 200) {
        print('OCR API call successful: ${response.body}');
      } else if (response.statusCode == 401) {
        await AuthService().clearToken();
        print('Unauthorized. Please log in again.');
      } else {
        print('OCR API call failed: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error making OCR API call: $e');
    }
  }
}