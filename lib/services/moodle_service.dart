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
  
  // ==================== TOKEN MANAGEMENT ====================
  
  // Save Moodle token to both memory and SharedPreferences
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
      print('Moodle token cleared');
    } catch (e) {
      print('Error clearing token: $e');
    }
  }
  
  // ==================== AUTHENTICATION METHODS ====================
  
  // Main authentication method - tries all available methods to get a token
  Future<String?> authenticateAndGetToken() async {
    try {
      // First check if we already have a token
      String? existingToken = await getMoodleToken();
      if (existingToken != null) {
        print('Using existing Moodle token');
        return existingToken;
      }
      
      print('No existing token, trying to authenticate...');
      
      // Try to authenticate with Google
      bool success = await authenticateWithGoogle();
      if (success) {
        existingToken = await getMoodleToken();
        if (existingToken != null) {
          print('Successfully authenticated with Google');
          return existingToken;
        }
      }
      
      // If Google authentication fails, try test credentials
      print('Google authentication failed, trying test credentials...');
      success = await getTokenWithTestCredentials();
      if (success) {
        existingToken = await getMoodleToken();
        if (existingToken != null) {
          print('Successfully authenticated with test credentials');
          return existingToken;
        }
      }
      
      // If all authentication methods fail, use a static fallback token for development
      // IMPORTANT: Remove this in production!
      print('All authentication methods failed, using fallback token');
      const fallbackToken = "e494a3e809d707053de0b0d5a9eb35c7"; // Add your static token here for development
      if (fallbackToken.isNotEmpty) {
        await saveMoodleToken(fallbackToken);
        return fallbackToken;
      }
      
      print('Authentication failed - no token available');
      return null;
    } catch (e) {
      print('Error in authenticateAndGetToken: $e');
      return null;
    }
  }
  
  // Get Moodle token directly using username and password
  Future<String?> getMoodleTokenByCredentials(String username, String password) async {
    try {
      // For quick testing, you can use your Moodle test account
      // In production, use the provided username and password
      final usernameToUse = username.isEmpty ? 'testuser' : username;
      final passwordToUse = password.isEmpty ? 'testpass' : password;
      
      print('Getting token with credentials: $usernameToUse');
      
      final response = await http.post(
        Uri.parse('$baseUrl/login/token.php'),
        body: {
          'username': usernameToUse,
          'password': passwordToUse,
          'service': 'moodle_mobile_app'
        }
      );
      
      print('Moodle token response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('token')) {
          final token = data['token'];
          await saveMoodleToken(token);
          return token;
        } else if (data.containsKey('error')) {
          print('Moodle error: ${data['error']}');
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
        
        print('Moodle Google auth response status: ${response.statusCode}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data.containsKey('token')) {
            // Save the token
            await saveMoodleToken(data['token']);
            print('Moodle token saved successfully via Google auth');
            return true;
          }
        }
      } catch (e) {
        print('Error with native Google auth: $e');
        // Continue to fallback method
      }
      
      // Second attempt: Try to use the email to log in
      if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
        try {
          // Many Moodle instances support auto-login by email
          final response = await http.post(
            Uri.parse('$baseUrl/login/token.php'),
            body: {
              'email': firebaseUser.email,
              'service': 'moodle_mobile_app'
            }
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data.containsKey('token')) {
              await saveMoodleToken(data['token']);
              print('Moodle token saved via email auth');
              return true;
            }
          }
        } catch (e) {
          print('Error with email auth: $e');
        }
      }
      
      // Last attempt: Try token.php with username = email
      if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
        try {
          // Use the email as username in a token request
          final response = await http.post(
            Uri.parse('$baseUrl/login/token.php'),
            body: {
              'username': firebaseUser.email,
              'password': 'googleauth', // This usually won't work but trying as last resort
              'service': 'moodle_mobile_app'
            }
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data.containsKey('token')) {
              await saveMoodleToken(data['token']);
              print('Moodle token saved via email-as-username');
              return true;
            }
          }
        } catch (e) {
          print('Error with email-as-username auth: $e');
        }
      }
      
      // All attempts failed
      return false;
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
  
  // ==================== DATA RETRIEVAL METHODS ====================
  
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
      
      print('Failed to get courses: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error getting Moodle courses: $e');
      return [];
    }
  }
  
  // Get details of a specific course
  Future<Map<String, dynamic>?> getCourseDetails(String courseId) async {
    try {
      final token = await getMoodleToken();
      if (token == null) {
        print('No Moodle token found');
        return null;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/webservice/rest/server.php'),
        body: {
          'wstoken': token,
          'wsfunction': 'core_course_get_contents',
          'moodlewsrestformat': 'json',
          'courseid': courseId
        }
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if response is an error
        if (data is Map && data.containsKey('exception')) {
          print('Moodle API error: ${data['message']}');
          return null;
        }
        
        return {'courseId': courseId, 'content': data};
      }
      
      print('Failed to get course details: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error getting course details: $e');
      return null;
    }
  }
  
  // ==================== URL AND DEEP LINKING METHODS ====================
  
  // Generate URL for deep linking to Moodle mobile app
  String getMoodleMobileDeepLink(String? courseId) {
    // Check if we have a token
    if (_cachedMoodleToken == null) {
      print('Cannot create deep link: No token available');
      return '';
    }
    
    // Create the deep link URL format
    String deepLink = 'moodlemobile://link=$baseUrl&token=$_cachedMoodleToken';
    
    // Add course ID if provided
    if (courseId != null && courseId.isNotEmpty) {
      deepLink += '&courseid=$courseId';
    }
    
    print('Created deep link: $deepLink');
    return deepLink;
  }
  
  // Generate URL for web browser with auto-login
  String getWebAutoLoginUrl(String? courseId) {
    // Check if we have a token
    if (_cachedMoodleToken == null) {
      // No token, return regular URL
      return courseId != null ? '$baseUrl/course/view.php?id=$courseId' : '$baseUrl/my/';
    }
    
    // Create web URL with token for auto-login
    // This method depends on your Moodle configuration
    // The most common approaches are:
    
    // Approach 1: Using pluginfile.php with redirect
    String webUrl = '$baseUrl/webservice/pluginfile.php?token=$_cachedMoodleToken&redirect=1';
    if (courseId != null && courseId.isNotEmpty) {
      webUrl += '&courseid=$courseId';
    }
    
    // Approach 2: Alternative for some Moodle configurations
    // String webUrl = '$baseUrl/login/token.php?token=$_cachedMoodleToken&service=moodle_mobile_app';
    // if (courseId != null && courseId.isNotEmpty) {
    //   webUrl += '&redirect=' + Uri.encodeComponent('$baseUrl/course/view.php?id=$courseId');
    // }
    
    print('Created web auto-login URL: $webUrl');
    return webUrl;
  }
  
  // Check if Moodle mobile app is installed
  Future<bool> isMoodleMobileAppInstalled() async {
    try {
      // Create a basic deep link to test
      String testUrl = 'moodlemobile://link=$baseUrl';
      return await canLaunchUrl(Uri.parse(testUrl));
    } catch (e) {
      print('Error checking if Moodle app is installed: $e');
      return false;
    }
  }
  
  // Helper method for url_launcher
  Future<bool> canLaunchUrl(Uri uri) async {
    try {
      return await checkCan(uri);
    } catch (e) {
      print('Error in canLaunchUrl: $e');
      return false;
    }
  }
  
  // This method is required to handle URL checking
  // Flutter's canLaunchUrl might not be directly accessible in this file
  Future<bool> checkCan(Uri uri) async {
    try {
      // Use your URL launcher package method here
      // This is a placeholder - in your app, use the actual method
      return true; // For testing - assume we can launch
    } catch (e) {
      print('Error checking URL: $e');
      return false;
    }
  }
}