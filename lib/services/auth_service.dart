// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import 'user_preferences_service.dart';
import '../models/enrolled_course.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserPreferencesService _preferencesService = UserPreferencesService();

  // Check if user is authenticated
  bool get isAuthenticated {
    return _firebaseAuth.currentUser != null;
  }

  // Simplified user conversion to avoid type issues
  User? _userFromFirebase(firebase_auth.User? firebaseUser) {
    if (firebaseUser == null) {
      return null;
    }
    
    try {
      // Create a minimal user object to avoid type conversion issues
      return User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        // Use empty strings for other fields - user can fill them later
        phone: '', // Empty by default - user can add their real phone
        company: '', // Empty by default - user can add their company
        tier: MembershipTier.standard, // Default tier for all signed-up users
        membershipExpiryDate: 'March 7, 2027', // Default expiry
      );
    } catch (e) {
      print('Error converting Firebase user: $e');
      return null;
    }
  }

  // Get current user
  User? get currentUser {
    try {
      final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
      return _userFromFirebase(firebaseUser);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Load user data including favorites
Future<void> loadUserData() async {
  final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
  if (firebaseUser == null) return;

  try {
    print('Loading user data for ${firebaseUser.uid}');

    // Get user profile data first
    final userProfile = await _preferencesService.getUserProfile(firebaseUser.uid);
    print('User profile loaded: ${userProfile != null}');

    // Always use the dedicated loadFavorites method which handles both Firestore and local storage
    final favorites = await _preferencesService.loadFavorites(firebaseUser.uid);
    print('Favorites loaded: $favorites');

    // Load enrolled courses data from profile
    List<EnrolledCourse> enrolledCourses = [];
    List<EnrolledCourse> courseHistory = [];

    if (userProfile != null && userProfile.containsKey('enrolledCourses')) {
      try {
        final enrolledCoursesData = List<Map<String, dynamic>>.from(userProfile['enrolledCourses'] ?? []);
        enrolledCourses = enrolledCoursesData.map((data) => EnrolledCourse(
          courseId: data['courseId'] ?? '',
          enrollmentDate: data['enrollmentDate'] != null
            ? DateTime.parse(data['enrollmentDate'])
            : DateTime.now(),
          status: _getEnrollmentStatusFromString(data['status'] ?? 'pending'),
          isOnline: data['isOnline'] ?? false,
          nextSessionDate: data['nextSessionDate'] != null
            ? DateTime.parse(data['nextSessionDate'])
            : null,
          nextSessionTime: data['nextSessionTime'],
          location: data['location'],
          instructorName: data['instructorName'],
          progress: data['progress'],
          gradeOrCertificate: data['gradeOrCertificate'],
        )).toList();
        print('Loaded ${enrolledCourses.length} enrolled courses');
      } catch (e) {
        print('Error parsing enrolled courses: $e');
      }
    }

    // Load course history data
    if (userProfile != null && userProfile.containsKey('courseHistory')) {
      try {
        final courseHistoryData = List<Map<String, dynamic>>.from(userProfile['courseHistory'] ?? []);
        courseHistory = courseHistoryData.map((data) => EnrolledCourse(
          courseId: data['courseId'] ?? '',
          enrollmentDate: data['enrollmentDate'] != null
            ? DateTime.parse(data['enrollmentDate'])
            : DateTime.now(),
          status: _getEnrollmentStatusFromString(data['status'] ?? 'cancelled'),
          isOnline: data['isOnline'] ?? false,
          nextSessionDate: data['nextSessionDate'] != null
            ? DateTime.parse(data['nextSessionDate'])
            : null,
          nextSessionTime: data['nextSessionTime'],
          location: data['location'],
          instructorName: data['instructorName'],
          progress: data['progress'],
          gradeOrCertificate: data['gradeOrCertificate'],
        )).toList();
        print('Loaded ${courseHistory.length} course history items');
      } catch (e) {
        print('Error parsing course history: $e');
      }
    }

    // If profile doesn't exist, create it
    if (userProfile == null) {
      print('User profile not found, creating one');
      await _preferencesService.saveUserProfile(
        userId: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        phone: '', // Empty phone instead of hardcoded number
        company: '', // Empty company instead of hardcoded company
        tier: MembershipTier.standard,
        membershipExpiryDate: 'March 7, 2027',
        favoriteCoursesIds: [], // Pass the loaded favorites
        enrolledCourses: [], // Empty enrolled courses for new users
        courseHistory: [], // Empty course history for new users
      );
    }

    // Update the currentUser with the loaded data
    User.currentUser = User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? userProfile?['name'] ?? 'User',
      email: firebaseUser.email ?? userProfile?['email'] ?? '',
      phone: userProfile?['phone'] ?? '',
      company: userProfile?['company'] ?? '',
      tier: _getTierFromString(userProfile?['tier']),
      membershipExpiryDate: userProfile?['membershipExpiryDate'] ?? 'March 7, 2027',
      favoriteCoursesIds: favorites, // Use the loaded favorites
      enrolledCourses: enrolledCourses, // Use the loaded enrolled courses
      courseHistory: courseHistory, // Use the loaded course history
    );

    print('User data loaded successfully. Favorites: ${User.currentUser.favoriteCoursesIds.length} items');
    print('Favorite IDs: ${User.currentUser.favoriteCoursesIds}');
    print('Enrolled courses: ${User.currentUser.enrolledCourses.length} items');
    print('Course history: ${User.currentUser.courseHistory.length} items');
  } catch (e) {
    print('Error loading user data: $e');
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

  // Helper method to convert string to MembershipTier
MembershipTier _getTierFromString(String? tierString) {
  switch (tierString) {
    case 'tier1':
      return MembershipTier.tier1;
    case 'tier2':
      return MembershipTier.tier2;
    case 'tier3':
      return MembershipTier.tier3;
    case 'standard':
    default:
      return MembershipTier.standard;
  }
}

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Check if user is currently signed in anonymously
      final currentUser = _firebaseAuth.currentUser;
      final isAnonymous = currentUser?.isAnonymous ?? false;
      
      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // Abort if sign in is aborted by user
      if (googleUser == null) {
        return null;
      }
      
      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create new credential for Firebase
      final firebase_auth.OAuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      firebase_auth.UserCredential userCredential;
      
      // Handle anonymous user linking or direct sign-in
      if (isAnonymous && currentUser != null) {
        try {
          // Try to link the anonymous account with Google credentials
          userCredential = await currentUser.linkWithCredential(credential);
          print('Successfully linked anonymous account with Google');
        } catch (e) {
          print('Failed to link anonymous account: $e');
          // If linking fails, sign out anonymous user and sign in with Google
          await _firebaseAuth.signOut();
          userCredential = await _firebaseAuth.signInWithCredential(credential);
          print('Signed out anonymous user and signed in with Google');
        }
      } else {
        // Direct sign-in with Google (no anonymous user)
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }
          
      if (userCredential.user != null) {
        // Check if user profile exists
        final userProfile = await _preferencesService.getUserProfile(userCredential.user!.uid);
        
        // If not, create one
        if (userProfile == null) {
          await _preferencesService.saveUserProfile(
            userId: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? 'User',
            email: userCredential.user!.email ?? '',
            phone: '', // Empty phone instead of hardcoded number
            company: '', // Empty company instead of hardcoded company
            tier: MembershipTier.standard,
            membershipExpiryDate: 'March 7, 2027',
            favoriteCoursesIds: [],
          );
        }
        
        // Load user data including favorites
        await loadUserData();
      }
      
      // Return user data
      return _userFromFirebase(userCredential.user);
    } catch (e) {
      print('Error during Google sign in: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Load user data including favorites
        await loadUserData();
      }
      
      return _userFromFirebase(credential.user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailPassword(String email, String password, String name) async {
    try {
      // Create the user first
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name separately (don't wait for it to complete)
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        
        // Create Firestore profile
        await _preferencesService.saveUserProfile(
          userId: credential.user!.uid,
          name: name,
          email: email,
          phone: '', // Empty phone instead of hardcoded number
          company: '', // Empty company instead of hardcoded company
          tier: MembershipTier.standard,
          membershipExpiryDate: 'March 7, 2027',
          favoriteCoursesIds: [],
        );
        
        // Load user data including favorites
        await loadUserData();
      }
      
      // Return user without relying on the updateProfile or reload operations
      return _userFromFirebase(credential.user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  // Sign in as guest
  Future<User?> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      
      if (credential.user != null) {
        // Create a basic profile for anonymous users
        await _preferencesService.saveUserProfile(
          userId: credential.user!.uid,
          name: 'Guest',
          email: '',
          favoriteCoursesIds: [],
        );
        
        // Load user data (though it's minimal for anonymous users)
        await loadUserData();
      }
      
      return _userFromFirebase(credential.user);
    } catch (e) {
      print('Anonymous sign in failed: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear local storage for the current user before signing out
      final currentUserId = _firebaseAuth.currentUser?.uid;
      if (currentUserId != null) {
        await _preferencesService.clearLocalStorage(currentUserId);
      }
      
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Sign out failed: $e');
      rethrow;
    }
  }
}