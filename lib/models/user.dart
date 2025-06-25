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
        return 'Standard';
      case MembershipTier.tier1:
        return 'Tier 1 Premium';
      case MembershipTier.tier2:
        return 'Tier 2 Professional'; 
      case MembershipTier.tier3:
        return 'Tier 3 Enterprise';
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
    phone: '+XX XXXXXXXXXX', // Generic phone
    company: 'Company Name', // Generic company
    tier: MembershipTier.tier1,
    membershipExpiryDate: 'March 7, 2027',
    favoriteCoursesIds: ['1', '3'],
    enrolledCourses: [
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