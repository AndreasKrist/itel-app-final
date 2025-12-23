# How to Send Notifications to Specific Users

## Quick Start Guide

### Step 1: Run Your App and Login

1. Run the app: `flutter run`
2. Login with any account (Google or Email)
3. Check the console/logs - you'll see:
   ```
   FCM Token: eXaMpLe_ToKeN_hErE...
   FCM token saved for user: user123
   ```

### Step 2: Check Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click **Firestore Database** in the left menu
4. Navigate to **users** collection
5. Click on a user document
6. You'll see a field called **fcmToken** with a long string

Example:
```
users/
  └── abc123xyz (user ID)
      ├── fcmToken: "dBx7Y3kQR8W..."  ← This is what you need!
      ├── email: "john@example.com"
      ├── name: "John Doe"
      └── ...
```

### Step 3: Send Notification via Firebase Console

1. In Firebase Console, click **Cloud Messaging** (left menu under "Engage")
2. Click **"Send your first message"** (or "New notification")
3. Fill in:
   - **Notification title**: e.g., "New Course Available!"
   - **Notification text**: e.g., "Check out Flutter Advanced"
4. Click **"Send test message"**
5. Paste the `fcmToken` you copied from Firestore
6. Click **"Test"**

**Done!** The user will receive the notification.

---

## Method 2: Send from Backend (For Automation)

If you want to send notifications programmatically (from a server, Cloud Function, etc.):

### Prerequisites:
1. Get your **Server Key** from Firebase Console:
   - Project Settings > Cloud Messaging > Server key

### Example: Using Node.js

```javascript
const admin = require('firebase-admin');

// Initialize (do this once)
admin.initializeApp({
  credential: admin.credential.cert('./serviceAccountKey.json')
});

// Function to send notification to specific user
async function sendToUser(userId, title, body) {
  try {
    // Get user's FCM token from Firestore
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      console.log('User not found');
      return;
    }

    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) {
      console.log('User has no FCM token');
      return;
    }

    // Send notification
    const message = {
      notification: {
        title: title,
        body: body,
      },
      token: fcmToken,
    };

    const response = await admin.messaging().send(message);
    console.log('Sent successfully:', response);

  } catch (error) {
    console.error('Error:', error);
  }
}

// Usage:
sendToUser('abc123xyz', 'Hello!', 'You have a new message');
```

### Example: Using cURL (REST API)

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "USER_FCM_TOKEN_HERE",
    "notification": {
      "title": "New Course",
      "body": "Flutter Advanced is now available"
    },
    "data": {
      "screen": "courses",
      "course_id": "123"
    }
  }'
```

---

## Method 3: Send to Multiple Specific Users

### Example: Send to a list of user IDs

```javascript
async function sendToMultipleUsers(userIds, title, body) {
  const promises = userIds.map(async (userId) => {
    // Get FCM token for each user
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return null;

    // Send notification
    return admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
    });
  });

  const results = await Promise.all(promises);
  console.log(`Sent to ${results.filter(r => r).length} users`);
}

// Usage:
sendToMultipleUsers(
  ['user1', 'user2', 'user3'],
  'Important Update',
  'New features are available'
);
```

### Example: Send to users with specific criteria

```javascript
async function sendToPremiumUsers(title, body) {
  // Query Firestore for premium users
  const snapshot = await admin.firestore()
    .collection('users')
    .where('tier', '==', 'premium')
    .get();

  const promises = snapshot.docs.map(doc => {
    const fcmToken = doc.data().fcmToken;
    if (!fcmToken) return null;

    return admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
    });
  });

  await Promise.all(promises);
  console.log(`Sent to ${snapshot.size} premium users`);
}

// Usage:
sendToPremiumUsers('Exclusive Content', 'New premium course added');
```

---

## Method 4: From Your Flutter App (Advanced)

You can also send notifications from within your Flutter app, but this requires:
1. A backend Cloud Function (you can't send directly from Flutter for security)
2. Your Flutter app calls the Cloud Function with the user ID

### Example Cloud Function:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const { targetUserId, title, body } = data;

  // Get target user's FCM token
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(targetUserId)
    .get();

  const fcmToken = userDoc.data()?.fcmToken;

  if (!fcmToken) {
    throw new functions.https.HttpsError('not-found', 'User has no FCM token');
  }

  // Send notification
  await admin.messaging().send({
    token: fcmToken,
    notification: { title, body },
  });

  return { success: true };
});
```

### Call from Flutter:

```dart
import 'package:cloud_functions/cloud_functions.dart';

Future<void> sendNotificationToUser(String userId, String title, String body) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('sendNotification');

    await callable.call({
      'targetUserId': userId,
      'title': title,
      'body': body,
    });

    print('Notification sent successfully');
  } catch (e) {
    print('Error sending notification: $e');
  }
}

// Usage:
sendNotificationToUser('user123', 'Hello!', 'You got a message');
```

---

## Common Use Cases

### 1. Welcome New User

```javascript
// When user signs up
exports.welcomeNewUser = functions.auth.user().onCreate(async (user) => {
  // Wait a bit for FCM token to be saved
  await new Promise(resolve => setTimeout(resolve, 2000));

  const userDoc = await admin.firestore()
    .collection('users')
    .doc(user.uid)
    .get();

  const fcmToken = userDoc.data()?.fcmToken;
  if (!fcmToken) return;

  await admin.messaging().send({
    token: fcmToken,
    notification: {
      title: 'Welcome to ITEL! 🎉',
      body: 'Start your learning journey today',
    },
  });
});
```

### 2. Notify When Course is Updated

```javascript
// When you update a course
async function notifyEnrolledStudents(courseId, updateMessage) {
  // Get all users enrolled in this course
  const usersSnapshot = await admin.firestore()
    .collection('users')
    .where('enrolledCourses', 'array-contains', courseId)
    .get();

  const promises = usersSnapshot.docs.map(doc => {
    const fcmToken = doc.data().fcmToken;
    if (!fcmToken) return null;

    return admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'Course Updated',
        body: updateMessage,
      },
      data: {
        screen: 'course_detail',
        course_id: courseId,
      },
    });
  });

  await Promise.all(promises);
}

// Usage:
notifyEnrolledStudents('flutter101', 'New lesson added: Advanced State Management');
```

### 3. Payment Confirmation

```javascript
// After successful payment
async function sendPaymentConfirmation(userId, amount, courseName) {
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(userId)
    .get();

  const fcmToken = userDoc.data()?.fcmToken;
  if (!fcmToken) return;

  await admin.messaging().send({
    token: fcmToken,
    notification: {
      title: 'Payment Successful ✓',
      body: `You've successfully enrolled in ${courseName}`,
    },
    data: {
      screen: 'profile',
      tab: 'enrolled',
    },
  });
}
```

---

## Testing Checklist

1. ✅ Run your app
2. ✅ Login with a user account
3. ✅ Check console for "FCM token saved for user: xxx"
4. ✅ Open Firebase Console > Firestore > users > [your user] > check fcmToken field exists
5. ✅ Copy the fcmToken value
6. ✅ Go to Cloud Messaging > Send test message
7. ✅ Paste token and send
8. ✅ Check your device for notification

---

## Important Notes

- **Tokens are saved automatically** when users login (already implemented)
- **Tokens are removed automatically** when users logout (already implemented)
- **Each device has a unique token** - if a user logs in on multiple devices, only the latest device gets notifications (you can extend this to save multiple tokens)
- **Tokens can expire** - the app handles token refresh automatically

---

## Need Help?

- FCM token not showing in Firestore? → Check that user logged in successfully
- Notification not received? → Check that device has internet and notifications are enabled
- Token is null? → Firebase might not be initialized properly, check console for errors

---

## Summary

**Easiest Method:**
1. User logs in → token saved automatically to Firestore
2. Get token from Firestore Database in Firebase Console
3. Send test notification via Cloud Messaging in Firebase Console

**That's it!** The infrastructure is all set up and working automatically.
