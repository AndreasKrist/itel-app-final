// lib/models/saved_account.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Represents a saved account that a user has previously logged into
/// This model stores minimal information to display in account switcher
class SavedAccount {
  final String uid;           // Firebase UID
  final String email;         // User email
  final String displayName;   // User display name
  final String? photoUrl;     // Profile photo URL (from Google)
  final String accountType;   // 'private' or 'corporate'
  final String authMethod;    // 'google' or 'email'
  final DateTime lastUsed;    // When this account was last active

  SavedAccount({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.accountType = 'private',
    this.authMethod = 'email',
    required this.lastUsed,
  });

  /// Convert SavedAccount to Map for storage in SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'accountType': accountType,
      'authMethod': authMethod,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  /// Create SavedAccount from Map stored in SharedPreferences
  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      accountType: json['accountType'] as String? ?? 'private',
      authMethod: json['authMethod'] as String? ?? 'email',
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }

  /// Create SavedAccount from Firebase User
  factory SavedAccount.fromFirebaseUser(
    firebase_auth.User firebaseUser, {
    String accountType = 'private',
    String authMethod = 'email',
  }) {
    return SavedAccount(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'User',
      photoUrl: firebaseUser.photoURL,
      accountType: accountType,
      authMethod: authMethod,
      lastUsed: DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  SavedAccount copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? accountType,
    String? authMethod,
    DateTime? lastUsed,
  }) {
    return SavedAccount(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      accountType: accountType ?? this.accountType,
      authMethod: authMethod ?? this.authMethod,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedAccount && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
