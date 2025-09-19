import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';

class CourseRemoteConfigService {
  static const String _cacheKey = 'course_remote_cache';
  static const String _cacheTimestampKey = 'course_remote_cache_timestamp';
  static const Duration _cacheValidityDuration = Duration(seconds: 0); // No cache - always fetch fresh content

  // GitHub raw content URL for course configuration
  // Using the same repo as trending content
  static const String _coursesConfigUrl = 'https://raw.githubusercontent.com/AndreasKrist/Trending_item/main/courses.json';

  /// Fetches course configuration from remote source with caching and fallback
  Future<List<Course>> getRemoteCourses() async {
    try {
      // Check cache first
      final cachedCourses = await _getCachedCourses();
      if (cachedCourses != null && await _isCacheValid()) {
        print('Using cached course configuration');
        return cachedCourses;
      }

      // Fetch from remote if cache is invalid or empty
      print('Fetching course configuration from remote...');
      final remoteCourses = await _fetchFromRemote();

      // Cache the new configuration
      await _cacheCourses(remoteCourses);

      return remoteCourses;
    } catch (e) {
      print('Error fetching course configuration: $e');

      // Try to return cached content even if expired
      final cachedCourses = await _getCachedCourses();
      if (cachedCourses != null && cachedCourses.isNotEmpty) {
        print('Using expired cached course configuration as fallback');
        return cachedCourses;
      }

      // Final fallback to hardcoded content
      print('Using hardcoded fallback courses');
      return _getFallbackCourses();
    }
  }

  /// Forces refresh from remote source
  Future<List<Course>> refreshCourses() async {
    try {
      print('Force refreshing course configuration...');
      final remoteCourses = await _fetchFromRemote();
      await _cacheCourses(remoteCourses);
      return remoteCourses;
    } catch (e) {
      print('Error refreshing course configuration: $e');
      throw Exception('Failed to refresh course configuration: $e');
    }
  }

  /// Fetches course configuration from remote URL
  Future<List<Course>> _fetchFromRemote() async {
    final response = await http.get(
      Uri.parse(_coursesConfigUrl),
      headers: {
        'Cache-Control': 'no-cache',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData is Map<String, dynamic> && jsonData.containsKey('courses')) {
        final courses = jsonData['courses'] as List;
        final remoteCourses = courses.map((course) => Course(
          id: course['id'] ?? '',
          courseCode: course['courseCode'] ?? '',
          title: course['title'] ?? '',
          category: course['category'] ?? '',
          certType: course['certType'],
          rating: (course['rating'] ?? 0.0).toDouble(),
          duration: course['duration'] ?? '',
          price: course['price'] ?? '',
          funding: course['funding'],
          isFavorite: course['isFavorite'] ?? false,
          deliveryMethods: course['deliveryMethods'] != null
              ? List<String>.from(course['deliveryMethods'])
              : null,
          startDate: course['startDate'],
          nextAvailableDate: course['nextAvailableDate'],
          outline: course['outline'] != null
              ? Map<String, List<String>>.from(
                  (course['outline'] as Map).map((key, value) =>
                    MapEntry(key.toString(), List<String>.from(value))
                  )
                )
              : null,
          description: course['description'],
          prerequisites: course['prerequisites'] != null
              ? List<String>.from(course['prerequisites'])
              : null,
          whoShouldAttend: course['whoShouldAttend'],
          importantNotes: course['importantNotes'],
          feeStructure: course['feeStructure'] != null
              ? Map<String, Map<String, String>>.from(
                  (course['feeStructure'] as Map).map((key, value) =>
                    MapEntry(key.toString(), Map<String, String>.from(value))
                  )
                )
              : null,
          progress: course['progress'],
          completionDate: course['completionDate'],
          moodleCourseId: course['moodleCourseId'],
        )).toList();

        print('Loaded ${remoteCourses.length} courses from remote');
        return remoteCourses;
      } else {
        throw Exception('Invalid JSON structure in course configuration');
      }
    } else {
      throw Exception('Failed to fetch course configuration: ${response.statusCode}');
    }
  }

  /// Gets cached courses from local storage
  Future<List<Course>?> _getCachedCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);

      if (cachedJson != null) {
        final jsonData = json.decode(cachedJson);
        if (jsonData is List) {
          return jsonData.map((courseJson) => Course(
            id: courseJson['id'] ?? '',
            courseCode: courseJson['courseCode'] ?? '',
            title: courseJson['title'] ?? '',
            category: courseJson['category'] ?? '',
            certType: courseJson['certType'],
            rating: (courseJson['rating'] ?? 0.0).toDouble(),
            duration: courseJson['duration'] ?? '',
            price: courseJson['price'] ?? '',
            funding: courseJson['funding'],
            isFavorite: courseJson['isFavorite'] ?? false,
            deliveryMethods: courseJson['deliveryMethods'] != null
                ? List<String>.from(courseJson['deliveryMethods'])
                : null,
            startDate: courseJson['startDate'],
            nextAvailableDate: courseJson['nextAvailableDate'],
            outline: courseJson['outline'] != null
                ? Map<String, List<String>>.from(
                    (courseJson['outline'] as Map).map((key, value) =>
                      MapEntry(key.toString(), List<String>.from(value))
                    )
                  )
                : null,
            description: courseJson['description'],
            prerequisites: courseJson['prerequisites'] != null
                ? List<String>.from(courseJson['prerequisites'])
                : null,
            whoShouldAttend: courseJson['whoShouldAttend'],
            importantNotes: courseJson['importantNotes'],
            feeStructure: courseJson['feeStructure'] != null
                ? Map<String, Map<String, String>>.from(
                    (courseJson['feeStructure'] as Map).map((key, value) =>
                      MapEntry(key.toString(), Map<String, String>.from(value))
                    )
                  )
                : null,
            progress: courseJson['progress'],
            completionDate: courseJson['completionDate'],
            moodleCourseId: courseJson['moodleCourseId'],
          )).toList();
        }
      }
      return null;
    } catch (e) {
      print('Error reading cached courses: $e');
      return null;
    }
  }

  /// Caches courses to local storage
  Future<void> _cacheCourses(List<Course> courses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = courses.map((course) => {
        'id': course.id,
        'courseCode': course.courseCode,
        'title': course.title,
        'category': course.category,
        'certType': course.certType,
        'rating': course.rating,
        'duration': course.duration,
        'price': course.price,
        'funding': course.funding,
        'isFavorite': course.isFavorite,
        'deliveryMethods': course.deliveryMethods,
        'startDate': course.startDate,
        'nextAvailableDate': course.nextAvailableDate,
        'outline': course.outline,
        'description': course.description,
        'prerequisites': course.prerequisites,
        'whoShouldAttend': course.whoShouldAttend,
        'importantNotes': course.importantNotes,
        'feeStructure': course.feeStructure,
        'progress': course.progress,
        'completionDate': course.completionDate,
        'moodleCourseId': course.moodleCourseId,
      }).toList();

      await prefs.setString(_cacheKey, json.encode(jsonData));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      print('Cached ${courses.length} courses');
    } catch (e) {
      print('Error caching courses: $e');
    }
  }

  /// Checks if cached content is still valid
  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      return now.difference(cacheTime) < _cacheValidityDuration;
    } catch (e) {
      print('Error checking cache validity: $e');
      return false;
    }
  }

  /// Fallback courses when remote and cache fail
  List<Course> _getFallbackCourses() {
    return [
      Course(
        id: '1',
        courseCode: 'SEC101',
        title: 'Network Security Fundamentals',
        category: 'Cybersecurity',
        certType: 'CEH',
        rating: 4.8,
        duration: '5 days',
        price: '\$3,215.50',
        funding: 'Eligible for funding',
        deliveryMethods: ['OLL', 'ILT'],
        startDate: 'March 15, 2025',
        nextAvailableDate: 'April 20, 2025',
        description: 'This comprehensive course introduces students to the fundamentals of network security.',
      ),
      Course(
        id: '2',
        courseCode: 'CLD201',
        title: 'Cloud Infrastructure Management',
        category: 'Cloud Computing',
        certType: 'CCNA',
        rating: 4.6,
        duration: '10 days',
        price: '\$3,499.50',
        funding: 'Not eligible for funding',
        deliveryMethods: ['OLL', 'ILT'],
        startDate: 'April 5, 2025',
        nextAvailableDate: 'May 15, 2025',
        description: 'Learn to design, implement, and manage cloud infrastructure across major platforms.',
      ),
      Course(
        id: '3',
        courseCode: 'NET301',
        title: 'Advanced Network Management',
        category: 'Networking',
        certType: 'CCNP',
        rating: 4.9,
        duration: '12 days',
        price: '\$3,899.50',
        funding: 'Eligible for funding',
        deliveryMethods: ['ILT'],
        startDate: 'May 10, 2025',
        nextAvailableDate: 'June 25, 2025',
        description: 'An advanced course covering enterprise network management and complex routing protocols.',
      ),
    ];
  }

  /// Clears the cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      print('Course remote config cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Gets cache information for debugging
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);
      final cachedJson = prefs.getString(_cacheKey);

      return {
        'hasCachedData': cachedJson != null,
        'cacheTimestamp': timestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(timestamp).toString()
            : null,
        'isCacheValid': await _isCacheValid(),
        'cacheSize': cachedJson?.length ?? 0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}