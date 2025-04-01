// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart' as app_user;

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Check if user is authenticated
  bool get isAuthenticated {
    return _firebaseAuth.currentUser != null;
  }

  // Simplified user conversion to avoid type issues
  app_user.User? _userFromFirebase(firebase_auth.User? firebaseUser) {
    if (firebaseUser == null) {
      return null;
    }
    
    try {
      // Create a minimal user object to avoid type conversion issues
      return app_user.User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        // Use empty strings/defaults for other required fields
        phone: '+62 821xxxxxxxx', // Default phone
        company: 'Lilo Store LTD', // Default company
        tier: app_user.MembershipTier.pro, // Default tier for all signed-up users
        membershipExpiryDate: 'March 7, 2027', // Default expiry
      );
    } catch (e) {
      print('Error converting Firebase user: $e');
      return null;
    }
  }

  // Get current user
  app_user.User? get currentUser {
    try {
      final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
      return _userFromFirebase(firebaseUser);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Sign in with Google
  Future<app_user.User?> signInWithGoogle() async {
    try {
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
      
      // Sign in with credential
      final firebase_auth.UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);
          
      // Return user data
      return _userFromFirebase(userCredential.user);
    } catch (e) {
      print('Error during Google sign in: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<app_user.User?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(credential.user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Register with email and password - simplified
  Future<app_user.User?> registerWithEmailPassword(String email, String password, String name) async {
    try {
      // Create the user first
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name separately (don't wait for it to complete)
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
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
  Future<app_user.User?> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      return _userFromFirebase(credential.user);
    } catch (e) {
      print('Anonymous sign in failed: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      // Sign out from Firebase
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Sign out failed: $e');
      rethrow;
    }
  }
  
  // Update user profile data
  Future<app_user.User?> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? company,
    app_user.MembershipTier? tier,
  }) async {
    try {
      final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return null;
      }
      
      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await firebaseUser.updateDisplayName(displayName);
      }
      
      // For now, we're just returning an updated user object
      // In a real app, you would save the additional data to Firestore
      
      // Get current user from our model
      app_user.User currentUser = _userFromFirebase(firebaseUser) ?? 
                                app_user.User(
                                  id: firebaseUser.uid,
                                  name: firebaseUser.displayName ?? 'User',
                                  email: firebaseUser.email ?? '',
                                );
      
      // Return updated user (in a real app, this would be saved to Firestore)
      return currentUser.copyWith(
        phone: phoneNumber ?? currentUser.phone,
        company: company ?? currentUser.company,
        tier: tier ?? currentUser.tier,
      );
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
}