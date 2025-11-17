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
  final String? companyAddress;  // Company address for corporate accounts
  final String accountType;  // 'private' or 'corporate'
  final String? profileImage;
  final MembershipTier tier;
  final String membershipExpiryDate;
  final List<String> favoriteCoursesIds;
  final List<EnrolledCourse> enrolledCourses;
  final List<EnrolledCourse> courseHistory;
  final int giveAccess;  // 0 = locked, 1 = can access complimentary courses
  final double trainingCredits;  // Available training credits for corporate accounts
  final List<Map<String, dynamic>> trainingCreditHistory;  // History of credit usage

  // Updated constructor with safer defaults
  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',  // Default to empty string
    this.company,
    this.companyAddress,
    this.accountType = 'private',  // Default to private account
    this.profileImage,
    this.tier = MembershipTier.standard,  // Default tier
    this.membershipExpiryDate = 'Not applicable',  // Default expiry
    this.favoriteCoursesIds = const [],  // Default to empty list
    this.enrolledCourses = const [],  // Default to empty list
    this.courseHistory = const [],  // Default to empty list
    this.giveAccess = 0,  // Default to locked (0)
    this.trainingCredits = 0.0,  // Default to 0 credits
    this.trainingCreditHistory = const [],  // Default to empty history
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? companyAddress,
    String? accountType,
    String? profileImage,
    MembershipTier? tier,
    String? membershipExpiryDate,
    List<String>? favoriteCoursesIds,
    List<EnrolledCourse>? enrolledCourses,
    List<EnrolledCourse>? courseHistory,
    int? giveAccess,
    double? trainingCredits,
    List<Map<String, dynamic>>? trainingCreditHistory,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      companyAddress: companyAddress ?? this.companyAddress,
      accountType: accountType ?? this.accountType,
      profileImage: profileImage ?? this.profileImage,
      tier: tier ?? this.tier,
      membershipExpiryDate: membershipExpiryDate ?? this.membershipExpiryDate,
      favoriteCoursesIds: favoriteCoursesIds ?? this.favoriteCoursesIds,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      courseHistory: courseHistory ?? this.courseHistory,
      giveAccess: giveAccess ?? this.giveAccess,
      trainingCredits: trainingCredits ?? this.trainingCredits,
      trainingCreditHistory: trainingCreditHistory ?? this.trainingCreditHistory,
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
    giveAccess: 0,  // Guests are locked by default
    accountType: 'private',
  );

  // Sample user for logged-in state - will be replaced by Firebase user data
  static User currentUser = User(
    id: '1',
    name: 'User Name', // Generic name
    email: 'user@example.com', // Generic email
    phone: '', // Empty phone - will be filled from user data
    company: '', // Empty company - will be filled from user data
    companyAddress: '', // Empty company address - will be filled from user data
    accountType: 'private', // Default to private account
    tier: MembershipTier.standard,
    membershipExpiryDate: 'March 7, 2027',
    favoriteCoursesIds: [], // Start with empty favorites - will be loaded from Firebase
    enrolledCourses: [], // Start with empty enrollments - will be loaded from Firebase
    courseHistory: [], // Start with empty history - will be loaded from Firebase
    giveAccess: 0,  // Default to locked (0)
    trainingCredits: 0.0,  // Default to 0 credits
    trainingCreditHistory: [], // Start with empty history
  );
}