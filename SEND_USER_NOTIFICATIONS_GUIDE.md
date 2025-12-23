# Sending Notifications to Specific Users - Quick Guide

## ✅ What's Already Done

Your app now **automatically**:
1. ✅ Saves FCM tokens to Firestore when users log in
2. ✅ Removes FCM tokens when users log out
3. ✅ Updates tokens when they refresh

**This happens automatically - you don't need to do anything!**

---

## How It Works

### When User Logs In:
```
User logs in → FCM token saved to Firestore
Location: users/{userId}/fcmToken
```

### Firestore Structure:
```
users/
  └── user123/
      ├── fcmToken: "dBx7Y3k..."
      ├── lastUpdated: timestamp
      ├── name: "John Doe"
      ├── email: "john@example.com"
      └── ... (other user data)
```

---

## Sending Notifications to Specific Users

### Option 1: Firebase Console (Easiest - No Coding!)

1. **Get User's ID**:
   - View your Firestore database in Firebase Console
   - Find the user you want to notify
   - Copy their FCM token from `users/{userId}/fcmToken`

2. **Send Notification**:
   - Go to Cloud Messaging > Send your first message
   - Click "Send test message"
   - Paste the FCM token
   - Click "Test"

**That's it!** Super easy.

---

### Option 2: Using a Backend/Cloud Function (Recommended for Production)

If you have a backend server or want to use Firebase Cloud Functions:

#### Example: Node.js Backend

```javascript
const admin = require('firebase-admin');
admin.initializeApp();

async function sendNotificationToUser(userId, title, body, data = {}) {
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
      console.log('No FCM token for this user');
      return;
    }

    // Send notification
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: data, // Extra data like screen to navigate to
    };

    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    return response;

  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
}

// Usage examples:
// Send simple notification
sendNotificationToUser('user123', 'New Course!', 'Flutter Advanced is now available');

// Send with navigation data
sendNotificationToUser(
  'user123',
  'Course Update',
  'Your enrolled course has new content',
  { screen: 'course_detail', course_id: '456' }
);
```

---

### Option 3: Firebase Cloud Functions (Automatic Triggers)

Send notifications automatically when certain events happen:

#### Example: Notify user when enrolled in a course

Create this file: `functions/index.js`

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Trigger when a user enrolls in a course
exports.sendCourseEnrollmentNotification = functions.firestore
  .document('users/{userId}/enrolledCourses/{courseId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const courseData = snap.data();

    // Get user's FCM token
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log('No FCM token for user:', userId);
      return;
    }

    // Send notification
    const message = {
      token: fcmToken,
      notification: {
        title: 'Enrollment Successful!',
        body: `You've been enrolled in ${courseData.courseName}`,
      },
      data: {
        screen: 'course_detail',
        course_id: courseData.courseId,
      },
    };

    try {
      await admin.messaging().send(message);
      console.log('Notification sent to user:', userId);
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  });
```

---

## Real-World Use Cases

### 1. New Course Announcement
```javascript
// Send to specific premium users
const premiumUsers = ['user1', 'user2', 'user3'];

for (const userId of premiumUsers) {
  await sendNotificationToUser(
    userId,
    'New Premium Course!',
    'Advanced Flutter Development is now live',
    { screen: 'courses', category: 'premium' }
  );
}
```

### 2. Course Reminder
```javascript
// Remind user about incomplete course
await sendNotificationToUser(
  'user123',
  'Continue Learning',
  'You have 2 lessons left in React Basics',
  { screen: 'course_detail', course_id: '789' }
);
```

### 3. Payment Confirmation
```javascript
// After successful payment
await sendNotificationToUser(
  userId,
  'Payment Successful',
  'Your premium membership is now active',
  { screen: 'profile' }
);
```

---

## Testing

### Test sending notification to yourself:

1. **Run your app and log in**
2. **Check Firebase Console**:
   - Go to Firestore Database
   - Find your user document
   - You should see `fcmToken` field with a long string

3. **Send test notification**:
   - Firebase Console > Cloud Messaging
   - "Send test message"
   - Paste your FCM token
   - Send!

4. **Check your phone** - you should receive the notification!

---

## Quick Reference: What You Can Do

| Action | Difficulty | How |
|--------|-----------|-----|
| Send to specific user | ⭐ Easy | Use Firebase Console with FCM token |
| Send to multiple users | ⭐⭐ Medium | Loop through users and send individually |
| Send based on conditions | ⭐⭐ Medium | Query Firestore, then send to matching users |
| Auto-send on events | ⭐⭐⭐ Advanced | Use Cloud Functions with triggers |

---

## Example: Send to All Users Who Enrolled Today

```javascript
async function notifyTodaysEnrollments() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  // Query users who enrolled today
  const usersSnapshot = await admin.firestore()
    .collection('users')
    .where('enrollmentDate', '>=', today)
    .get();

  // Send notification to each
  const promises = usersSnapshot.docs.map(async (doc) => {
    const fcmToken = doc.data().fcmToken;
    if (!fcmToken) return;

    return admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'Welcome to ITEL!',
        body: 'Start your learning journey today',
      },
    });
  });

  await Promise.all(promises);
  console.log(`Sent ${promises.length} notifications`);
}
```

---

## Summary

**It's actually very easy!**

1. ✅ Your app automatically saves FCM tokens (already done)
2. ✅ You can send to specific users from Firebase Console (no coding)
3. ✅ Or use a simple backend script for automation (optional)

**The hard part is already done** - FCM tokens are automatically managed in your app!
