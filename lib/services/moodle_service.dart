import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class MoodleService {
  // Your Moodle site URL - replace with your actual Moodle URL
  static const String baseUrl = 'https://online.itel.com.sg';
  
  // Save Moodle token
  Future<void> saveMoodleToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('moodle_token', token);
  }
  
  // Get stored Moodle token
  Future<String?> getMoodleToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('moodle_token');
  }
  
  // Clear Moodle token (for logout)
  Future<void> clearMoodleToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('moodle_token');
  }
  
  // Get or create Moodle token using Google ID token
  Future<bool> authenticateWithGoogle() async {
    try {
      print('Authenticating with Moodle using Google...');
      // Get the current Firebase user
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        print('No Firebase user found');
        return false;
      }
      
      // Get ID token from Firebase
      final idToken = await firebaseUser.getIdToken();
      
      // First try to use the native Moodle Google OAuth endpoint
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/login/token.php'),
          body: {
            'googleoauth_token': idToken,
            'service': 'moodle_mobile_app'
          }
        );
        
        print('Moodle response status: ${response.statusCode}');
        print('Moodle response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data.containsKey('token')) {
            // Save the token
            await saveMoodleToken(data['token']);
            print('Moodle token saved successfully');
            return true;
          }
        }
      } catch (e) {
        print('Error with native Google auth: $e');
        // Continue to fallback method
      }
      
      // Fallback method: Match based on email
      print('Trying fallback authentication method');
      try {
        // Use the email to get a token via mobile service
        final response = await http.post(
          Uri.parse('$baseUrl/login/token.php'),
          body: {
            'username': firebaseUser.email,
            'service': 'moodle_mobile_app'
          }
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data.containsKey('token')) {
            // Save the token
            await saveMoodleToken(data['token']);
            print('Moodle token saved via fallback method');
            return true;
          }
        }
      } catch (e) {
        print('Error with fallback auth: $e');
      }
      
      return false;
    } catch (e) {
      print('Error authenticating with Moodle: $e');
      return false;
    }
  }
  
  // Get user's enrolled courses from Moodle
  Future<List<Map<String, dynamic>>> getUserCourses() async {
    try {
      final token = await getMoodleToken();
      if (token == null) {
        print('No Moodle token found');
        return [];
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/webservice/rest/server.php'),
        body: {
          'wstoken': token,
          'wsfunction': 'core_enrol_get_users_courses',
          'moodlewsrestformat': 'json',
          'userid': '0' // 0 means current user
        }
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if response is an error
        if (data is Map && data.containsKey('exception')) {
          print('Moodle API error: ${data['message']}');
          return [];
        }
        
        if (data is List) {
          print('Successfully retrieved ${data.length} courses from Moodle');
          return data.map((course) => course as Map<String, dynamic>).toList();
        }
      }
      
      print('Failed to get courses: ${response.statusCode}, ${response.body}');
      return [];
    } catch (e) {
      print('Error getting Moodle courses: $e');
      return [];
    }
  }
}