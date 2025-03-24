// File: lib/models/user.dart
// Add these imports
import 'enrolled_course.dart';

enum MembershipTier {
  standard,
  pro,
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? company;
  final String? profileImage;
  final MembershipTier tier;
  final String membershipExpiryDate;
  final List<String> favoriteCoursesIds;
  final List<EnrolledCourse> enrolledCourses; // New field for enrolled courses

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.company,
    this.profileImage,
    required this.tier,
    required this.membershipExpiryDate,
    this.favoriteCoursesIds = const [],
    this.enrolledCourses = const [], // Default to empty list
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? profileImage,
    MembershipTier? tier,
    String? membershipExpiryDate,
    List<String>? favoriteCoursesIds,
    List<EnrolledCourse>? enrolledCourses, // Add to copyWith
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      profileImage: profileImage ?? this.profileImage,
      tier: tier ?? this.tier,
      membershipExpiryDate: membershipExpiryDate ?? this.membershipExpiryDate,
      favoriteCoursesIds: favoriteCoursesIds ?? this.favoriteCoursesIds,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
    );
  }

  // Add a method to enroll in a course
  User enrollInCourse(EnrolledCourse course) {
    List<EnrolledCourse> updatedCourses = List.from(enrolledCourses);
    
    // Check if already enrolled
    final existingIndex = updatedCourses.indexWhere((c) => c.courseId == course.courseId);
    if (existingIndex >= 0) {
      // Update existing enrollment
      updatedCourses[existingIndex] = course;
    } else {
      // Add new enrollment
      updatedCourses.add(course);
    }
    
    return copyWith(enrolledCourses: updatedCourses);
  }

  // Other static variables and methods remain the same
  static bool isGuest = true;
  static bool isAuthenticated = false;

  // Update the sample user with enrolled courses
  static User currentUser = User(
    id: '1',
    name: 'Andreas Kristianto',
    email: 'andreaskrist2004@gmail.com',
    phone: '+62 82111508130',
    company: 'Lilo Store LTD',
    tier: MembershipTier.pro,
    membershipExpiryDate: 'March 7, 2027',
    favoriteCoursesIds: ['1', '3'],
    enrolledCourses: [
      // We removed the Network Security Fundamentals example
      // Leave this list initially empty or with other courses you want to appear by default
      EnrolledCourse(
        courseId: '7',
        enrollmentDate: DateTime.now().subtract(const Duration(days: 7)),
        status: EnrollmentStatus.pending,
        isOnline: false,
        nextSessionDate: DateTime.now().add(const Duration(days: 5)),
        nextSessionTime: '2:00 PM - 5:00 PM',
        location: 'Room 302, ITEL Training Center',
        progress: null, // Not started yet
      ),
    ],
  );
}