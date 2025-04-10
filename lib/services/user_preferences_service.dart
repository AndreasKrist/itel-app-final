// lib/services/user_preferences_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/enrolled_course.dart';

class UserPreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create or update user profile
// Replace the saveUserProfile method in user_preferences_service.dart

Future<void> saveUserProfile({
  required String userId,
  required String name,
  required String email,
  String phone = '',
  String? company,
  MembershipTier tier = MembershipTier.standard,
  String membershipExpiryDate = 'Not applicable',
  List<String> favoriteCoursesIds = const [],
  List<EnrolledCourse> enrolledCourses = const [],
}) async {
  try {
    print('Saving user profile for $userId with ${enrolledCourses.length} enrolled courses');
    
    // Convert EnrolledCourse objects to maps for Firestore using simple string status
    final List<Map<String, dynamic>> enrolledCoursesData = enrolledCourses.map((course) {
      // Convert enum to simple string
      String statusString;
      switch (course.status) {
        case EnrollmentStatus.pending:
          statusString = 'pending';
          break;
        case EnrollmentStatus.confirmed:
          statusString = 'confirmed';
          break;
        case EnrollmentStatus.active:
          statusString = 'active';
          break;
        case EnrollmentStatus.completed:
          statusString = 'completed';
          break;
        case EnrollmentStatus.cancelled:
          statusString = 'cancelled';
          break;
        default:
          statusString = 'pending';
      }
      
      return {
        'courseId': course.courseId,
        'enrollmentDate': course.enrollmentDate.toIso8601String(),
        'status': statusString,
        'isOnline': course.isOnline,
        'nextSessionDate': course.nextSessionDate?.toIso8601String(),
        'nextSessionTime': course.nextSessionTime,
        'location': course.location,
        'instructorName': course.instructorName,
        'progress': course.progress,
        'gradeOrCertificate': course.gradeOrCertificate,
      };
    }).toList();
    
    // Update in batches to avoid timeouts on large data
    final batch = _firestore.batch();
    
    // Main user document update
    final userDocRef = _usersCollection.doc(userId);
    batch.set(userDocRef, {
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'tier': tier == MembershipTier.pro ? 'pro' : 'standard',
      'membershipExpiryDate': membershipExpiryDate,
      'favoriteCoursesIds': favoriteCoursesIds,
      'enrolledCourses': enrolledCoursesData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    // Also update each enrollment in the subcollection for redundancy and reliability
    for (var course in enrolledCourses) {
      // Convert enum to simple string
      String statusString;
      switch (course.status) {
        case EnrollmentStatus.pending:
          statusString = 'pending';
          break;
        case EnrollmentStatus.confirmed:
          statusString = 'confirmed';
          break;
        case EnrollmentStatus.active:
          statusString = 'active';
          break;
        case EnrollmentStatus.completed:
          statusString = 'completed';
          break;
        case EnrollmentStatus.cancelled:
          statusString = 'cancelled';
          break;
        default:
          statusString = 'pending';
      }
      
      final courseDocRef = _usersCollection
          .doc(userId)
          .collection('enrolledCourses')
          .doc(course.courseId);
      
      batch.set(courseDocRef, {
        'courseId': course.courseId,
        'enrollmentDate': course.enrollmentDate.toIso8601String(),
        'status': statusString,
        'isOnline': course.isOnline,
        'nextSessionDate': course.nextSessionDate?.toIso8601String(),
        'nextSessionTime': course.nextSessionTime,
        'location': course.location,
        'instructorName': course.instructorName,
        'progress': course.progress,
        'gradeOrCertificate': course.gradeOrCertificate,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    
    // Commit all changes
    await batch.commit();
    
    print('User profile saved successfully with enrolled courses');
  } catch (e) {
    print('Error saving user profile: $e');
    rethrow;
  }
}

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      print('Getting user profile for $userId');
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        print('User profile found');
        return doc.data() as Map<String, dynamic>;
      }
      print('User profile not found');
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Load favorites
  Future<List<String>> loadFavorites(String userId) async {
    try {
      print('Loading favorites for $userId');
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('favoriteCoursesIds')) {
          List<String> favorites = List<String>.from(data['favoriteCoursesIds']);
          print('Loaded favorites: $favorites');
          return favorites;
        }
      }
      print('No favorites found');
      return [];
    } catch (e) {
      print('Error loading favorites: $e');
      return [];
    }
  }

  // Toggle a course favorite status and save to Firestore
  Future<List<String>> toggleFavorite({
    required String userId,
    required String courseId,
    required List<String> currentFavorites,
  }) async {
    try {
      print('Toggling favorite for user $userId, course $courseId');
      print('Current favorites before toggle: $currentFavorites');
      
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      List<String> updatedFavorites = List.from(currentFavorites);

      
      // Toggle the course in favorites
      if (updatedFavorites.contains(courseId)) {
        updatedFavorites.remove(courseId);
        print('Removed course from favorites');
      } else {
        updatedFavorites.add(courseId);
        print('Added course to favorites');
      }
      
        print('Updated favorites: $updatedFavorites');
      
      // Check if document exists first
      DocumentSnapshot docSnapshot = await _usersCollection.doc(userId).get();
      
      // Always use set with merge instead of update
      await _usersCollection.doc(userId).set({
        'favoriteCoursesIds': updatedFavorites,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    
    print('Favorites updated successfully');
      
      return updatedFavorites;
    } catch (e) {
      print('Error toggling favorite: $e');
      // Return the original list on error
      return currentFavorites;
    }
  }
}