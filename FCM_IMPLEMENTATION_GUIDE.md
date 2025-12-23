# Firebase Cloud Messaging (FCM) Implementation Guide

**Complete step-by-step guide to replicate FCM implementation in another Flutter project (iOS repository)**

This document contains all changes made to implement Firebase Cloud Messaging with user-specific notification support.

---

## Overview of Changes

### Files Created:
1. `lib/services/firebase_messaging_service.dart` - Core FCM service
2. `lib/services/user_notification_service.dart` - User-specific notification management
3. `FCM_SETUP_GUIDE.md` - General FCM setup documentation
4. `SEND_USER_NOTIFICATIONS_GUIDE.md` - Guide for sending to specific users
5. `HOW_TO_SEND_TO_SPECIFIC_USER.md` - Quick reference guide

### Files Modified:
1. `pubspec.yaml` - Added firebase_messaging dependency
2. `lib/main.dart` - Added FCM initialization
3. `lib/services/auth_service.dart` - Added automatic token save/remove on login/logout
4. `android/app/build.gradle` - Added Firebase Messaging dependency
5. `android/app/src/main/AndroidManifest.xml` - Added FCM permissions and metadata

---

## Step 1: Add Dependencies

### File: `pubspec.yaml`

**Location:** Line 35 (after `firebase_auth`)

**Add this line:**
```yaml
firebase_messaging: ^14.6.5
```

**Full context:**
```yaml
dependencies:
  url_launcher: ^6.2.1
  table_calendar: ^3.0.9
  firebase_core: ^2.10.0
  firebase_auth: ^4.6.3
  firebase_messaging: ^14.6.5  # ← ADD THIS LINE
  google_sign_in: ^6.1.5
  cloud_firestore: ^4.8.2
```

**Run after adding:**
```bash
flutter pub get
```

---

## Step 2: Create Firebase Messaging Service

### File: `lib/services/firebase_messaging_service.dart`

**Action:** Create new file

**Full content:**
```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Handle background messages here
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Cloud Messaging
  Future<void> initialize() async {
    try {
      // Request notification permissions (iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      // Get FCM token
      await _getToken();

      // Setup message handlers
      _setupMessageHandlers();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token refreshed: $newToken');
        // You can send this token to your backend server
        _saveTokenToPreferences(newToken);
      });

    } catch (e) {
      print('Error initializing Firebase Messaging: $e');
    }
  }

  /// Get FCM token
  Future<String?> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      print('FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        await _saveTokenToPreferences(_fcmToken!);
        // Send token to your backend server here if needed
      }

      return _fcmToken;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save token to local storage
  Future<void> _saveTokenToPreferences(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Get saved token from local storage
  Future<String?> getSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      print('Error getting saved FCM token: $e');
      return null;
    }
  }

  /// Setup message handlers for different states
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Show local notification here if needed
        _handleForegroundMessage(message);
      }
    });

    // Handle notification taps when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');
      _handleNotificationTap(message);
    });

    // Check if app was opened from terminated state by tapping notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state via notification');
        _handleNotificationTap(message);
      }
    });
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // You can show a local notification or in-app notification here
    print('Foreground message received:');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');

    // Add your custom logic here (e.g., show a snackbar, dialog, etc.)
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped:');
    print('Data: ${message.data}');

    // Navigate to specific screen based on notification data
    if (message.data.containsKey('screen')) {
      String screen = message.data['screen'];
      print('Navigate to screen: $screen');

      // Add navigation logic here
      // Example: Navigator.pushNamed(context, screen);
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      print('FCM token deleted');
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }
}
```

---

## Step 3: Create User Notification Service

### File: `lib/services/user_notification_service.dart`

**Action:** Create new file

**Full content:**
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_messaging_service.dart';

/// Service to manage user-specific notifications
class UserNotificationService {
  static final UserNotificationService _instance = UserNotificationService._internal();
  factory UserNotificationService() => _instance;
  UserNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();

  /// Save user's FCM token to Firestore
  /// Call this when user logs in
  Future<void> saveUserToken(String userId) async {
    try {
      String? token = _messagingService.fcmToken;

      if (token == null) {
        print('No FCM token available');
        return;
      }

      // Save token to Firestore under user's document
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true won't overwrite other user data

      print('FCM token saved for user: $userId');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Remove user's FCM token from Firestore
  /// Call this when user logs out
  Future<void> removeUserToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });

      print('FCM token removed for user: $userId');
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }

  /// Get FCM token for a specific user
  /// Useful if you want to send notification from your Flutter app
  Future<String?> getUserToken(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        return data?['fcmToken'];
      }

      return null;
    } catch (e) {
      print('Error getting user token: $e');
      return null;
    }
  }

  /// Update token when it refreshes
  Future<void> updateUserToken(String userId, String newToken) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': newToken,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('FCM token updated for user: $userId');
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
}
```

---

## Step 4: Update main.dart

### File: `lib/main.dart`

**Changes:**

#### Change 1: Add imports (at the top, around line 6)

**Add these two lines:**
```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/firebase_messaging_service.dart';
```

**Full import section should look like:**
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';  // ← ADD THIS
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/firebase_messaging_service.dart';  // ← ADD THIS
import 'screens/home_screen.dart';
// ... rest of imports
```

#### Change 2: Update main() function (around line 24)

**Replace the entire `main()` function with:**
```dart
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('Firebase initialized successfully');

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize Firebase Messaging
    final messagingService = FirebaseMessagingService();
    await messagingService.initialize();
    print('Firebase Messaging initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue running the app even if Firebase fails
  }

  runApp(const MyApp());
}
```

**What changed:**
- Added `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);`
- Added FCM service initialization: `final messagingService = FirebaseMessagingService();` and `await messagingService.initialize();`
- Added success log

---

## Step 5: Update auth_service.dart

### File: `lib/services/auth_service.dart`

**Changes:**

#### Change 1: Add import (at the top, around line 8)

**Add this line:**
```dart
import 'user_notification_service.dart';
```

**Full import section should look like:**
```dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../models/saved_account.dart';
import 'user_preferences_service.dart';
import '../models/enrolled_course.dart';
import 'account_manager_service.dart';
import 'user_notification_service.dart';  // ← ADD THIS
```

#### Change 2: Add notification service instance (around line 15)

**Add this line after the other service declarations:**
```dart
final UserNotificationService _notificationService = UserNotificationService();
```

**Full class variables should look like:**
```dart
class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserPreferencesService _preferencesService = UserPreferencesService();
  final AccountManagerService _accountManager = AccountManagerService();
  final UserNotificationService _notificationService = UserNotificationService();  // ← ADD THIS
```

#### Change 3: Update signInWithGoogle() function (around line 307-316)

**Find this code block:**
```dart
        // Save account to saved accounts list
        await _saveAccountAfterLogin(userCredential.user!, 'google');

        // Load user data including favorites
        await loadUserData();
      }

      // Return user data
      return _userFromFirebase(userCredential.user);
```

**Replace with:**
```dart
        // Save account to saved accounts list
        await _saveAccountAfterLogin(userCredential.user!, 'google');

        // Save FCM token for push notifications
        await _notificationService.saveUserToken(userCredential.user!.uid);

        // Load user data including favorites
        await loadUserData();
      }

      // Return user data
      return _userFromFirebase(userCredential.user);
```

**What changed:** Added `await _notificationService.saveUserToken(userCredential.user!.uid);`

#### Change 4: Update signInWithEmailPassword() function (around line 335-344)

**Find this code block:**
```dart
      if (credential.user != null) {
        // Save account to saved accounts list
        await _saveAccountAfterLogin(credential.user!, 'email');

        // Load user data including favorites
        await loadUserData();
      }

      return _userFromFirebase(credential.user);
```

**Replace with:**
```dart
      if (credential.user != null) {
        // Save account to saved accounts list
        await _saveAccountAfterLogin(credential.user!, 'email');

        // Save FCM token for push notifications
        await _notificationService.saveUserToken(credential.user!.uid);

        // Load user data including favorites
        await loadUserData();
      }

      return _userFromFirebase(credential.user);
```

**What changed:** Added `await _notificationService.saveUserToken(credential.user!.uid);`

#### Change 5: Update signOut() function (around line 440-452)

**Find this code block:**
```dart
  Future<void> signOut() async {
    try {
      // Clear local storage for the current user before signing out
      final currentUserId = _firebaseAuth.currentUser?.uid;
      if (currentUserId != null) {
        await _preferencesService.clearLocalStorage(currentUserId);
      }

      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
```

**Replace with:**
```dart
  Future<void> signOut() async {
    try {
      // Clear local storage for the current user before signing out
      final currentUserId = _firebaseAuth.currentUser?.uid;
      if (currentUserId != null) {
        await _preferencesService.clearLocalStorage(currentUserId);

        // Remove FCM token from Firestore on logout
        await _notificationService.removeUserToken(currentUserId);
      }

      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
```

**What changed:** Added `await _notificationService.removeUserToken(currentUserId);`

---

## Step 6: Android Configuration

### File: `android/app/build.gradle`

**Change:** Add Firebase Messaging dependency (around line 71)

**Find this section:**
```gradle
dependencies {
    // Import the Firebase BoM
    implementation platform('com.google.firebase:firebase-bom:32.2.0')
    implementation 'com.google.firebase:firebase-auth'
}
```

**Replace with:**
```gradle
dependencies {
    // Import the Firebase BoM
    implementation platform('com.google.firebase:firebase-bom:32.2.0')
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-messaging'  // ← ADD THIS LINE
}
```

---

### File: `android/app/src/main/AndroidManifest.xml`

#### Change 1: Add notification permission (around line 4)

**Find:**
```xml
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

**Replace with:**
```xml
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <!-- FCM Permissions -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

#### Change 2: Add FCM metadata (around line 36)

**Find:**
```xml
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
```

**Replace with:**
```xml
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />

        <!-- Firebase Cloud Messaging -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="default_notification_channel" />
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/launcher_icon" />
    </application>
```

---

## Step 7: iOS Configuration

### File: `ios/Runner/Info.plist`

**No changes needed!** The `firebase_messaging` plugin handles iOS setup automatically.

### Additional iOS Setup (Required in Xcode):

1. **Open iOS project in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Select Runner target > Signing & Capabilities**

3. **Add Push Notifications capability:**
   - Click "+ Capability"
   - Search for "Push Notifications"
   - Add it

4. **Add Background Modes capability:**
   - Click "+ Capability"
   - Search for "Background Modes"
   - Add it
   - Check "Remote notifications"

5. **Configure APNs in Firebase Console:**
   - Go to Firebase Console > Project Settings > Cloud Messaging
   - Under "Apple app configuration", upload your APNs authentication key
   - Get this from Apple Developer account

---

## Step 8: Verify Firebase Configuration Files

Ensure these files exist and are properly configured:

### Android:
- `android/app/google-services.json` - should exist with your Firebase project config

### iOS:
- `ios/Runner/GoogleService-Info.plist` - should exist with your Firebase project config

If these don't exist, download them from Firebase Console > Project Settings > Your apps

---

## Testing Instructions

### 1. Install dependencies:
```bash
flutter pub get
```

### 2. Run the app:
```bash
flutter run
```

### 3. Check logs for FCM token:
Look for console output:
```
FCM Token: dBx7Y3k...
FCM token saved for user: abc123
```

### 4. Test notification:
1. Go to Firebase Console > Cloud Messaging
2. Click "Send your first message"
3. Fill in notification details
4. Click "Send test message"
5. Paste the FCM token from logs
6. Click "Test"

### 5. Verify in Firestore:
1. Go to Firebase Console > Firestore Database
2. Navigate to `users` collection
3. Find your user document
4. Verify `fcmToken` field exists with the token value

---

## How to Send Notifications to Specific Users

### Method 1: Firebase Console (Easiest)

1. Get user's FCM token from Firestore: `users/{userId}/fcmToken`
2. Firebase Console > Cloud Messaging > Send test message
3. Paste token and send

### Method 2: Backend/Cloud Function

```javascript
const admin = require('firebase-admin');

async function sendToUser(userId, title, body) {
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(userId)
    .get();

  const token = userDoc.data().fcmToken;

  await admin.messaging().send({
    token: token,
    notification: { title, body }
  });
}
```

---

## Summary of All Changes

### Dependencies:
- ✅ Added `firebase_messaging: ^14.6.5`

### New Files:
- ✅ `lib/services/firebase_messaging_service.dart`
- ✅ `lib/services/user_notification_service.dart`

### Modified Files:
- ✅ `lib/main.dart` - Added FCM initialization
- ✅ `lib/services/auth_service.dart` - Added token save/remove on login/logout
- ✅ `android/app/build.gradle` - Added FCM dependency
- ✅ `android/app/src/main/AndroidManifest.xml` - Added permissions and metadata

### iOS Additional Setup:
- ✅ Add Push Notifications capability in Xcode
- ✅ Add Background Modes capability with Remote notifications
- ✅ Upload APNs key to Firebase Console

---

## Quick Implementation Checklist for iOS Repository

```
[ ] 1. Add firebase_messaging to pubspec.yaml
[ ] 2. Run flutter pub get
[ ] 3. Create firebase_messaging_service.dart
[ ] 4. Create user_notification_service.dart
[ ] 5. Update main.dart (add imports and FCM init)
[ ] 6. Update auth_service.dart (add import, instance, and 3 function updates)
[ ] 7. Update android/app/build.gradle (add FCM dependency)
[ ] 8. Update AndroidManifest.xml (add permission and metadata)
[ ] 9. Open Xcode and add Push Notifications capability
[ ] 10. Open Xcode and add Background Modes capability
[ ] 11. Upload APNs key to Firebase Console
[ ] 12. Test: Run app, login, check for FCM token in logs
[ ] 13. Test: Send notification from Firebase Console
[ ] 14. Verify: Check Firestore for fcmToken field in user document
```

---

## Troubleshooting

### FCM token is null
- Check Firebase initialization completed successfully
- Verify google-services.json / GoogleService-Info.plist exists
- Ensure device has internet connection

### Notifications not showing (iOS)
- Verify APNs certificate uploaded to Firebase Console
- Check Push Notifications capability is enabled in Xcode
- Check Background Modes > Remote notifications is enabled

### Notifications not showing (Android)
- Check POST_NOTIFICATIONS permission granted (Android 13+)
- Verify google-services.json is in android/app/

### Token not saving to Firestore
- Check Firestore rules allow writes to users collection
- Verify user is logged in before token save attempt
- Check console for any error messages

---

**End of Implementation Guide**

Use this guide to replicate the exact same FCM implementation in your iOS repository.
