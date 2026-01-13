# Complete Community Feature Implementation (Forum Q&A + Global Chat)

Copy and paste this entire prompt to Claude Code on your Mac:

---

I want to implement a **Community** feature for my Flutter app with two sub-features:

## Feature 1: Forum Q&A
- View a list of questions posted by other users
- Create new questions with title, description, and tags
- Answer questions posted by others
- Accept answers (only question author can accept)
- Filter questions by status (All, Open, Resolved)
- Real-time updates when new questions/answers are posted

## Feature 2: Global Chat
- Real-time chat room where all users can send messages
- See messages from everyone in real-time
- Delete own messages (long-press)
- Message bubbles with avatars and timestamps

## App Context:

My Flutter app uses:
- **Firebase Authentication** (email/password + Google Sign-In)
- **Firestore** for data storage
- **Provider** for state management
- User has a static singleton: `User.currentUser`
- Bottom navigation with 5 tabs (Home, Courses, Trending, About, Profile)

---

## PART 1: FORUM Q&A MODELS

### 1.1 Create ForumQuestion Model

Create file: `lib/models/forum_question.dart`
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionStatus {
  open,
  resolved,
}

class ForumQuestion {
  final String id;
  final String authorId;
  final String authorName;
  final String authorEmail;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int answerCount;
  final QuestionStatus status;
  final String? acceptedAnswerId;

  ForumQuestion({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    required this.title,
    required this.content,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.answerCount = 0,
    this.status = QuestionStatus.open,
    this.acceptedAnswerId,
  });

  factory ForumQuestion.fromJson(Map<String, dynamic> json, String id) {
    return ForumQuestion(
      id: id,
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Unknown',
      authorEmail: json['authorEmail'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      answerCount: json['answerCount'] as int? ?? 0,
      status: _stringToStatus(json['status'] as String? ?? 'open'),
      acceptedAnswerId: json['acceptedAnswerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'title': title,
      'content': content,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'answerCount': answerCount,
      'status': _statusToString(status),
      'acceptedAnswerId': acceptedAnswerId,
    };
  }

  ForumQuestion copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorEmail,
    String? title,
    String? content,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? answerCount,
    QuestionStatus? status,
    String? acceptedAnswerId,
  }) {
    return ForumQuestion(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      answerCount: answerCount ?? this.answerCount,
      status: status ?? this.status,
      acceptedAnswerId: acceptedAnswerId ?? this.acceptedAnswerId,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  static QuestionStatus _stringToStatus(String statusString) {
    switch (statusString) {
      case 'resolved':
        return QuestionStatus.resolved;
      case 'open':
      default:
        return QuestionStatus.open;
    }
  }

  static String _statusToString(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.resolved:
        return 'resolved';
      case QuestionStatus.open:
        return 'open';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForumQuestion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
```

### 1.2 Create ForumAnswer Model

Create file: `lib/models/forum_answer.dart`
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ForumAnswer {
  final String id;
  final String questionId;
  final String authorId;
  final String authorName;
  final String authorEmail;
  final String content;
  final DateTime createdAt;
  final bool isAccepted;

  ForumAnswer({
    required this.id,
    required this.questionId,
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    required this.content,
    required this.createdAt,
    this.isAccepted = false,
  });

  factory ForumAnswer.fromJson(Map<String, dynamic> json, String id) {
    return ForumAnswer(
      id: id,
      questionId: json['questionId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Unknown',
      authorEmail: json['authorEmail'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      isAccepted: json['isAccepted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAccepted': isAccepted,
    };
  }

  ForumAnswer copyWith({
    String? id,
    String? questionId,
    String? authorId,
    String? authorName,
    String? authorEmail,
    String? content,
    DateTime? createdAt,
    bool? isAccepted,
  }) {
    return ForumAnswer(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForumAnswer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
```

---

## PART 2: CHAT MODEL

### 2.1 Create ChatMessage Model

Create file: `lib/models/chat_message.dart`
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String authorId;
  final String authorName;
  final String authorEmail;
  final String content;
  final DateTime createdAt;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    required this.content,
    required this.createdAt,
    this.type = MessageType.text,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String id) {
    return ChatMessage(
      id: id,
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? 'Unknown',
      authorEmail: json['authorEmail'] ?? '',
      content: json['content'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type.name,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorEmail,
    String? content,
    DateTime? createdAt,
    MessageType? type,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }

  bool isFromUser(String userId) => authorId == userId;
}

enum MessageType {
  text,
  system,
}
```

---

## PART 3: SERVICES

### 3.1 Create ForumService

Create file: `lib/services/forum_service.dart`
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/forum_question.dart';
import '../models/forum_answer.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _questionsCollection =>
      _firestore.collection('forum_questions');

  CollectionReference _answersCollection(String questionId) =>
      _questionsCollection.doc(questionId).collection('answers');

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

  Stream<ForumQuestion?> getQuestionStream(String questionId) {
    return _questionsCollection.doc(questionId).snapshots().map((doc) {
      if (doc.exists) {
        return ForumQuestion.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    });
  }

  Future<String> createQuestion({
    required String authorId,
    required String authorName,
    required String authorEmail,
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
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
    });
    return docRef.id;
  }

  Stream<List<ForumAnswer>> getAnswersStream(String questionId) {
    return _answersCollection(questionId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ForumAnswer.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<String> createAnswer({
    required String questionId,
    required String authorId,
    required String authorName,
    required String authorEmail,
    required String content,
  }) async {
    final batch = _firestore.batch();

    final answerRef = _answersCollection(questionId).doc();
    batch.set(answerRef, {
      'questionId': questionId,
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'content': content,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'isAccepted': false,
    });

    final questionRef = _questionsCollection.doc(questionId);
    batch.update(questionRef, {
      'answerCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return answerRef.id;
  }

  Future<void> acceptAnswer({
    required String questionId,
    required String answerId,
    required String currentUserId,
  }) async {
    final questionDoc = await _questionsCollection.doc(questionId).get();
    if (!questionDoc.exists) {
      throw Exception('Question not found');
    }

    final questionData = questionDoc.data() as Map<String, dynamic>;
    if (questionData['authorId'] != currentUserId) {
      throw Exception('Only the question author can accept an answer');
    }

    final batch = _firestore.batch();

    final previousAcceptedId = questionData['acceptedAnswerId'] as String?;
    if (previousAcceptedId != null && previousAcceptedId.isNotEmpty) {
      final previousAnswerRef =
          _answersCollection(questionId).doc(previousAcceptedId);
      batch.update(previousAnswerRef, {'isAccepted': false});
    }

    final answerRef = _answersCollection(questionId).doc(answerId);
    batch.update(answerRef, {'isAccepted': true});

    batch.update(_questionsCollection.doc(questionId), {
      'acceptedAnswerId': answerId,
      'status': 'resolved',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
```

### 3.2 Create ChatService

Create file: `lib/services/chat_service.dart`
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _globalChatRef =>
      _firestore.collection('global_chat');

  Stream<List<ChatMessage>> getMessagesStream({int limit = 100}) {
    return _globalChatRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<void> sendMessage({
    required String authorId,
    required String authorName,
    required String authorEmail,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final message = ChatMessage(
      id: '',
      authorId: authorId,
      authorName: authorName,
      authorEmail: authorEmail,
      content: content.trim(),
      createdAt: DateTime.now(),
      type: type,
    );

    await _globalChatRef.add(message.toJson());
  }

  Future<void> deleteMessage({
    required String messageId,
    required String currentUserId,
  }) async {
    final doc = await _globalChatRef.doc(messageId).get();
    if (!doc.exists) {
      throw Exception('Message not found');
    }

    final data = doc.data() as Map<String, dynamic>;
    if (data['authorId'] != currentUserId) {
      throw Exception('You can only delete your own messages');
    }

    await _globalChatRef.doc(messageId).delete();
  }
}
```

---

## PART 4: WIDGETS

### 4.1 Create ForumQuestionCard Widget

Create file: `lib/widgets/forum_question_card.dart`
```dart
import 'package:flutter/material.dart';
import '../models/forum_question.dart';

class ForumQuestionCard extends StatelessWidget {
  final ForumQuestion question;
  final VoidCallback onTap;

  const ForumQuestionCard({
    super.key,
    required this.question,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: question.status == QuestionStatus.resolved
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        question.status == QuestionStatus.resolved
                            ? Icons.check_circle
                            : Icons.help_outline,
                        size: 12,
                        color: question.status == QuestionStatus.resolved
                            ? Colors.green
                            : const Color(0xFFFF6600),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        question.status == QuestionStatus.resolved
                            ? 'Resolved'
                            : 'Open',
                        style: TextStyle(
                          color: question.status == QuestionStatus.resolved
                              ? Colors.green
                              : const Color(0xFFFF6600),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${question.answerCount} ${question.answerCount == 1 ? 'answer' : 'answers'}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              question.content,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            if (question.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: question.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF0056AC)),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFF0056AC),
                  child: Text(
                    question.authorName.isNotEmpty
                        ? question.authorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.authorName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatDate(question.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

### 4.2 Create ForumAnswerCard Widget

Create file: `lib/widgets/forum_answer_card.dart`
```dart
import 'package:flutter/material.dart';
import '../models/forum_answer.dart';

class ForumAnswerCard extends StatelessWidget {
  final ForumAnswer answer;
  final bool isQuestionAuthor;
  final VoidCallback? onAccept;

  const ForumAnswerCard({
    super.key,
    required this.answer,
    required this.isQuestionAuthor,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: answer.isAccepted ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: answer.isAccepted ? Colors.green[300]! : Colors.grey[200]!,
          width: answer.isAccepted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text(
            answer.content,
            style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF0056AC),
                child: Text(
                  answer.authorName.isNotEmpty
                      ? answer.authorName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answer.authorName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _formatDate(answer.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              if (isQuestionAuthor && !answer.isAccepted && onAccept != null)
                TextButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check, size: 16, color: Colors.green),
                  label: const Text('Accept', style: TextStyle(color: Colors.green)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

### 4.3 Create ChatMessageBubble Widget

Create file: `lib/widgets/chat_message_bubble.dart`
```dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onDelete,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return _buildSystemMessage();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _getAvatarColor(message.authorName),
              child: Text(
                message.authorName.isNotEmpty
                    ? message.authorName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrentUser ? const Color(0xFF0056AC) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                    bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          message.authorName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getAvatarColor(message.authorName),
                          ),
                        ),
                      ),
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: isCurrentUser ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrentUser
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF0056AC).withOpacity(0.2),
              child: Text(
                message.authorName.isNotEmpty
                    ? message.authorName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF0056AC),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF0056AC),
      const Color(0xFFFF6600),
      const Color(0xFF4CAF50),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFFFF5722),
      const Color(0xFF3F51B5),
    ];
    if (name.isEmpty) return colors[0];
    final index = name.codeUnitAt(0) % colors.length;
    return colors[index];
  }
}
```

---

## PART 5: SCREENS

### 5.1 Create ForumCreateQuestionScreen

Create file: `lib/screens/forum_create_question_screen.dart`
```dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/forum_service.dart';

class ForumCreateQuestionScreen extends StatefulWidget {
  const ForumCreateQuestionScreen({super.key});

  @override
  State<ForumCreateQuestionScreen> createState() =>
      _ForumCreateQuestionScreenState();
}

class _ForumCreateQuestionScreenState extends State<ForumCreateQuestionScreen> {
  final ForumService _forumService = ForumService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];
  bool _isSubmitting = false;

  final List<String> _suggestedTags = [
    'Course Help', 'Technical', 'Career', 'Certification',
    'Study Tips', 'Networking', 'Security', 'Programming', 'Cloud', 'Data',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag) && _tags.length < 5) {
      setState(() => _tags.add(trimmedTag));
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = User.currentUser;
    if (currentUser.id.isEmpty || currentUser.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to ask a question'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _forumService.createQuestion(
        authorId: currentUser.id,
        authorName: currentUser.name,
        authorEmail: currentUser.email,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: _tags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question posted successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting question: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Ask a Question'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitQuestion,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Post', style: TextStyle(color: Color(0xFF0056AC), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'What is your question about?',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter a title';
                        if (value.trim().length < 10) return 'Title must be at least 10 characters';
                        return null;
                      },
                      maxLength: 100,
                    ),
                    const SizedBox(height: 16),
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        hintText: 'Describe your question in detail...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter a description';
                        if (value.trim().length < 20) return 'Description must be at least 20 characters';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      Text('(up to 5)', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0056AC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(tag, style: const TextStyle(color: Colors.white, fontSize: 13)),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _removeTag(tag),
                                child: const Icon(Icons.close, size: 16, color: Colors.white70),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_tags.length < 5)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            decoration: InputDecoration(
                              hintText: 'Add a tag',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            onSubmitted: _addTag,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0056AC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () => _addTag(_tagController.text),
                            icon: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Text('Suggested tags:', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestedTags.where((tag) => !_tags.contains(tag)).take(8).map((tag) {
                      return GestureDetector(
                        onTap: () => _addTag(tag),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(tag, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056AC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Post Question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
```

### 5.2 Create ForumQuestionDetailScreen

Create file: `lib/screens/forum_question_detail_screen.dart`
```dart
import 'package:flutter/material.dart';
import '../models/forum_question.dart';
import '../models/forum_answer.dart';
import '../models/user.dart';
import '../services/forum_service.dart';
import '../widgets/forum_answer_card.dart';

class ForumQuestionDetailScreen extends StatefulWidget {
  final String questionId;

  const ForumQuestionDetailScreen({
    super.key,
    required this.questionId,
  });

  @override
  State<ForumQuestionDetailScreen> createState() =>
      _ForumQuestionDetailScreenState();
}

class _ForumQuestionDetailScreenState extends State<ForumQuestionDetailScreen> {
  final ForumService _forumService = ForumService();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer(ForumQuestion question) async {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;

    if (isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to answer questions'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your answer'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _forumService.createAnswer(
        questionId: widget.questionId,
        authorId: currentUser.id,
        authorName: currentUser.name,
        authorEmail: currentUser.email,
        content: _answerController.text.trim(),
      );
      _answerController.clear();
      _answerFocusNode.unfocus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer posted successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting answer: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _acceptAnswer(String answerId) async {
    try {
      await _forumService.acceptAnswer(
        questionId: widget.questionId,
        answerId: answerId,
        currentUserId: User.currentUser.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer accepted!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Question'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<ForumQuestion?>(
        stream: _forumService.getQuestionStream(widget.questionId),
        builder: (context, questionSnapshot) {
          if (questionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final question = questionSnapshot.data;
          if (question == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Question not found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
                ],
              ),
            );
          }

          final isAuthor = currentUser.id == question.authorId;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: question.status == QuestionStatus.resolved ? Colors.green[50] : Colors.orange[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        question.status == QuestionStatus.resolved ? Icons.check_circle : Icons.help_outline,
                                        size: 14,
                                        color: question.status == QuestionStatus.resolved ? Colors.green : const Color(0xFFFF6600),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        question.status == QuestionStatus.resolved ? 'Resolved' : 'Open',
                                        style: TextStyle(
                                          color: question.status == QuestionStatus.resolved ? Colors.green : const Color(0xFFFF6600),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(_formatDate(question.createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(question.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(question.content, style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.6)),
                            const SizedBox(height: 16),
                            if (question.tags.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: question.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                                    child: Text(tag, style: const TextStyle(fontSize: 12, color: Color(0xFF0056AC))),
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF0056AC),
                                  child: Text(
                                    question.authorName.isNotEmpty ? question.authorName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(question.authorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    Text('Asked ${_formatDate(question.createdAt)}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text('Answers', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF0056AC), borderRadius: BorderRadius.circular(12)),
                            child: Text('${question.answerCount}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<ForumAnswer>>(
                        stream: _forumService.getAnswersStream(widget.questionId),
                        builder: (context, answersSnapshot) {
                          if (answersSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                          }

                          final answers = answersSnapshot.data ?? [];

                          if (answers.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text('No answers yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600])),
                                    const SizedBox(height: 4),
                                    Text('Be the first to help!', style: TextStyle(color: Colors.grey[500])),
                                  ],
                                ),
                              ),
                            );
                          }

                          final sortedAnswers = List<ForumAnswer>.from(answers);
                          sortedAnswers.sort((a, b) {
                            if (a.isAccepted && !b.isAccepted) return -1;
                            if (!a.isAccepted && b.isAccepted) return 1;
                            return a.createdAt.compareTo(b.createdAt);
                          });

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sortedAnswers.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final answer = sortedAnswers[index];
                              return ForumAnswerCard(
                                answer: answer,
                                isQuestionAuthor: isAuthor,
                                onAccept: isAuthor && !answer.isAccepted && question.status != QuestionStatus.resolved
                                    ? () => _acceptAnswer(answer.id)
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              if (!isGuest)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
                  ),
                  child: SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _answerController,
                            focusNode: _answerFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Write your answer...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            maxLines: 4,
                            minLines: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(color: const Color(0xFF0056AC), borderRadius: BorderRadius.circular(24)),
                          child: IconButton(
                            onPressed: _isSubmitting ? null : () => _submitAnswer(question),
                            icon: _isSubmitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (isGuest)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.orange[50], border: Border(top: BorderSide(color: Colors.orange[200]!))),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Sign in to answer this question', style: TextStyle(color: Colors.orange[700]))),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

### 5.3 Create GlobalChatScreen

Create file: `lib/screens/global_chat_screen.dart`
```dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../widgets/chat_message_bubble.dart';

class GlobalChatScreen extends StatefulWidget {
  const GlobalChatScreen({super.key});

  @override
  State<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends State<GlobalChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;

    if (isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to send messages'), backgroundColor: Colors.orange),
      );
      return;
    }

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(
        authorId: currentUser.id,
        authorName: currentUser.name,
        authorEmail: currentUser.email,
        content: content,
      );
      _messageController.clear();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final currentUser = User.currentUser;

    if (message.authorId != currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own messages'), backgroundColor: Colors.orange),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _chatService.deleteMessage(messageId: message.id, currentUserId: currentUser.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message deleted'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: _chatService.getMessagesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final messages = snapshot.data ?? [];

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No messages yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Be the first to say hello!', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isCurrentUser = message.authorId == currentUser.id;

                  return ChatMessageBubble(
                    message: message,
                    isCurrentUser: isCurrentUser,
                    onLongPress: isCurrentUser ? () => _deleteMessage(message) : null,
                  );
                },
              );
            },
          ),
        ),
        if (!isGuest)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0056AC),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (isGuest)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border(top: BorderSide(color: Colors.orange[200]!)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Sign in to join the conversation', style: TextStyle(color: Colors.orange[700]))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
```

### 5.4 Create CommunityScreen (Main Screen with Tabs)

Create file: `lib/screens/community_screen.dart`
```dart
import 'package:flutter/material.dart';
import '../models/forum_question.dart';
import '../models/user.dart';
import '../services/forum_service.dart';
import '../widgets/forum_question_card.dart';
import 'forum_question_detail_screen.dart';
import 'forum_create_question_screen.dart';
import 'global_chat_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ForumService _forumService = ForumService();
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Row(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.1,
                    height: MediaQuery.of(context).size.width * 0.1,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Image.asset('assets/images/itel.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Community', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Connect, ask, and share knowledge', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      if (_tabController.index == 0) {
                        return PopupMenuButton<String>(
                          icon: Icon(Icons.filter_list, color: _filterStatus != 'all' ? const Color(0xFF0056AC) : Colors.grey[600]),
                          onSelected: (value) => setState(() => _filterStatus = value),
                          itemBuilder: (context) => [
                            _buildFilterItem('all', 'All Questions', Icons.list),
                            _buildFilterItem('open', 'Open', Icons.help_outline),
                            _buildFilterItem('resolved', 'Resolved', Icons.check_circle),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            // Tab bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF0056AC),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF0056AC),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                tabs: const [
                  Tab(icon: Icon(Icons.forum, size: 20), text: 'Q&A Forum'),
                  Tab(icon: Icon(Icons.chat, size: 20), text: 'Global Chat'),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildForumTab(isGuest),
                  const GlobalChatScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          if (_tabController.index == 0 && !isGuest) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ForumCreateQuestionScreen()));
              },
              backgroundColor: const Color(0xFF0056AC),
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  PopupMenuItem<String> _buildFilterItem(String value, String label, IconData icon) {
    Color iconColor;
    if (value == 'open') {
      iconColor = _filterStatus == 'open' ? const Color(0xFFFF6600) : Colors.grey;
    } else if (value == 'resolved') {
      iconColor = _filterStatus == 'resolved' ? Colors.green : Colors.grey;
    } else {
      iconColor = _filterStatus == 'all' ? const Color(0xFF0056AC) : Colors.grey;
    }
    return PopupMenuItem(value: value, child: Row(children: [Icon(icon, size: 18, color: iconColor), const SizedBox(width: 8), Text(label)]));
  }

  Widget _buildForumTab(bool isGuest) {
    return Column(
      children: [
        if (_filterStatus != 'all')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _filterStatus == 'open' ? Colors.orange[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _filterStatus == 'open' ? Colors.orange[200]! : Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_filterStatus == 'open' ? Icons.help_outline : Icons.check_circle, size: 14,
                          color: _filterStatus == 'open' ? const Color(0xFFFF6600) : Colors.green),
                      const SizedBox(width: 4),
                      Text('Showing: ${_filterStatus == 'open' ? 'Open' : 'Resolved'}',
                          style: TextStyle(fontSize: 12, color: _filterStatus == 'open' ? const Color(0xFFFF6600) : Colors.green, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _filterStatus = 'all'),
                        child: Icon(Icons.close, size: 14, color: _filterStatus == 'open' ? const Color(0xFFFF6600) : Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<List<ForumQuestion>>(
            stream: _forumService.getQuestionsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              var questions = snapshot.data ?? [];

              if (_filterStatus == 'open') {
                questions = questions.where((q) => q.status == QuestionStatus.open).toList();
              } else if (_filterStatus == 'resolved') {
                questions = questions.where((q) => q.status == QuestionStatus.resolved).toList();
              }

              if (questions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(_filterStatus == 'all' ? 'No questions yet' : 'No $_filterStatus questions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView.separated(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  itemCount: questions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return ForumQuestionCard(
                      question: question,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ForumQuestionDetailScreen(questionId: question.id)));
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

---

## PART 6: UPDATE main.dart

Make these changes to `lib/main.dart`:

**1. Change the import (replace forum_screen with community_screen):**
```dart
// Change this:
import 'screens/forum_screen.dart';
// To this:
import 'screens/community_screen.dart';
```

**2. Update screens list (replace ForumScreen with CommunityScreen):**
```dart
// Change this:
const ForumScreen(),
// To this:
const CommunityScreen(),
```

**3. Update bottom navigation item (change Forum to Community):**
```dart
// Change this:
BottomNavigationBarItem(
  icon: Icon(Icons.forum),
  label: 'Forum',
),
// To this:
BottomNavigationBarItem(
  icon: Icon(Icons.people),
  label: 'Community',
),
```

---

## PART 7: FIRESTORE SECURITY RULES

Go to Firebase Console → Firestore Database → Rules and set:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection (KEEP YOUR EXISTING RULES)
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /enrolledCourses/{courseId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Forum Q&A
    match /forum_questions/{questionId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null && resource.data.authorId == request.auth.uid;

      match /answers/{answerId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow update: if request.auth != null;
        allow delete: if request.auth != null && resource.data.authorId == request.auth.uid;
      }
    }

    // Global Chat
    match /global_chat/{messageId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null && resource.data.authorId == request.auth.uid;
      allow delete: if request.auth != null && resource.data.authorId == request.auth.uid;
    }
  }
}
```

Click **Publish** to save.

---

## FILES SUMMARY

### New Files to Create (10 files):

| File | Purpose |
|------|---------|
| `lib/models/forum_question.dart` | Question model |
| `lib/models/forum_answer.dart` | Answer model |
| `lib/models/chat_message.dart` | Chat message model |
| `lib/services/forum_service.dart` | Forum Firestore operations |
| `lib/services/chat_service.dart` | Chat Firestore operations |
| `lib/widgets/forum_question_card.dart` | Question card widget |
| `lib/widgets/forum_answer_card.dart` | Answer card widget |
| `lib/widgets/chat_message_bubble.dart` | Chat bubble widget |
| `lib/screens/forum_create_question_screen.dart` | Create question form |
| `lib/screens/forum_question_detail_screen.dart` | Question detail view |
| `lib/screens/global_chat_screen.dart` | Global chat interface |
| `lib/screens/community_screen.dart` | Main community screen with tabs |

### Files to Modify (1 file):
| File | Changes |
|------|---------|
| `lib/main.dart` | Import community_screen, use CommunityScreen, update nav item |

---

## TESTING CHECKLIST

- [ ] Community tab appears in navigation
- [ ] Two tabs visible: "Q&A Forum" and "Global Chat"
- [ ] Q&A Forum loads questions with real-time updates
- [ ] Filter works (All/Open/Resolved)
- [ ] Can create new questions
- [ ] Can view question details
- [ ] Can post answers
- [ ] Question author can accept answer
- [ ] Global Chat loads messages in real-time
- [ ] Can send chat messages
- [ ] Can delete own messages (long-press)
- [ ] Guest users can view but not post
- [ ] Message bubbles show avatars and timestamps

---

## UI COLORS
- Primary Blue: `Color(0xFF0056AC)`
- Orange Accent: `Color(0xFFFF6600)`
- Green (Resolved): `Colors.green`
- Card Background: `Colors.white`
- Page Background: `Colors.grey[100]`

Please implement exactly as described!
