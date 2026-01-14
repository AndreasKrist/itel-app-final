# Ask ITEL Feature Implementation Guide

This guide documents the changes to convert the Forum Q&A into "Ask ITEL" with:
- **Question moderation** (pending/approved/rejected status)
- **Staff-only answers** (only ITEL staff can answer)
- **Role-based access control** (user/staff/admin roles)

---

## PART 1: UPDATE USER MODEL

### File: `lib/models/user.dart`

**ADD** the `UserRole` enum and extension at the TOP of the file (after imports, before `MembershipTier`):

```dart
/// User roles for access control
enum UserRole {
  user,   // Regular user - can ask questions, view answers
  staff,  // ITEL staff - can answer questions
  admin,  // Admin - full access (future use)
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.staff:
        return 'ITEL Staff';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  bool get canAnswerQuestions => this == UserRole.staff || this == UserRole.admin;
  bool get canModerateQuestions => this == UserRole.staff || this == UserRole.admin;
}
```

**ADD** the `role` field to the `User` class:

In the class fields section, add:
```dart
final UserRole role;  // User role for access control (user, staff, admin)
```

In the constructor, add:
```dart
this.role = UserRole.user,  // Default to regular user role
```

In the `copyWith` method, add parameter:
```dart
UserRole? role,
```

And in the return statement:
```dart
role: role ?? this.role,
```

**UPDATE** `guestUser` static getter - add:
```dart
role: UserRole.user,
```

**UPDATE** `currentUser` static instance - add:
```dart
role: UserRole.user,  // Default role - will be loaded from Firebase
```

**ADD** these helper methods at the end of the `User` class (before the closing brace):

```dart
/// Helper method to check if user is ITEL staff
bool get isStaff => role.canAnswerQuestions;

/// Helper method to parse role from Firebase string
static UserRole parseRole(String? roleString) {
  switch (roleString) {
    case 'staff':
      return UserRole.staff;
    case 'admin':
      return UserRole.admin;
    case 'user':
    default:
      return UserRole.user;
  }
}

/// Convert role to string for Firebase storage
String get roleString {
  switch (role) {
    case UserRole.staff:
      return 'staff';
    case UserRole.admin:
      return 'admin';
    case UserRole.user:
      return 'user';
  }
}
```

---

## PART 2: UPDATE FORUM QUESTION MODEL

### File: `lib/models/forum_question.dart`

**ADD** the `ApprovalStatus` enum after `QuestionStatus`:

```dart
/// Approval status for question moderation
enum ApprovalStatus {
  pending,   // Waiting for admin/staff approval
  approved,  // Approved and visible to public
  rejected,  // Rejected by moderator
}
```

**ADD** the `approvalStatus` field to `ForumQuestion` class:

In class fields:
```dart
final ApprovalStatus approvalStatus;  // Moderation status
```

In constructor:
```dart
this.approvalStatus = ApprovalStatus.pending,  // Default to pending
```

**UPDATE** `fromJson` factory - add:
```dart
approvalStatus: _stringToApprovalStatus(json['approvalStatus'] as String? ?? 'pending'),
```

**UPDATE** `toJson` method - add:
```dart
'approvalStatus': _approvalStatusToString(approvalStatus),
```

**UPDATE** `copyWith` method - add parameter:
```dart
ApprovalStatus? approvalStatus,
```

And in return:
```dart
approvalStatus: approvalStatus ?? this.approvalStatus,
```

**ADD** these helper methods (after `_statusToString`):

```dart
static ApprovalStatus _stringToApprovalStatus(String statusString) {
  switch (statusString) {
    case 'approved':
      return ApprovalStatus.approved;
    case 'rejected':
      return ApprovalStatus.rejected;
    case 'pending':
    default:
      return ApprovalStatus.pending;
  }
}

static String _approvalStatusToString(ApprovalStatus status) {
  switch (status) {
    case ApprovalStatus.approved:
      return 'approved';
    case ApprovalStatus.rejected:
      return 'rejected';
    case ApprovalStatus.pending:
      return 'pending';
  }
}

/// Check if question is visible to public (approved)
bool get isApproved => approvalStatus == ApprovalStatus.approved;

/// Check if question is pending moderation
bool get isPending => approvalStatus == ApprovalStatus.pending;
```

---

## PART 3: UPDATE FORUM ANSWER MODEL

### File: `lib/models/forum_answer.dart`

**ADD** the `isStaffAnswer` field:

In class fields:
```dart
final bool isStaffAnswer;  // Indicates if this is an official ITEL staff answer
```

In constructor:
```dart
this.isStaffAnswer = false,
```

**UPDATE** `fromJson` - add:
```dart
isStaffAnswer: json['isStaffAnswer'] as bool? ?? false,
```

**UPDATE** `toJson` - add:
```dart
'isStaffAnswer': isStaffAnswer,
```

**UPDATE** `copyWith` - add parameter:
```dart
bool? isStaffAnswer,
```

And in return:
```dart
isStaffAnswer: isStaffAnswer ?? this.isStaffAnswer,
```

---

## PART 4: UPDATE FORUM SERVICE

### File: `lib/services/forum_service.dart`

**ADD** import at top:
```dart
import '../models/user.dart';
```

**REPLACE** the `getQuestionsStream` section with these THREE methods:

```dart
// ============ QUESTIONS ============

/// Stream of APPROVED questions only (for public view)
/// This is what regular users see
Stream<List<ForumQuestion>> getApprovedQuestionsStream() {
  return _questionsCollection
      .where('approvalStatus', isEqualTo: 'approved')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return ForumQuestion.fromJson(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  });
}

/// Stream of all questions ordered by newest first (for staff/admin moderation)
Stream<List<ForumQuestion>> getQuestionsStream() {
  return _questionsCollection
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return ForumQuestion.fromJson(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  });
}

/// Stream of questions by a specific user (shows their own questions regardless of status)
Stream<List<ForumQuestion>> getUserQuestionsStream(String userId) {
  return _questionsCollection
      .where('authorId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return ForumQuestion.fromJson(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  });
}
```

**UPDATE** `createQuestion` method - add `approvalStatus` to the document:

```dart
/// Create a new question (defaults to pending approval status)
Future<String> createQuestion({
  required String authorId,
  required String authorName,
  required String authorEmail,
  required String title,
  required String content,
  List<String> tags = const [],
}) async {
  try {
    final now = DateTime.now();
    final docRef = await _questionsCollection.add({
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'title': title,
      'content': content,
      'tags': tags,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'answerCount': 0,
      'status': 'open',
      'acceptedAnswerId': null,
      'approvalStatus': 'pending',  // Questions need approval before showing publicly
    });
    print('Question created with ID: ${docRef.id} (pending approval)');
    return docRef.id;
  } catch (e) {
    print('Error creating question: $e');
    rethrow;
  }
}
```

**ADD** this new method after `createQuestion`:

```dart
/// Update question approval status (staff/admin only)
Future<void> updateQuestionApprovalStatus(
  String questionId,
  ApprovalStatus status,
) async {
  try {
    String statusString;
    switch (status) {
      case ApprovalStatus.approved:
        statusString = 'approved';
        break;
      case ApprovalStatus.rejected:
        statusString = 'rejected';
        break;
      case ApprovalStatus.pending:
        statusString = 'pending';
        break;
    }

    await _questionsCollection.doc(questionId).update({
      'approvalStatus': statusString,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('Question $questionId approval status updated to: $statusString');
  } catch (e) {
    print('Error updating question approval status: $e');
    rethrow;
  }
}
```

**REPLACE** `createAnswer` method with staff-only version:

```dart
/// Create a new answer (staff only)
/// The isStaff flag indicates if the answer is from ITEL staff
Future<String> createAnswer({
  required String questionId,
  required String authorId,
  required String authorName,
  required String authorEmail,
  required String content,
  required bool isStaff,
}) async {
  try {
    // Only staff can answer questions
    if (!isStaff) {
      throw Exception('Only ITEL staff can answer questions');
    }

    final batch = _firestore.batch();

    // Create answer document with staff indicator
    final answerRef = _answersCollection(questionId).doc();
    batch.set(answerRef, {
      'questionId': questionId,
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'content': content,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'isAccepted': false,
      'isStaffAnswer': true,  // Mark as official ITEL staff answer
    });

    // Increment answer count on question
    final questionRef = _questionsCollection.doc(questionId);
    batch.update(questionRef, {
      'answerCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    print('Staff answer created with ID: ${answerRef.id}');
    return answerRef.id;
  } catch (e) {
    print('Error creating answer: $e');
    rethrow;
  }
}
```

---

## PART 5: UPDATE AUTH SERVICE

### File: `lib/services/auth_service.dart`

**FIND** the section where `User.currentUser` is set (in the `loadUserData` or similar method).

**ADD** before the `User.currentUser = User(...)` line:

```dart
// Load user role (for Ask ITEL staff functionality)
final UserRole role = User.parseRole(userProfile?['role']);
print('Loaded user role: ${role.displayName} (${role.canAnswerQuestions ? "CAN ANSWER QUESTIONS" : "REGULAR USER"})');
```

**ADD** in the `User.currentUser = User(...)` constructor call:

```dart
role: role, // Load user role for Ask ITEL feature
```

---

## PART 6: UPDATE COMMUNITY SCREEN

### File: `lib/screens/community_screen.dart`

**CHANGE** header title from 'Community' to 'Ask ITEL':

```dart
Text(
  'Ask ITEL',
  style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
),
Text(
  'Get answers from ITEL experts',
  style: TextStyle(
    fontSize: 12,
    color: Colors.grey[600],
  ),
),
```

**CHANGE** tab labels:

```dart
tabs: const [
  Tab(
    icon: Icon(Icons.question_answer, size: 20),
    text: 'Ask ITEL',
  ),
  Tab(
    icon: Icon(Icons.chat, size: 20),
    text: 'Global Chat',
  ),
],
```

**CHANGE** in `_buildForumTab`, update the stream to use approved questions:

```dart
// Questions list (only approved questions)
Expanded(
  child: StreamBuilder<List<ForumQuestion>>(
    stream: _forumService.getApprovedQuestionsStream(),
    builder: (context, snapshot) {
```

**CHANGE** the empty state icon and text:

```dart
Icon(Icons.question_answer_outlined,
    size: 64, color: Colors.grey[400]),
// ...
Text(
  _filterStatus == 'all'
      ? 'Ask ITEL experts your questions!'
      : 'Try a different filter',
  style: TextStyle(color: Colors.grey[500]),
),
// ...
label: const Text('Ask ITEL'),
```

---

## PART 7: UPDATE FORUM QUESTION DETAIL SCREEN

### File: `lib/screens/forum_question_detail_screen.dart`

**ADD** staff check in `build` method:

```dart
@override
Widget build(BuildContext context) {
  final currentUser = User.currentUser;
  final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;
  final isStaff = currentUser.isStaff;  // Check if user is ITEL staff
```

**UPDATE** `_submitAnswer` method - add staff check and pass isStaff:

After the guest check, add:
```dart
// Check if user is staff
if (!currentUser.isStaff) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Only ITEL staff can answer questions'),
      backgroundColor: Colors.orange,
    ),
  );
  return;
}
```

Update the `createAnswer` call:
```dart
await _forumService.createAnswer(
  questionId: widget.questionId,
  authorId: currentUser.id,
  authorName: currentUser.name,
  authorEmail: currentUser.email,
  content: _answerController.text.trim(),
  isStaff: currentUser.isStaff,  // Pass staff status
);
```

**REPLACE** the bottom section (answer input area) with:

```dart
// Answer input (only for ITEL staff)
if (isStaff)
  Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(
        top: BorderSide(color: Colors.grey[200]!),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Staff badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0056AC).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 14, color: Color(0xFF0056AC)),
                SizedBox(width: 4),
                Text(
                  'Answering as ITEL Staff',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0056AC),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _answerController,
                  focusNode: _answerFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Write your official answer...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFF0056AC)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 4,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0056AC),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitAnswer(question),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),

// Info message for regular users (non-staff, non-guest)
if (!isGuest && !isStaff)
  Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      border: Border(
        top: BorderSide(color: Colors.blue[200]!),
      ),
    ),
    child: SafeArea(
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Questions are answered by ITEL experts',
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    ),
  ),

// Guest prompt
if (isGuest)
  Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.orange[50],
      border: Border(
        top: BorderSide(color: Colors.orange[200]!),
      ),
    ),
    child: SafeArea(
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sign in to ask questions to ITEL experts',
              style: TextStyle(color: Colors.orange[700]),
            ),
          ),
        ],
      ),
    ),
  ),
```

---

## PART 8: UPDATE FORUM ANSWER CARD

### File: `lib/widgets/forum_answer_card.dart`

**REPLACE** the badges section at the start of the Column children:

```dart
child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Badges row (Staff + Accepted)
    Row(
      children: [
        // ITEL Staff badge
        if (answer.isStaffAnswer)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8, bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0056AC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'ITEL Staff',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        // Accepted badge
        if (answer.isAccepted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Accepted Answer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),

    // Content
    Text(
```

---

## PART 9: UPDATE FORUM CREATE QUESTION SCREEN

### File: `lib/screens/forum_create_question_screen.dart`

**CHANGE** AppBar title:

```dart
appBar: AppBar(
  title: const Text('Ask ITEL'),
```

**CHANGE** success message:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Question submitted! It will be visible after review.'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 4),
  ),
);
```

**ADD** info note before submit button:

```dart
const SizedBox(height: 24),

// Info note about moderation
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue[200]!),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Your question will be reviewed before it appears publicly. ITEL staff will answer your question.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue[700],
            ),
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 16),

// Submit button
```

**CHANGE** submit button text:

```dart
: const Text(
    'Submit Question',
    style: TextStyle(
```

---

## PART 10: FIRESTORE INDEX (IMPORTANT!)

After deploying, you may see an error about missing index.

**Create Composite Index in Firebase Console:**

1. Go to Firebase Console > Firestore Database > Indexes
2. Click "Create Index"
3. Settings:
   - Collection ID: `forum_questions`
   - Fields:
     - `approvalStatus` - Ascending
     - `createdAt` - Descending
4. Click Create

Or click the link in the error message - it auto-creates the index.

---

## PART 11: FIREBASE DATA STRUCTURE

### To approve a question (in Firebase Console):
1. Go to Firestore > `forum_questions` collection
2. Find the question document
3. Change `approvalStatus` from `"pending"` to `"approved"`

### To make someone ITEL staff (in Firebase Console):
1. Go to Firestore > `users` collection
2. Find the user document
3. Add field: `role` with value `"staff"`

---

## TESTING CHECKLIST

- [ ] Questions show as "pending" by default
- [ ] Only approved questions appear in the public list
- [ ] Regular users see "Questions are answered by ITEL experts" message
- [ ] Staff users see answer input with "Answering as ITEL Staff" badge
- [ ] Staff answers show "ITEL Staff" badge
- [ ] Question submission shows moderation info message
- [ ] Tab renamed to "Ask ITEL"
- [ ] Role loads correctly from Firebase

---

## FILES MODIFIED SUMMARY

| File | Changes |
|------|---------|
| `lib/models/user.dart` | Added UserRole enum, role field, helper methods |
| `lib/models/forum_question.dart` | Added ApprovalStatus enum, approvalStatus field |
| `lib/models/forum_answer.dart` | Added isStaffAnswer field |
| `lib/services/forum_service.dart` | Added approval streams, staff-only answers |
| `lib/services/auth_service.dart` | Load role from Firebase |
| `lib/screens/community_screen.dart` | Renamed to Ask ITEL, use approved stream |
| `lib/screens/forum_question_detail_screen.dart` | Staff-only answer input |
| `lib/screens/forum_create_question_screen.dart` | Updated messaging |
| `lib/widgets/forum_answer_card.dart` | Added ITEL Staff badge |

---

Copy this entire guide to Claude Code on your Mac and it will implement the same changes!
