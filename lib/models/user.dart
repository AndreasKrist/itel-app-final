// lib/models/user.dart
import 'enrolled_course.dart';

enum MembershipTier {
  standard,
  tier1,    // 15% discount, 1 year free
  tier2,    // 25% discount
  tier3,    // 35% discount
}

extension MembershipTierExtension on MembershipTier {
  String get displayName {
    switch (this) {
      case MembershipTier.standard:
        return 'Associate Member';
      case MembershipTier.tier1:
        return 'Associate Member';
      case MembershipTier.tier2:
        return 'Professional';
      case MembershipTier.tier3:
        return 'Specialist';
    }
  }
  
  double get discountPercentage {
    switch (this) {
      case MembershipTier.standard:
        return 0.0;
      case MembershipTier.tier1:
        return 0.15;  // 15%
      case MembershipTier.tier2:
        return 0.25;  // 25%
      case MembershipTier.tier3:
        return 0.35;  // 35%
    }
  }
  
  String get benefits {
    switch (this) {
      case MembershipTier.standard:
        return 'Access to standard courses, Community forum access, Monthly newsletter';
      case MembershipTier.tier1:
        return '15% discount on all courses, Priority support, Extended access to resources, 1 year free membership';
      case MembershipTier.tier2:
        return '25% discount on all courses, Priority access to new courses, Exclusive webinars and events, Advanced certifications';
      case MembershipTier.tier3:
        return '35% discount on all courses, One-on-one mentoring sessions, Early access to beta features, Custom learning paths, Dedicated account manager';
    }
  }
  
  double get yearlyPrice {
    switch (this) {
      case MembershipTier.standard:
        return 0.0;
      case MembershipTier.tier1:
        return 0.0;  // Free for 1 year
      case MembershipTier.tier2:
        return 299.99;
      case MembershipTier.tier3:
        return 599.99;
    }
  }
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
  final List<EnrolledCourse> enrolledCourses;
  final List<EnrolledCourse> courseHistory;

  // Updated constructor with safer defaults
  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',  // Default to empty string
    this.company,
    this.profileImage,
    this.tier = MembershipTier.standard,  // Default tier
    this.membershipExpiryDate = 'Not applicable',  // Default expiry
    this.favoriteCoursesIds = const [],  // Default to empty list
    this.enrolledCourses = const [],  // Default to empty list
    this.courseHistory = const [],  // Default to empty list
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
    List<EnrolledCourse>? enrolledCourses,
    List<EnrolledCourse>? courseHistory,
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
      courseHistory: courseHistory ?? this.courseHistory,
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

  // Add a method to move course from enrolled to history
  User moveCourseToHistory(String courseId) {
    List<EnrolledCourse> updatedEnrolled = List.from(enrolledCourses);
    List<EnrolledCourse> updatedHistory = List.from(courseHistory);
    
    // Find the course in enrolled list
    final courseIndex = updatedEnrolled.indexWhere((c) => c.courseId == courseId);
    if (courseIndex >= 0) {
      final course = updatedEnrolled.removeAt(courseIndex);
      // Add to history with current timestamp
      updatedHistory.add(course.copyWith(
        status: EnrollmentStatus.cancelled,
      ));
    }
    
    return copyWith(
      enrolledCourses: updatedEnrolled,
      courseHistory: updatedHistory,
    );
  }

  // Add a method to mark course as completed
  User markCourseAsCompleted(String courseId) {
    List<EnrolledCourse> updatedEnrolled = List.from(enrolledCourses);
    List<EnrolledCourse> updatedHistory = List.from(courseHistory);
    
    // Find the course in enrolled list
    final courseIndex = updatedEnrolled.indexWhere((c) => c.courseId == courseId);
    if (courseIndex >= 0) {
      final course = updatedEnrolled.removeAt(courseIndex);
      // Add to history as completed
      updatedHistory.add(course.copyWith(
        status: EnrollmentStatus.completed,
        progress: '100% complete',
      ));
    }
    
    return copyWith(
      enrolledCourses: updatedEnrolled,
      courseHistory: updatedHistory,
    );
  }

  // Default user for anonymous/guest sessions
  static User get guestUser => User(
    id: '',
    name: 'Guest',
    email: '',
    tier: MembershipTier.standard,
    membershipExpiryDate: 'Not applicable',
  );

  // Sample user for logged-in state - will be replaced by Firebase user data
  static User currentUser = User(
    id: '1',
    name: 'User Name', // Generic name
    email: 'user@example.com', // Generic email
    phone: '', // Empty phone - will be filled from user data
    company: '', // Empty company - will be filled from user data
    tier: MembershipTier.standard,
    membershipExpiryDate: 'March 7, 2027',
    favoriteCoursesIds: [], // Start with empty favorites - will be loaded from Firebase
    enrolledCourses: [], // Start with empty enrollments - will be loaded from Firebase
    courseHistory: [], // Start with empty history - will be loaded from Firebase
  );
}