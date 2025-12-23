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
