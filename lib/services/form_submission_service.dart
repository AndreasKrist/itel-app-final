import 'dart:convert';
import 'package:http/http.dart' as http;

class FormSubmissionService {
  // Use your deployed Google Apps Script web app URL
  static const String scriptUrl = 'https://script.google.com/macros/s/AKfycbyZZmJy_lpqWOpfh8ZNlX9qRxnXdTXUuRGKynv56CnElD9bU4O57P4-rKNr_2R38ctFsw/exec';
  
  /// Submits form data to the Google Sheets through Google Apps Script
  /// Returns a Future with success status and message
  static Future<Map<String, dynamic>> submitEnquiry(Map<String, dynamic> formData) async {
    try {
      // Add timestamp in ISO format
      formData['timestamp'] = DateTime.now().toIso8601String();
      
      // Use URLEncoded form data instead of JSON
      final body = formData.entries.map((e) => 
        '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}').join('&');
      
      // Send the POST request with URLEncoded data
      final response = await http.post(
        Uri.parse(scriptUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ).timeout(const Duration(seconds: 20)); // Longer timeout
      
      // Check response
      if (response.statusCode == 200 || response.statusCode == 302) {
        try {
          // Try to parse JSON response if available
          final result = jsonDecode(response.body);
          return {
            'success': true,
            'message': result['message'] ?? 'Submission successful',
          };
        } catch (e) {
          // If JSON parsing fails but status is 200 or 302, consider it success
          return {
            'success': true,
            'message': 'Submission successful',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to submit data. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error submitting enquiry: ${e.toString()}',
      };
    }
  }
}