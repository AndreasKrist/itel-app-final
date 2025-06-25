// lib/services/user_preferences_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/enrolled_course.dart';

class UserPreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create or update user profile
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
        'tier': _tierToString(tier),
        'membershipExpiryDate': membershipExpiryDate,
        'favoriteCoursesIds': favoriteCoursesIds,
        'enrolledCourses': enrolledCoursesData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Commit the batch
      await batch.commit();
      
      print('Successfully saved user profile for $userId');
    } catch (e) {
      print('Error saving user profile: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      print('Getting user profile for $userId');
      
      final doc = await _usersCollection.doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('User profile found for $userId');
        return data;
      } else {
        print('No user profile found for $userId');
        return null;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Load user favorites
  Future<List<String>> loadFavorites(String userId) async {
    try {
      print('Loading favorites for user: $userId');
      
      final doc = await _usersCollection.doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('favoriteCoursesIds')) {
          final favorites = List<String>.from(data['favoriteCoursesIds'] ?? []);
          print('Loaded ${favorites.length} favorites for user $userId');
          return favorites;
        }
      }
      
      print('No favorites found for user $userId');
      return [];
    } catch (e) {
      print('Error loading favorites: $e');
      return [];
    }
  }

  // Save user favorites
  Future<void> saveFavorites(String userId, List<String> favoriteIds) async {
    try {
      print('Saving ${favoriteIds.length} favorites for user $userId');
      
      await _usersCollection.doc(userId).update({
        'favoriteCoursesIds': favoriteIds,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('Successfully saved favorites for user $userId');
    } catch (e) {
      print('Error saving favorites: $e');
      rethrow;
    }
  }

  // Add favorite course
  Future<void> addFavorite(String userId, String courseId) async {
    try {
      final favorites = await loadFavorites(userId);
      if (!favorites.contains(courseId)) {
        favorites.add(courseId);
        await saveFavorites(userId, favorites);
      }
    } catch (e) {
      print('Error adding favorite: $e');
      rethrow;
    }
  }

  // Remove favorite course
  Future<void> removeFavorite(String userId, String courseId) async {
    try {
      final favorites = await loadFavorites(userId);
      if (favorites.contains(courseId)) {
        favorites.remove(courseId);
        await saveFavorites(userId, favorites);
      }
    } catch (e) {
      print('Error removing favorite: $e');
      rethrow;
    }
  }

  // Load enrolled courses
  Future<List<EnrolledCourse>> loadEnrolledCourses(String userId) async {
    try {
      print('Loading enrolled courses for user: $userId');
      
      final doc = await _usersCollection.doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('enrolledCourses')) {
          final enrolledCoursesData = List<Map<String, dynamic>>.from(data['enrolledCourses'] ?? []);
          final enrolledCourses = enrolledCoursesData.map((courseData) {
            return EnrolledCourse(
              courseId: courseData['courseId'] ?? '',
              enrollmentDate: courseData['enrollmentDate'] != null 
                ? DateTime.parse(courseData['enrollmentDate']) 
                : DateTime.now(),
              status: _getEnrollmentStatusFromString(courseData['status'] ?? 'pending'),
              isOnline: courseData['isOnline'] ?? false,
              nextSessionDate: courseData['nextSessionDate'] != null 
                ? DateTime.parse(courseData['nextSessionDate']) 
                : null,
              nextSessionTime: courseData['nextSessionTime'],
              location: courseData['location'],
              instructorName: courseData['instructorName'],
              progress: courseData['progress'],
              gradeOrCertificate: courseData['gradeOrCertificate'],
            );
          }).toList();
          
          print('Loaded ${enrolledCourses.length} enrolled courses for user $userId');
          return enrolledCourses;
        }
      }
      
      print('No enrolled courses found for user $userId');
      return [];
    } catch (e) {
      print('Error loading enrolled courses: $e');
      return [];
    }
  }

  // Save enrolled courses
  Future<void> saveEnrolledCourses(String userId, List<EnrolledCourse> enrolledCourses) async {
    try {
      print('Saving ${enrolledCourses.length} enrolled courses for user $userId');
      
      // Convert to maps
      final enrolledCoursesData = enrolledCourses.map((course) {
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
      
      await _usersCollection.doc(userId).update({
        'enrolledCourses': enrolledCoursesData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('Successfully saved enrolled courses for user $userId');
    } catch (e) {
      print('Error saving enrolled courses: $e');
      rethrow;
    }
  }

  // Add enrolled course
  Future<void> addEnrolledCourse(String userId, EnrolledCourse course) async {
    try {
      final enrolledCourses = await loadEnrolledCourses(userId);
      
      // Check if already enrolled
      final existingIndex = enrolledCourses.indexWhere((c) => c.courseId == course.courseId);
      if (existingIndex >= 0) {
        // Update existing enrollment
        enrolledCourses[existingIndex] = course;
      } else {
        // Add new enrollment
        enrolledCourses.add(course);
      }
      
      await saveEnrolledCourses(userId, enrolledCourses);
    } catch (e) {
      print('Error adding enrolled course: $e');
      rethrow;
    }
  }

  // Update user membership tier
  Future<void> updateMembershipTier({
    required String userId,
    required MembershipTier tier,
    required String membershipExpiryDate,
  }) async {
    try {
      print('Updating membership tier for user $userId to ${_tierToString(tier)}');
      
      await _usersCollection.doc(userId).update({
        'tier': _tierToString(tier),
        'membershipExpiryDate': membershipExpiryDate,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('Successfully updated membership tier for user $userId');
    } catch (e) {
      print('Error updating membership tier: $e');
      rethrow;
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    try {
      print('Deleting user profile for $userId');
      
      await _usersCollection.doc(userId).delete();
      
      print('Successfully deleted user profile for $userId');
    } catch (e) {
      print('Error deleting user profile: $e');
      rethrow;
    }
  }

  // Helper method to convert string to EnrollmentStatus
  EnrollmentStatus _getEnrollmentStatusFromString(String statusString) {
    switch (statusString) {
      case 'active':
        return EnrollmentStatus.active;
      case 'confirmed':
        return EnrollmentStatus.confirmed;
      case 'completed':
        return EnrollmentStatus.completed;
      case 'cancelled':
        return EnrollmentStatus.cancelled;
      case 'pending':
      default:
        return EnrollmentStatus.pending;
    }
  }

  // Helper method to convert MembershipTier to string for Firebase
  String _tierToString(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.standard:
        return 'standard';
      case MembershipTier.tier1:
        return 'tier1';
      case MembershipTier.tier2:
        return 'tier2';
      case MembershipTier.tier3:
        return 'tier3';
    }
  }
}