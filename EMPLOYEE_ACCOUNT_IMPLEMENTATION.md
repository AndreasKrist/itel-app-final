# Employee Account System Implementation Guide

This guide contains all the code changes needed to implement the employee account system that links employees to corporate accounts via a `companyId` field.

---

## Overview of Changes

1. Add `companyId` field to User model
2. Update auth_service.dart to load/save companyId
3. Update user_preferences_service.dart to handle companyId
4. Update profile_screen.dart to preserve companyId and show dashboard for corporate accounts

---

## FILE 1: lib/models/user.dart

### CHANGE 1.1 - Add companyId field to class properties (around line 67-84)

**Find this code:**
```dart
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? company;
  final String? jobTitle;  // Job title for corporate accounts
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
```

**Replace with:**
```dart
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? company;
  final String? jobTitle;  // Job title for corporate accounts
  final String? companyAddress;  // Company address for corporate accounts
  final String accountType;  // 'private', 'corporate', or 'employee'
  final String? companyId;  // Company ID to link employees to corporate accounts
  final String? profileImage;
  final MembershipTier tier;
  final String membershipExpiryDate;
  final List<String> favoriteCoursesIds;
  final List<EnrolledCourse> enrolledCourses;
  final List<EnrolledCourse> courseHistory;
  final int giveAccess;  // 0 = locked, 1 = can access complimentary courses
  final double trainingCredits;  // Available training credits for corporate accounts
  final List<Map<String, dynamic>> trainingCreditHistory;  // History of credit usage
```

---

### CHANGE 1.2 - Update constructor (around line 87-106)

**Find this code:**
```dart
  // Updated constructor with safer defaults
  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',  // Default to empty string
    this.company,
    this.jobTitle,
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
```

**Replace with:**
```dart
  // Updated constructor with safer defaults
  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',  // Default to empty string
    this.company,
    this.jobTitle,
    this.companyAddress,
    this.accountType = 'private',  // Default to private account
    this.companyId,  // Company ID for linking employees to corporate accounts
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
```

---

### CHANGE 1.3 - Update copyWith method (around line 108-148)

**Find this code:**
```dart
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? jobTitle,
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
      jobTitle: jobTitle ?? this.jobTitle,
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
```

**Replace with:**
```dart
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? jobTitle,
    String? companyAddress,
    String? accountType,
    String? companyId,
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
      jobTitle: jobTitle ?? this.jobTitle,
      companyAddress: companyAddress ?? this.companyAddress,
      accountType: accountType ?? this.accountType,
      companyId: companyId ?? this.companyId,
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
```

---

## FILE 2: lib/services/auth_service.dart

### CHANGE 2.1 - Update loadUserData to load companyId (around line 171-208)

**Find this code:**
```dart
    // Load corporate fields
    final String accountType = userProfile?['accountType'] ?? 'private';
    final String? jobTitle = userProfile?['jobTitle'];
    final String? companyAddress = userProfile?['companyAddress'];
    final double trainingCredits = (userProfile?['trainingCredits'] ?? 0.0).toDouble();
    final List<Map<String, dynamic>> trainingCreditHistory = userProfile?['trainingCreditHistory'] != null
        ? List<Map<String, dynamic>>.from(userProfile!['trainingCreditHistory'])
        : [];

    print('Loaded account type: $accountType');
    if (accountType == 'corporate') {
      print('Corporate account - Credits: \$${trainingCredits.toStringAsFixed(2)}, History items: ${trainingCreditHistory.length}');
    }

    // Update the currentUser with the loaded data
    User.currentUser = User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? userProfile?['name'] ?? 'User',
      email: firebaseUser.email ?? userProfile?['email'] ?? '',
      phone: userProfile?['phone'] ?? '',
      company: userProfile?['company'] ?? '',
      jobTitle: jobTitle,
      companyAddress: companyAddress,
      accountType: accountType,
      tier: _getTierFromString(userProfile?['tier']),
      membershipExpiryDate: userProfile?['membershipExpiryDate'] ?? 'March 7, 2027',
      favoriteCoursesIds: favorites, // Use the loaded favorites
      enrolledCourses: enrolledCourses, // Use the loaded enrolled courses
      courseHistory: courseHistory, // Use the loaded course history
      giveAccess: giveAccess, // Use the loaded giveAccess value
      trainingCredits: trainingCredits,
      trainingCreditHistory: trainingCreditHistory,
    );
```

**Replace with:**
```dart
    // Load corporate fields
    final String accountType = userProfile?['accountType'] ?? 'private';
    final String? jobTitle = userProfile?['jobTitle'];
    final String? companyAddress = userProfile?['companyAddress'];
    final String? companyId = userProfile?['companyId'];
    final double trainingCredits = (userProfile?['trainingCredits'] ?? 0.0).toDouble();
    final List<Map<String, dynamic>> trainingCreditHistory = userProfile?['trainingCreditHistory'] != null
        ? List<Map<String, dynamic>>.from(userProfile!['trainingCreditHistory'])
        : [];

    print('Loaded account type: $accountType');
    if (accountType == 'corporate') {
      print('Corporate account - Credits: \$${trainingCredits.toStringAsFixed(2)}, History items: ${trainingCreditHistory.length}');
    }
    if (accountType == 'employee' && companyId != null) {
      print('Employee account - Company ID: $companyId');
    }

    // Update the currentUser with the loaded data
    User.currentUser = User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? userProfile?['name'] ?? 'User',
      email: firebaseUser.email ?? userProfile?['email'] ?? '',
      phone: userProfile?['phone'] ?? '',
      company: userProfile?['company'] ?? '',
      jobTitle: jobTitle,
      companyAddress: companyAddress,
      accountType: accountType,
      companyId: companyId,
      tier: _getTierFromString(userProfile?['tier']),
      membershipExpiryDate: userProfile?['membershipExpiryDate'] ?? 'March 7, 2027',
      favoriteCoursesIds: favorites, // Use the loaded favorites
      enrolledCourses: enrolledCourses, // Use the loaded enrolled courses
      courseHistory: courseHistory, // Use the loaded course history
      giveAccess: giveAccess, // Use the loaded giveAccess value
      trainingCredits: trainingCredits,
      trainingCreditHistory: trainingCreditHistory,
    );
```

---

## FILE 3: lib/services/user_preferences_service.dart

### CHANGE 3.1 - Update saveUserProfile method signature (around line 52-70)

**Find this code:**
```dart
  // Create or update user profile
  Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String email,
    String phone = '',
    String? company,
    String? jobTitle,
    String? companyAddress,
    String accountType = 'private',
    MembershipTier tier = MembershipTier.standard,
    String membershipExpiryDate = 'Not applicable',
    List<String> favoriteCoursesIds = const [],
    List<EnrolledCourse> enrolledCourses = const [],
    List<EnrolledCourse> courseHistory = const [],
    int giveAccess = 0,
    double trainingCredits = 0.0,
    List<Map<String, dynamic>> trainingCreditHistory = const [],
  }) async {
```

**Replace with:**
```dart
  // Create or update user profile
  Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String email,
    String phone = '',
    String? company,
    String? jobTitle,
    String? companyAddress,
    String accountType = 'private',
    String? companyId,
    MembershipTier tier = MembershipTier.standard,
    String membershipExpiryDate = 'Not applicable',
    List<String> favoriteCoursesIds = const [],
    List<EnrolledCourse> enrolledCourses = const [],
    List<EnrolledCourse> courseHistory = const [],
    int giveAccess = 0,
    double trainingCredits = 0.0,
    List<Map<String, dynamic>> trainingCreditHistory = const [],
  }) async {
```

---

### CHANGE 3.2 - Update Firestore batch.set to include companyId (around line 152-172)

**Find this code:**
```dart
      // Main user document update
      final userDocRef = _usersCollection.doc(userId);
      batch.set(userDocRef, {
        'name': name,
        'email': email,
        'phone': phone,
        'company': company,
        'jobTitle': jobTitle,
        'companyAddress': companyAddress,
        'accountType': accountType,
        'tier': _tierToString(tier),
        'membershipExpiryDate': membershipExpiryDate,
        'favoriteCoursesIds': favoriteCoursesIds,
        'enrolledCourses': enrolledCoursesData,
        'courseHistory': courseHistoryData,
        'giveAccess': giveAccess,
        'trainingCredits': trainingCredits,
        'trainingCreditHistory': trainingCreditHistory,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
```

**Replace with:**
```dart
      // Main user document update
      final userDocRef = _usersCollection.doc(userId);
      batch.set(userDocRef, {
        'name': name,
        'email': email,
        'phone': phone,
        'company': company,
        'jobTitle': jobTitle,
        'companyAddress': companyAddress,
        'accountType': accountType,
        'companyId': companyId,
        'tier': _tierToString(tier),
        'membershipExpiryDate': membershipExpiryDate,
        'favoriteCoursesIds': favoriteCoursesIds,
        'enrolledCourses': enrolledCoursesData,
        'courseHistory': courseHistoryData,
        'giveAccess': giveAccess,
        'trainingCredits': trainingCredits,
        'trainingCreditHistory': trainingCreditHistory,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
```

---

## FILE 4: lib/screens/profile_screen.dart

### CHANGE 4.1 - Update _updateProfile method (around line 88-106)

**Find this code:**
```dart
    // First update in Firestore to ensure data is saved with ALL user data
    await _preferencesService.saveUserProfile(
      userId: firebaseUser.uid,
      name: name,
      email: User.currentUser.email,
      phone: phone,
      company: company,
      companyAddress: User.currentUser.companyAddress,
      accountType: User.currentUser.accountType,
      tier: User.currentUser.tier,
      membershipExpiryDate: User.currentUser.membershipExpiryDate,
      favoriteCoursesIds: User.currentUser.favoriteCoursesIds,
      enrolledCourses: User.currentUser.enrolledCourses,
      courseHistory: User.currentUser.courseHistory,
      giveAccess: User.currentUser.giveAccess,
      trainingCredits: User.currentUser.trainingCredits,
      trainingCreditHistory: User.currentUser.trainingCreditHistory,
    );
```

**Replace with:**
```dart
    // First update in Firestore to ensure data is saved with ALL user data
    await _preferencesService.saveUserProfile(
      userId: firebaseUser.uid,
      name: name,
      email: User.currentUser.email,
      phone: phone,
      company: company,
      companyAddress: User.currentUser.companyAddress,
      accountType: User.currentUser.accountType,
      companyId: User.currentUser.companyId,
      tier: User.currentUser.tier,
      membershipExpiryDate: User.currentUser.membershipExpiryDate,
      favoriteCoursesIds: User.currentUser.favoriteCoursesIds,
      enrolledCourses: User.currentUser.enrolledCourses,
      courseHistory: User.currentUser.courseHistory,
      giveAccess: User.currentUser.giveAccess,
      trainingCredits: User.currentUser.trainingCredits,
      trainingCreditHistory: User.currentUser.trainingCreditHistory,
    );
```

---

### CHANGE 4.2 - Update favorites sync method (around line 591-609)

**Find this code:**
```dart
    // Update in Firestore directly with saveUserProfile to ensure persistence
    await _preferencesService.saveUserProfile(
      userId: currentUser.id,
      name: User.currentUser.name,
      email: User.currentUser.email,
      phone: User.currentUser.phone,
      company: User.currentUser.company,
      companyAddress: User.currentUser.companyAddress,
      accountType: User.currentUser.accountType,
      tier: User.currentUser.tier,
      membershipExpiryDate: User.currentUser.membershipExpiryDate,
      favoriteCoursesIds: updatedFavorites,
      enrolledCourses: User.currentUser.enrolledCourses,
      courseHistory: User.currentUser.courseHistory,
      giveAccess: User.currentUser.giveAccess,
      trainingCredits: User.currentUser.trainingCredits,
      trainingCreditHistory: User.currentUser.trainingCreditHistory,
```

**Replace with:**
```dart
    // Update in Firestore directly with saveUserProfile to ensure persistence
    await _preferencesService.saveUserProfile(
      userId: currentUser.id,
      name: User.currentUser.name,
      email: User.currentUser.email,
      phone: User.currentUser.phone,
      company: User.currentUser.company,
      companyAddress: User.currentUser.companyAddress,
      accountType: User.currentUser.accountType,
      companyId: User.currentUser.companyId,
      tier: User.currentUser.tier,
      membershipExpiryDate: User.currentUser.membershipExpiryDate,
      favoriteCoursesIds: updatedFavorites,
      enrolledCourses: User.currentUser.enrolledCourses,
      courseHistory: User.currentUser.courseHistory,
      giveAccess: User.currentUser.giveAccess,
      trainingCredits: User.currentUser.trainingCredits,
      trainingCreditHistory: User.currentUser.trainingCreditHistory,
```

---

### CHANGE 4.3 - Update tier upgrade method (around line 726-744)

**Find this code:**
```dart
        // Update main user document
        await _preferencesService.saveUserProfile(
          userId: currentUser.id,
          name: currentUser.name,
          email: currentUser.email,
          phone: currentUser.phone,
          company: currentUser.company,
          companyAddress: User.currentUser.companyAddress,
          accountType: User.currentUser.accountType,
          tier: currentUser.tier,
          membershipExpiryDate: currentUser.membershipExpiryDate,
          favoriteCoursesIds: User.currentUser.favoriteCoursesIds,
          enrolledCourses: User.currentUser.enrolledCourses,
          courseHistory: User.currentUser.courseHistory,
          giveAccess: User.currentUser.giveAccess,
          trainingCredits: User.currentUser.trainingCredits,
          trainingCreditHistory: User.currentUser.trainingCreditHistory,
```

**Replace with:**
```dart
        // Update main user document
        await _preferencesService.saveUserProfile(
          userId: currentUser.id,
          name: currentUser.name,
          email: currentUser.email,
          phone: currentUser.phone,
          company: currentUser.company,
          companyAddress: User.currentUser.companyAddress,
          accountType: User.currentUser.accountType,
          companyId: User.currentUser.companyId,
          tier: currentUser.tier,
          membershipExpiryDate: currentUser.membershipExpiryDate,
          favoriteCoursesIds: User.currentUser.favoriteCoursesIds,
          enrolledCourses: User.currentUser.enrolledCourses,
          courseHistory: User.currentUser.courseHistory,
          giveAccess: User.currentUser.giveAccess,
          trainingCredits: User.currentUser.trainingCredits,
          trainingCreditHistory: User.currentUser.trainingCreditHistory,
```

---

### CHANGE 4.4 - Remove dashboard restriction for corporate accounts (around line 1376-1379)

**Find this code:**
```dart
      const SizedBox(height: 24),

      // Dashboard Section (Hidden for corporate accounts)
      if (currentUser.accountType != 'corporate') ...[
      // Dashboard Section
      Container(
```

**Replace with:**
```dart
      const SizedBox(height: 24),

      // Dashboard Section (Available for all account types)
      // Dashboard Section
      Container(
```

---

### CHANGE 4.5 - Remove closing bracket for dashboard restriction (around line 1700-1702)

**Find this code:**
```dart
        ),
      ),
      ], // End of dashboard section (hidden for corporate accounts)

      // const SizedBox(height: 24),
```

**Replace with:**
```dart
        ),
      ),

      // const SizedBox(height: 24),
```

---

## Summary

After implementing all changes above:

1. ✅ User model now has `companyId` field for linking employees to companies
2. ✅ Auth service loads and logs `companyId` for employee accounts
3. ✅ User preferences service saves `companyId` to Firestore
4. ✅ Profile screen preserves `companyId` during all updates
5. ✅ Corporate accounts can now see Dashboard and enquire for courses (same as private/employee)

---

## Testing Checklist

After implementation, you should be able to:

- [ ] Create corporate account with company name
- [ ] Manually add `companyId` in Firebase Console for corporate account (Field: `companyId`, Type: `string`, Value: e.g., `"lilostore_001"`)
- [ ] Create employee account (as private)
- [ ] Manually change `accountType` to `"employee"` and add same `companyId` in Firebase
- [ ] Both accounts linked via `companyId`
- [ ] Corporate accounts can now see Dashboard and make enquiries
- [ ] Employee accounts show their company name in profile
- [ ] Profile updates preserve `companyId` for all account types

---

## Firebase Manual Setup Example

### For Corporate Account (HR/Manager):
1. User signs up as "Associate Corporate"
2. In Firebase Console → Firestore → `users` → Find the user
3. Add field: `companyId` = `"lilostore_001"` (type: string)

### For Employee Account:
1. User signs up as "Private"
2. In Firebase Console → Firestore → `users` → Find the user
3. Edit document:
   - Change `accountType` from `"private"` to `"employee"`
   - Add field: `company` = `"LiloStore"` (type: string)
   - Add field: `companyId` = `"lilostore_001"` (type: string - same as HR!)

### Query All Company Employees:
```
In Firebase Console:
Filter: companyId == lilostore_001

Result: Shows both HR and all employees with that companyId
```

---

**Implementation Date:** 2025-12-23
**Flutter Version:** Compatible with current project structure
