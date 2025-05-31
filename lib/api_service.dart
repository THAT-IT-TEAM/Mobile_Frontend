import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  Future<void> callOcrApi({
    required String fileUrl,
    required String userId,
    required String tripId,
  }) async {
    final String? apiUrl = dotenv.env['API_BASE_URL']; // Get API base URL from .env

    if (apiUrl == null) {
      print('Error: API_BASE_URL not found in .env file.');
      // Handle error appropriately, maybe throw an exception or show a message
      return;
    }

    final String ocrEndpoint = '$apiUrl/ocr'; // Construct the full endpoint URL

    try {
      final response = await http.post(
        Uri.parse(ocrEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String?>{
          'file_url': fileUrl,
          'user_id': userId,
          'trip_id': tripId,
        }),
      );

      if (response.statusCode == 200) {
        // API call successful, handle the response if needed
        print('OCR API call successful: ${response.body}');
      } else {
        // API call failed, handle the error
        print('OCR API call failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        // Handle error appropriately, maybe throw an exception or show a message
      }
    } catch (e) {
      // Handle any exceptions during the API call
      print('Error making OCR API call: $e');
      // Handle error appropriately
    }
  }
} 