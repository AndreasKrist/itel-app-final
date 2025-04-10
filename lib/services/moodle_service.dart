// lib/services/moodle_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class MoodleService {
  // Your Moodle site URL - replace with your actual Moodle URL
  static const String baseUrl = 'https://online.itel.com.sg';
  
  // Store Moodle token in memory to avoid SharedPreferences issues
  static String? _cachedMoodleToken;
  
  // Save Moodle token to both memory and SharedPreferences as backup
  Future<void> saveMoodleToken(String token) async {
    _cachedMoodleToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('moodle_token', token);
      print('Token saved to SharedPreferences: $token');
    } catch (e) {
      print('Error saving to SharedPreferences, using memory only: $e');
    }
  }
  
  // Get stored Moodle token from memory first, then try SharedPreferences
  Future<String?> getMoodleToken() async {
    // First check in-memory cache
    if (_cachedMoodleToken != null) {
      print('Using cached token from memory');
      return _cachedMoodleToken;
    }
    
    // Try SharedPreferences as fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('moodle_token');
      if (token != null) {
        _cachedMoodleToken = token; // Update cache
        print('Retrieved token from SharedPreferences');
      }
      return token;
    } catch (e) {
      print('Error accessing SharedPreferences: $e');
      return null;
    }
  }
  
  // Clear Moodle token (for logout)
  Future<void> clearMoodleToken() async {
    _cachedMoodleToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('moodle_token');
    } catch (e) {
      print('Error clearing token: $e');
    }
  }
  
  // Get Moodle token directly using username and password
  Future<String?> getMoodleTokenByCredentials(String username, String password) async {
    try {
      // This is for testing only - hardcoded credentials should never be in production
      username = 'testuser';  // Replace with actual test credentials or remove
      password = 'testpass';  // these lines in production
      
      final response = await http.post(
        Uri.parse('$baseUrl/login/token.php'),
        body: {
          'username': username,
          'password': password,
          'service': 'moodle_mobile_app'
        }
      );
      
      print('Moodle token response status: ${response.statusCode}');
      print('Moodle token response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('token')) {
          final token = data['token'];
          await saveMoodleToken(token);
          return token;
        }
      }
      return null;
    } catch (e) {
      print('Error getting token by credentials: $e');
      return null;
    }
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
      
      // Last resort: try using test credentials
      return await getTokenWithTestCredentials();
    } catch (e) {
      print('Error authenticating with Moodle: $e');
      return false;
    }
  }
  
  // Test method to get a token for demo purposes
  Future<bool> getTokenWithTestCredentials() async {
    try {
      final token = await getMoodleTokenByCredentials('testuser', 'testpass');
      return token != null;
    } catch (e) {
      print('Error getting test token: $e');
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
  
  // Get direct SSO URL for Moodle (this is a simpler approach)
  String getMoodleSsoUrl(String? courseId) {
    // Get the Firebase user
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    
    // Generate a SSO URL - note this would need server-side support
    // This is just a placeholder - your actual implementation would depend
    // on how your Moodle site handles SSO
    String ssoUrl = '$baseUrl';
    
    if (courseId != null) {
      ssoUrl += '/course/view.php?id=$courseId';
    } else {
      ssoUrl += '/my/';
    }
    
    // Add user email as a parameter that your Moodle site could use for auto-login
    // (This requires custom Moodle configuration)
    if (firebaseUser?.email != null) {
      ssoUrl += '&autologin=true&email=${Uri.encodeComponent(firebaseUser!.email!)}';
    }
    
    return ssoUrl;
  }
}