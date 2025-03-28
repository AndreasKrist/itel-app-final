// import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_user;

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;

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
        phone: '',
        tier: app_user.MembershipTier.standard,
        membershipExpiryDate: 'Not applicable',
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
        credential.user!.updateDisplayName(name).catchError((e) {
          print('Could not update display name: $e');
        });
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
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Sign out failed: $e');
      rethrow;
    }
  }
}