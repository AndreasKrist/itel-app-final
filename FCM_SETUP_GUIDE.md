# Firebase Cloud Messaging (FCM) Setup Guide

## What I've Done

I've set up Firebase Cloud Messaging for your ITEL app. Here's what was configured:

### 1. Added Dependencies
- `firebase_messaging: ^14.6.5` added to `pubspec.yaml`

### 2. Created Service
- Created `lib/services/firebase_messaging_service.dart` - handles all push notification logic

### 3. Updated main.dart
- Initialized FCM when app starts
- Registered background message handler

### 4. Android Configuration
- Added `firebase-messaging` to `build.gradle`
- Added notification permission to `AndroidManifest.xml`
- Configured default notification channel and icon

### 5. iOS Configuration
- iOS setup is automatically handled by the firebase_messaging plugin
- Notifications will work once you configure APNs in Firebase Console

---

## How to Use Push Notifications

### Getting the FCM Token

The FCM token is automatically generated when the app starts. You can access it:

```dart
import 'services/firebase_messaging_service.dart';

final messagingService = FirebaseMessagingService();
String? token = messagingService.fcmToken;
print('FCM Token: $token');
```

### Sending Test Notifications

#### Method 1: Firebase Console (Easiest)
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Cloud Messaging** in the left sidebar
4. Click **Send your first message**
5. Enter notification title and text
6. Click **Send test message**
7. Paste your FCM token
8. Click **Test**

#### Method 2: Using REST API

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
-H "Authorization: key=YOUR_SERVER_KEY" \
-H "Content-Type: application/json" \
-d '{
  "to": "DEVICE_FCM_TOKEN",
  "notification": {
    "title": "Test Notification",
    "body": "This is a test message from FCM"
  },
  "data": {
    "screen": "courses",
    "course_id": "123"
  }
}'
```

Find your server key in Firebase Console > Project Settings > Cloud Messaging

---

## Notification States

The app handles notifications in three states:

### 1. Foreground (App is open)
- Notification appears while user is using the app
- Handled in `_handleForegroundMessage()` in `firebase_messaging_service.dart`
- You can show an in-app notification, snackbar, or dialog

### 2. Background (App is minimized)
- Notification appears in the notification tray
- Tapping opens the app
- Handled in `FirebaseMessaging.onMessageOpenedApp`

### 3. Terminated (App is closed)
- Notification appears in the notification tray
- Tapping launches the app
- Handled in `_messaging.getInitialMessage()`

---

## Topic Subscriptions

Subscribe users to topics to send notifications to groups:

```dart
final messagingService = FirebaseMessagingService();

// Subscribe to a topic
await messagingService.subscribeToTopic('all_users');
await messagingService.subscribeToTopic('premium_users');

// Unsubscribe from a topic
await messagingService.unsubscribeFromTopic('all_users');
```

Send to topics from Firebase Console or API:

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
-H "Authorization: key=YOUR_SERVER_KEY" \
-H "Content-Type: application/json" \
-d '{
  "to": "/topics/all_users",
  "notification": {
    "title": "New Course Available!",
    "body": "Check out our latest Flutter course"
  }
}'
```

---

## Advanced Features

### Navigate to Specific Screens

Include screen data in your notification:

```json
{
  "notification": {
    "title": "New Course",
    "body": "Flutter Advanced"
  },
  "data": {
    "screen": "course_detail",
    "course_id": "123"
  }
}
```

Then handle navigation in `_handleNotificationTap()`:

```dart
void _handleNotificationTap(RemoteMessage message) {
  if (message.data.containsKey('screen')) {
    String screen = message.data['screen'];
    String? courseId = message.data['course_id'];

    // Navigate to the specific screen
    // Example: Navigator.pushNamed(context, '/course', arguments: courseId);
  }
}
```

### Store Token in Your Backend

When a user logs in, send their FCM token to your server:

```dart
final messagingService = FirebaseMessagingService();
String? token = messagingService.fcmToken;

// Send to your backend
await http.post(
  Uri.parse('https://your-api.com/users/update-fcm-token'),
  body: {
    'user_id': userId,
    'fcm_token': token,
  },
);
```

---

## Testing Checklist

1. **Run the app**
   ```bash
   flutter pub get
   flutter run
   ```

2. **Check console for FCM token**
   - Look for: "FCM Token: xxxxxx" in your logs

3. **Test foreground notification**
   - Keep app open
   - Send test notification from Firebase Console
   - Should see notification data in logs

4. **Test background notification**
   - Minimize app
   - Send test notification
   - Tap notification to open app

5. **Test terminated state**
   - Close app completely
   - Send test notification
   - Tap notification to launch app

---

## Important Notes

### Android
- **Minimum SDK**: API level 21 (already configured in your app)
- **Notification permission**: Required for Android 13+ (already added)
- **Icon**: Uses your launcher_icon by default

### iOS
- **APNs Certificate**: You need to upload your APNs certificate to Firebase Console
- **Capabilities**: Enable "Push Notifications" in Xcode
- **Background Modes**: Enable "Remote notifications" in Xcode

### iOS Additional Setup (Required for iOS)
1. Open project in Xcode: `open ios/Runner.xcworkspace`
2. Select Runner > Signing & Capabilities
3. Click "+ Capability" and add "Push Notifications"
4. Click "+ Capability" and add "Background Modes"
5. Check "Remote notifications" under Background Modes
6. Upload APNs key to Firebase Console:
   - Firebase Console > Project Settings > Cloud Messaging
   - Under "Apple app configuration", upload your APNs key

---

## Troubleshooting

### Token is null
- Make sure Firebase is initialized
- Check that google-services.json (Android) and GoogleService-Info.plist (iOS) are in the correct locations
- Ensure device has internet connection

### Notifications not showing
- Android: Check notification permission is granted
- iOS: Check APNs certificate is configured in Firebase Console
- Check server key is correct

### Background notifications not working
- Make sure `FirebaseMessaging.onBackgroundMessage` is registered before `runApp()`
- Check that the handler function is top-level (not inside a class)

---

## Next Steps

1. **Get your FCM token**: Check the console when you run the app
2. **Send a test notification**: Use Firebase Console
3. **Implement custom notification handling**: Modify `_handleForegroundMessage()` to show in-app notifications
4. **Set up server integration**: Send tokens to your backend
5. **Create notification categories**: Subscribe users to topics based on their interests

---

## Example Usage in Your App

```dart
// In any screen, get the messaging service
import 'services/firebase_messaging_service.dart';

class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();

  @override
  void initState() {
    super.initState();

    // Subscribe to topics based on user preferences
    _subscribeToCourseTopics();
  }

  void _subscribeToCourseTopics() async {
    await _messagingService.subscribeToTopic('flutter_courses');
    await _messagingService.subscribeToTopic('trending_updates');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Notifications are enabled!'),
      ),
    );
  }
}
```

---

## Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire FCM Plugin](https://firebase.flutter.dev/docs/messaging/overview)
- [Test FCM Messages](https://firebase.google.com/docs/cloud-messaging/flutter/first-message)
