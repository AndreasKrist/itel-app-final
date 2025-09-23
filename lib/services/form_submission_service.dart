import 'dart:convert';
import 'package:http/http.dart' as http;

class FormSubmissionService {
  // Replace this with your new deployed Google Apps Script web app URL
  static const String scriptUrl = 'https://script.google.com/macros/s/AKfycby1sMTVuKreooY5blAxoTm0_i9oQbtbyALtnE0h1z27YqVDX5SUEdcCZMelZvJ-Jc7U/exec';
  
  /// Submits form data to the Google Sheets through Google Apps Script
  /// Returns a Future with success status and message
  static Future<Map<String, dynamic>> submitEnquiry(Map<String, dynamic> formData) async {
    try {
      print('Starting form submission to Google Sheets');
      
      // Add timestamp in ISO format
      formData['timestamp'] = DateTime.now().toIso8601String();

      // Convert form data to JSON
      final jsonData = jsonEncode(formData);

      print('Sending request to: $scriptUrl');
      print('Request data: $jsonData');

      // Send the POST request with JSON data
      final response = await http.post(
        Uri.parse(scriptUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonData,
      ).timeout(const Duration(seconds: 30)); // Longer timeout
      
      print('Received response with status code: ${response.statusCode}');
      
      // Check response
      if (response.statusCode == 200 || response.statusCode == 302) {
        try {
          // Try to parse JSON response if available
          print('Response body: ${response.body}');
          final result = jsonDecode(response.body);
          return {
            'success': true,
            'message': result['message'] ?? 'Submission successful',
          };
        } catch (e) {
          print('Failed to parse JSON response: $e');
          // If JSON parsing fails but status is 200 or 302, consider it success
          return {
            'success': true,
            'message': 'Submission successful',
          };
        }
      } else {
        print('Failed request with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to submit data. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error in submission service: $e');
      return {
        'success': false,
        'message': 'Error submitting enquiry: ${e.toString()}',
      };
    }
  }
  
  /// For testing or when Google Sheets is unavailable
  static Future<Map<String, dynamic>> mockSubmitEnquiry(Map<String, dynamic> formData) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Always return success
    return {
      'success': true,
      'message': 'Submission successful (mock)',
    };
  }

  
}