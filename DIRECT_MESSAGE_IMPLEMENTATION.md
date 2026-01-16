# Direct Message (DM) Feature Implementation Guide

This guide documents the complete implementation of a Direct Message feature for the ITEL Flutter app.

## Features Implemented
- Messages icon in Community header with unread count badge
- Tap on users in Global Chat to start DM
- Tap on question/answer authors in Forum to start DM
- Full chat features: send/receive messages, delete own messages
- Read receipts, typing indicators, online status
- Conversation list with unread badges

---

## PART 1: CREATE NEW MODEL FILES

### File 1: `lib/models/conversation.dart` (CREATE NEW FILE)

```dart
// lib/models/conversation.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents participant details stored in a conversation
class ParticipantInfo {
  final String name;
  final String email;
  final String? profileImage;

  ParticipantInfo({
    required this.name,
    required this.email,
    this.profileImage,
  });

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      profileImage: json['profileImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'profileImage': profileImage,
    };
  }
}

/// Represents the last message in a conversation (denormalized for quick display)
class LastMessageInfo {
  final String content;
  final String senderId;
  final DateTime createdAt;

  LastMessageInfo({
    required this.content,
    required this.senderId,
    required this.createdAt,
  });

  factory LastMessageInfo.fromJson(Map<String, dynamic> json) {
    return LastMessageInfo(
      content: json['content'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'senderId': senderId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }
}

/// Represents a direct message conversation between two users
class Conversation {
  final String id;
  final List<String> participants;
  final Map<String, ParticipantInfo> participantDetails;
  final LastMessageInfo? lastMessage;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, DateTime> readBy;
  final Map<String, int> unreadCount;

  Conversation({
    required this.id,
    required this.participants,
    required this.participantDetails,
    this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.readBy = const {},
    this.unreadCount = const {},
  });

  factory Conversation.fromJson(Map<String, dynamic> json, String id) {
    // Parse participant details
    final participantDetailsJson = json['participantDetails'] as Map<String, dynamic>? ?? {};
    final participantDetails = <String, ParticipantInfo>{};
    participantDetailsJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        participantDetails[key] = ParticipantInfo.fromJson(value);
      }
    });

    // Parse readBy timestamps
    final readByJson = json['readBy'] as Map<String, dynamic>? ?? {};
    final readBy = <String, DateTime>{};
    readByJson.forEach((key, value) {
      readBy[key] = _parseTimestamp(value);
    });

    // Parse unread counts
    final unreadCountJson = json['unreadCount'] as Map<String, dynamic>? ?? {};
    final unreadCount = <String, int>{};
    unreadCountJson.forEach((key, value) {
      unreadCount[key] = (value as num?)?.toInt() ?? 0;
    });

    return Conversation(
      id: id,
      participants: List<String>.from(json['participants'] ?? []),
      participantDetails: participantDetails,
      lastMessage: json['lastMessage'] != null
          ? LastMessageInfo.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      lastMessageAt: _parseTimestamp(json['lastMessageAt']),
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      readBy: readBy,
      unreadCount: unreadCount,
    );
  }

  Map<String, dynamic> toJson() {
    final participantDetailsJson = <String, dynamic>{};
    participantDetails.forEach((key, value) {
      participantDetailsJson[key] = value.toJson();
    });

    final readByJson = <String, dynamic>{};
    readBy.forEach((key, value) {
      readByJson[key] = Timestamp.fromDate(value);
    });

    return {
      'participants': participants,
      'participantDetails': participantDetailsJson,
      'lastMessage': lastMessage?.toJson(),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'readBy': readByJson,
      'unreadCount': unreadCount,
    };
  }

  Conversation copyWith({
    String? id,
    List<String>? participants,
    Map<String, ParticipantInfo>? participantDetails,
    LastMessageInfo? lastMessage,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, DateTime>? readBy,
    Map<String, int>? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantDetails: participantDetails ?? this.participantDetails,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readBy: readBy ?? this.readBy,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  /// Get the other participant's info (not the current user)
  ParticipantInfo? getOtherParticipant(String currentUserId) {
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return otherUserId.isNotEmpty ? participantDetails[otherUserId] : null;
  }

  /// Get the other participant's ID
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Get unread count for a specific user
  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// Check if conversation has been read by user
  bool isReadByUser(String userId) {
    return getUnreadCountForUser(userId) == 0;
  }

  /// Check if the last message is from the current user
  bool isLastMessageFromUser(String userId) {
    return lastMessage?.senderId == userId;
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
    return other is Conversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
```

---

### File 2: `lib/models/direct_message.dart` (CREATE NEW FILE)

```dart
// lib/models/direct_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Message type for direct messages
enum DirectMessageType {
  text,
  system, // For "conversation started" notifications
}

/// Represents a single message in a direct message conversation
class DirectMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String content;
  final DateTime createdAt;
  final DirectMessageType type;
  final DateTime? readAt;
  final DateTime? deletedAt;
  final String? deletedBy;

  DirectMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.content,
    required this.createdAt,
    this.type = DirectMessageType.text,
    this.readAt,
    this.deletedAt,
    this.deletedBy,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json, String id) {
    return DirectMessage(
      id: id,
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderEmail: json['senderEmail'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      type: DirectMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DirectMessageType.text,
      ),
      readAt: json['readAt'] != null ? _parseTimestamp(json['readAt']) : null,
      deletedAt: json['deletedAt'] != null ? _parseTimestamp(json['deletedAt']) : null,
      deletedBy: json['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type.name,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy,
    };
  }

  DirectMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? content,
    DateTime? createdAt,
    DirectMessageType? type,
    DateTime? readAt,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return DirectMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      readAt: readAt ?? this.readAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  /// Check if this message is from a specific user
  bool isFromUser(String userId) => senderId == userId;

  /// Check if the message has been read
  bool get isRead => readAt != null;

  /// Check if the message has been deleted
  bool get isDeleted => deletedAt != null;

  /// Get the display content (shows placeholder if deleted)
  String get displayContent {
    if (isDeleted) {
      return 'This message was deleted';
    }
    return content;
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
    return other is DirectMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
```

---

### File 3: `lib/models/user_presence.dart` (CREATE NEW FILE)

```dart
// lib/models/user_presence.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents typing status for a specific conversation
class TypingStatus {
  final bool isTyping;
  final DateTime updatedAt;

  TypingStatus({
    required this.isTyping,
    required this.updatedAt,
  });

  factory TypingStatus.fromJson(Map<String, dynamic> json) {
    return TypingStatus(
      isTyping: json['isTyping'] as bool? ?? false,
      updatedAt: _parseTimestamp(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isTyping': isTyping,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Check if typing status is still valid (not stale)
  /// Typing indicators older than 5 seconds are considered stale
  bool get isValid {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    return diff.inSeconds < 5 && isTyping;
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }
}

/// Represents user's online presence and typing status
class UserPresence {
  final String userId;
  final bool isOnline;
  final DateTime lastSeen;
  final Map<String, TypingStatus> typing;

  UserPresence({
    required this.userId,
    required this.isOnline,
    required this.lastSeen,
    this.typing = const {},
  });

  factory UserPresence.fromJson(Map<String, dynamic> json, String id) {
    // Parse typing status map
    final typingJson = json['typing'] as Map<String, dynamic>? ?? {};
    final typing = <String, TypingStatus>{};
    typingJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        typing[key] = TypingStatus.fromJson(value);
      }
    });

    return UserPresence(
      userId: id,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: _parseTimestamp(json['lastSeen']),
      typing: typing,
    );
  }

  Map<String, dynamic> toJson() {
    final typingJson = <String, dynamic>{};
    typing.forEach((key, value) {
      typingJson[key] = value.toJson();
    });

    return {
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'typing': typingJson,
    };
  }

  UserPresence copyWith({
    String? userId,
    bool? isOnline,
    DateTime? lastSeen,
    Map<String, TypingStatus>? typing,
  }) {
    return UserPresence(
      userId: userId ?? this.userId,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      typing: typing ?? this.typing,
    );
  }

  /// Check if user is currently typing in a specific conversation
  bool isTypingIn(String conversationId) {
    final status = typing[conversationId];
    return status?.isValid ?? false;
  }

  /// Get a human-readable last seen text
  String getLastSeenText() {
    if (isOnline) {
      return 'Online';
    }

    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.inMinutes < 1) {
      return 'Last seen just now';
    } else if (diff.inMinutes < 60) {
      return 'Last seen ${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return 'Last seen ${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return 'Last seen ${diff.inDays}d ago';
    } else {
      return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  /// Create a default offline presence
  static UserPresence offline(String userId) {
    return UserPresence(
      userId: userId,
      isOnline: false,
      lastSeen: DateTime.now(),
      typing: {},
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
    return other is UserPresence && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
```

---

## PART 2: CREATE NEW SERVICE FILE

### File 4: `lib/services/direct_message_service.dart` (CREATE NEW FILE)

```dart
// lib/services/direct_message_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation.dart';
import '../models/direct_message.dart';
import '../models/user_presence.dart';

class DirectMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _conversationsRef =>
      _firestore.collection('direct_messages');

  CollectionReference get _presenceRef =>
      _firestore.collection('user_presence');

  CollectionReference _messagesRef(String conversationId) =>
      _conversationsRef.doc(conversationId).collection('messages');

  // ============ CONVERSATION ID GENERATION ============

  /// Generate a consistent conversation ID from two user IDs
  /// IDs are sorted to ensure the same conversation ID regardless of who initiates
  String _generateConversationId(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // ============ CONVERSATIONS ============

  /// Get or create a conversation between two users
  Future<Conversation> getOrCreateConversation({
    required String currentUserId,
    required String currentUserName,
    required String currentUserEmail,
    String? currentUserProfileImage,
    required String otherUserId,
    required String otherUserName,
    required String otherUserEmail,
    String? otherUserProfileImage,
  }) async {
    final conversationId = _generateConversationId(currentUserId, otherUserId);
    final docRef = _conversationsRef.doc(conversationId);
    final doc = await docRef.get();

    if (doc.exists) {
      // Conversation exists, return it
      return Conversation.fromJson(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }

    // Create new conversation
    final now = DateTime.now();
    final participants = [currentUserId, otherUserId]..sort();

    final participantDetails = {
      currentUserId: ParticipantInfo(
        name: currentUserName,
        email: currentUserEmail,
        profileImage: currentUserProfileImage,
      ),
      otherUserId: ParticipantInfo(
        name: otherUserName,
        email: otherUserEmail,
        profileImage: otherUserProfileImage,
      ),
    };

    final conversation = Conversation(
      id: conversationId,
      participants: participants,
      participantDetails: participantDetails,
      lastMessage: null,
      lastMessageAt: now,
      createdAt: now,
      updatedAt: now,
      readBy: {currentUserId: now, otherUserId: now},
      unreadCount: {currentUserId: 0, otherUserId: 0},
    );

    await docRef.set(conversation.toJson());
    print('Created new conversation: $conversationId');

    return conversation;
  }

  /// Stream of conversations for current user (ordered by lastMessageAt)
  Stream<List<Conversation>> getConversationsStream(String userId) {
    return _conversationsRef
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Conversation.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Stream of a single conversation
  Stream<Conversation?> getConversationStream(String conversationId) {
    return _conversationsRef.doc(conversationId).snapshots().map((doc) {
      if (doc.exists) {
        return Conversation.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    });
  }

  /// Get total unread count across all conversations for a user
  Stream<int> getTotalUnreadCountStream(String userId) {
    return _conversationsRef
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final unreadCount = data['unreadCount'] as Map<String, dynamic>? ?? {};
        total += (unreadCount[userId] as num?)?.toInt() ?? 0;
      }
      return total;
    });
  }

  // ============ MESSAGES ============

  /// Stream of messages for a conversation
  Stream<List<DirectMessage>> getMessagesStream(String conversationId, {int limit = 100}) {
    return _messagesRef(conversationId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DirectMessage.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderEmail,
    required String content,
    required String recipientId,
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    // Create the message
    final messageRef = _messagesRef(conversationId).doc();
    final message = DirectMessage(
      id: messageRef.id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderEmail: senderEmail,
      content: content.trim(),
      createdAt: now,
      type: DirectMessageType.text,
    );
    batch.set(messageRef, message.toJson());

    // Update conversation with last message and increment recipient's unread count
    final conversationRef = _conversationsRef.doc(conversationId);
    batch.update(conversationRef, {
      'lastMessage': {
        'content': content.trim(),
        'senderId': senderId,
        'createdAt': Timestamp.fromDate(now),
      },
      'lastMessageAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'unreadCount.$recipientId': FieldValue.increment(1),
    });

    await batch.commit();
    print('Message sent in conversation: $conversationId');
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
    required String currentUserId,
  }) async {
    final messageRef = _messagesRef(conversationId).doc(messageId);
    final doc = await messageRef.get();

    if (!doc.exists) {
      throw Exception('Message not found');
    }

    final data = doc.data() as Map<String, dynamic>;
    if (data['senderId'] != currentUserId) {
      throw Exception('You can only delete your own messages');
    }

    await messageRef.update({
      'deletedAt': Timestamp.fromDate(DateTime.now()),
      'deletedBy': currentUserId,
    });
    print('Message deleted: $messageId');
  }

  /// Mark conversation as read for a user
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    final now = DateTime.now();

    // Update conversation read status and reset unread count
    await _conversationsRef.doc(conversationId).update({
      'readBy.$userId': Timestamp.fromDate(now),
      'unreadCount.$userId': 0,
    });
    print('Marked conversation $conversationId as read for user $userId');
  }

  // ============ PRESENCE & TYPING ============

  /// Update user online status
  Future<void> setOnlineStatus(String userId, bool isOnline) async {
    await _presenceRef.doc(userId).set({
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  /// Set typing indicator for a conversation
  Future<void> setTypingStatus({
    required String userId,
    required String conversationId,
    required bool isTyping,
  }) async {
    await _presenceRef.doc(userId).set({
      'typing.$conversationId': {
        'isTyping': isTyping,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
    }, SetOptions(merge: true));
  }

  /// Stream of user presence
  Stream<UserPresence?> getUserPresenceStream(String userId) {
    return _presenceRef.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserPresence.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return UserPresence.offline(userId);
    });
  }

  /// Stream of typing status for another user in a conversation
  Stream<bool> getTypingStatusStream({
    required String conversationId,
    required String otherUserId,
  }) {
    return _presenceRef.doc(otherUserId).snapshots().map((doc) {
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final typing = data['typing'] as Map<String, dynamic>? ?? {};
      final conversationTyping = typing[conversationId] as Map<String, dynamic>?;

      if (conversationTyping == null) return false;

      final typingStatus = TypingStatus.fromJson(conversationTyping);
      return typingStatus.isValid;
    });
  }

  // ============ HELPERS ============

  /// Check if a conversation exists between two users
  Future<bool> conversationExists(String userId1, String userId2) async {
    final conversationId = _generateConversationId(userId1, userId2);
    final doc = await _conversationsRef.doc(conversationId).get();
    return doc.exists;
  }

  /// Get conversation ID for two users
  String getConversationId(String userId1, String userId2) {
    return _generateConversationId(userId1, userId2);
  }

  /// Delete a conversation (for cleanup - use with caution)
  Future<void> deleteConversation(String conversationId) async {
    // Delete all messages first
    final messages = await _messagesRef(conversationId).get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_conversationsRef.doc(conversationId));
    await batch.commit();
    print('Conversation deleted: $conversationId');
  }
}
```

---

## PART 3: CREATE NEW WIDGET FILES

### File 5: `lib/widgets/direct_message_bubble.dart` (CREATE NEW FILE)

```dart
// lib/widgets/direct_message_bubble.dart
import 'package:flutter/material.dart';
import '../models/direct_message.dart';

class DirectMessageBubble extends StatelessWidget {
  final DirectMessage message;
  final bool isCurrentUser;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  const DirectMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onDelete,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // System message (conversation started, etc.)
    if (message.type == DirectMessageType.system) {
      return _buildSystemMessage();
    }

    // Deleted message
    if (message.isDeleted) {
      return _buildDeletedMessage(context);
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
              backgroundColor: _getAvatarColor(message.senderName),
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
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
                    // Message content
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: isCurrentUser ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Timestamp and read receipt row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isCurrentUser
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey[500],
                          ),
                        ),
                        // Read receipt (only for current user's messages)
                        if (isCurrentUser) ...[
                          const SizedBox(width: 4),
                          _buildReadReceipt(),
                        ],
                      ],
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
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
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

  Widget _buildReadReceipt() {
    if (message.isRead) {
      // Double check - message has been read
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.done_all,
            size: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ],
      );
    } else {
      // Single check - message delivered but not read
      return Icon(
        Icons.done,
        size: 14,
        color: Colors.white.withOpacity(0.7),
      );
    }
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

  Widget _buildDeletedMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) const SizedBox(width: 40), // Space for avatar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'This message was deleted',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 40), // Space for avatar
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
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

### File 6: `lib/widgets/conversation_list_tile.dart` (CREATE NEW FILE)

```dart
// lib/widgets/conversation_list_tile.dart
import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../models/user_presence.dart';
import '../services/direct_message_service.dart';

class ConversationListTile extends StatelessWidget {
  final Conversation conversation;
  final String currentUserId;
  final VoidCallback onTap;

  const ConversationListTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherParticipant = conversation.getOtherParticipant(currentUserId);
    final otherParticipantId = conversation.getOtherParticipantId(currentUserId);
    final unreadCount = conversation.getUnreadCountForUser(currentUserId);
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasUnread ? Colors.blue[50] : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _getAvatarColor(otherParticipant?.name ?? ''),
                  backgroundImage: otherParticipant?.profileImage != null
                      ? NetworkImage(otherParticipant!.profileImage!)
                      : null,
                  child: otherParticipant?.profileImage == null
                      ? Text(
                          otherParticipant?.name.isNotEmpty == true
                              ? otherParticipant!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                // Online indicator
                StreamBuilder<UserPresence?>(
                  stream: DirectMessageService().getUserPresenceStream(otherParticipantId),
                  builder: (context, snapshot) {
                    final isOnline = snapshot.data?.isOnline ?? false;
                    if (!isOnline) return const SizedBox.shrink();

                    return Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Name and last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherParticipant?.name ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.lastMessage != null)
                        Text(
                          _formatTime(conversation.lastMessageAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? const Color(0xFF0056AC)
                                : Colors.grey[500],
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Last message preview and unread badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getLastMessagePreview(),
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread ? Colors.black87 : Colors.grey[600],
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0056AC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLastMessagePreview() {
    final lastMessage = conversation.lastMessage;
    if (lastMessage == null) {
      return 'Tap to start chatting';
    }

    final isFromMe = lastMessage.senderId == currentUserId;
    final prefix = isFromMe ? 'You: ' : '';
    final content = lastMessage.content;

    // Truncate long messages
    if (content.length > 30) {
      return '$prefix${content.substring(0, 30)}...';
    }
    return '$prefix$content';
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${date.day}/${date.month}';
    }
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

## PART 4: CREATE NEW SCREEN FILES

### File 7: `lib/screens/conversations_list_screen.dart` (CREATE NEW FILE)

```dart
// lib/screens/conversations_list_screen.dart
import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../models/user.dart';
import '../services/direct_message_service.dart';
import '../widgets/conversation_list_tile.dart';
import 'direct_message_chat_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final DirectMessageService _dmService = DirectMessageService();

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isGuest
          ? _buildGuestView()
          : StreamBuilder<List<Conversation>>(
              stream: _dmService.getConversationsStream(currentUser.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading conversations',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final conversations = snapshot.data ?? [];

                if (conversations.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final otherParticipant =
                          conversation.getOtherParticipant(currentUser.id);
                      final otherParticipantId =
                          conversation.getOtherParticipantId(currentUser.id);

                      return ConversationListTile(
                        conversation: conversation,
                        currentUserId: currentUser.id,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DirectMessageChatScreen(
                                otherUserId: otherParticipantId,
                                otherUserName: otherParticipant?.name ?? 'Unknown',
                                otherUserEmail: otherParticipant?.email ?? '',
                                otherUserProfileImage: otherParticipant?.profileImage,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mail_outline,
                size: 64,
                color: Colors.orange[300],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sign in to Message',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create an account or sign in to send direct messages to other members.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Colors.blue[300],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Messages Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start a conversation by tapping on someone\'s name in the Global Chat or Forum.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, color: Colors.grey[500], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tap on any user to message them',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### File 8: `lib/screens/direct_message_chat_screen.dart` (CREATE NEW FILE)

```dart
// lib/screens/direct_message_chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../models/direct_message.dart';
import '../models/user.dart';
import '../models/user_presence.dart';
import '../services/direct_message_service.dart';
import '../widgets/direct_message_bubble.dart';

class DirectMessageChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserEmail;
  final String? otherUserProfileImage;

  const DirectMessageChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserEmail,
    this.otherUserProfileImage,
  });

  @override
  State<DirectMessageChatScreen> createState() => _DirectMessageChatScreenState();
}

class _DirectMessageChatScreenState extends State<DirectMessageChatScreen>
    with WidgetsBindingObserver {
  final DirectMessageService _dmService = DirectMessageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isSending = false;
  String? _conversationId;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initConversation();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    // Clear typing status when leaving
    if (_conversationId != null) {
      _dmService.setTypingStatus(
        userId: User.currentUser.id,
        conversationId: _conversationId!,
        isTyping: false,
      );
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userId = User.currentUser.id;
    if (userId.isEmpty) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _dmService.setOnlineStatus(userId, false);
    } else if (state == AppLifecycleState.resumed) {
      _dmService.setOnlineStatus(userId, true);
    }
  }

  Future<void> _initConversation() async {
    final currentUser = User.currentUser;
    if (currentUser.id.isEmpty) return;

    try {
      final conversation = await _dmService.getOrCreateConversation(
        currentUserId: currentUser.id,
        currentUserName: currentUser.name,
        currentUserEmail: currentUser.email,
        currentUserProfileImage: currentUser.profileImage,
        otherUserId: widget.otherUserId,
        otherUserName: widget.otherUserName,
        otherUserEmail: widget.otherUserEmail,
        otherUserProfileImage: widget.otherUserProfileImage,
      );

      setState(() {
        _conversationId = conversation.id;
      });

      // Mark conversation as read
      await _dmService.markAsRead(
        conversationId: conversation.id,
        userId: currentUser.id,
      );

      // Set online status
      await _dmService.setOnlineStatus(currentUser.id, true);
    } catch (e) {
      print('Error initializing conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTextChanged() {
    if (_conversationId == null) return;

    final hasText = _messageController.text.trim().isNotEmpty;

    if (hasText && !_isTyping) {
      _isTyping = true;
      _dmService.setTypingStatus(
        userId: User.currentUser.id,
        conversationId: _conversationId!,
        isTyping: true,
      );
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTyping) {
        _isTyping = false;
        _dmService.setTypingStatus(
          userId: User.currentUser.id,
          conversationId: _conversationId!,
          isTyping: false,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_conversationId == null) return;

    final currentUser = User.currentUser;
    if (currentUser.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to send messages'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    // Clear typing status
    _isTyping = false;
    _dmService.setTypingStatus(
      userId: currentUser.id,
      conversationId: _conversationId!,
      isTyping: false,
    );

    try {
      await _dmService.sendMessage(
        conversationId: _conversationId!,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderEmail: currentUser.email,
        content: content,
        recipientId: widget.otherUserId,
      );

      _messageController.clear();

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteMessage(DirectMessage message) async {
    if (_conversationId == null) return;

    final currentUser = User.currentUser;
    if (message.senderId != currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete your own messages'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
        await _dmService.deleteMessage(
          conversationId: _conversationId!,
          messageId: message.id,
          currentUserId: currentUser.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: _getAvatarColor(widget.otherUserName),
              backgroundImage: widget.otherUserProfileImage != null
                  ? NetworkImage(widget.otherUserProfileImage!)
                  : null,
              child: widget.otherUserProfileImage == null
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Name and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Online status and typing indicator
                  StreamBuilder<UserPresence?>(
                    stream: _dmService.getUserPresenceStream(widget.otherUserId),
                    builder: (context, presenceSnapshot) {
                      final presence = presenceSnapshot.data;

                      // Check typing status
                      if (_conversationId != null) {
                        return StreamBuilder<bool>(
                          stream: _dmService.getTypingStatusStream(
                            conversationId: _conversationId!,
                            otherUserId: widget.otherUserId,
                          ),
                          builder: (context, typingSnapshot) {
                            final isTyping = typingSnapshot.data ?? false;

                            if (isTyping) {
                              return Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0056AC),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'typing...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF0056AC),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              );
                            }

                            return _buildOnlineStatus(presence);
                          },
                        );
                      }

                      return _buildOnlineStatus(presence);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _conversationId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<DirectMessage>>(
                    stream: _dmService.getMessagesStream(_conversationId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Say hello to ${widget.otherUserName}!',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
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
                          final isCurrentUser = message.senderId == currentUser.id;

                          return DirectMessageBubble(
                            message: message,
                            isCurrentUser: isCurrentUser,
                            onLongPress: isCurrentUser
                                ? () => _deleteMessage(message)
                                : null,
                          );
                        },
                      );
                    },
                  ),
          ),
          // Message input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
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
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineStatus(UserPresence? presence) {
    if (presence == null) {
      return Text(
        'Offline',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: presence.isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          presence.getLastSeenText(),
          style: TextStyle(
            fontSize: 12,
            color: presence.isOnline ? Colors.green : Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
```

---

## PART 5: MODIFY EXISTING FILES

### Modify `lib/widgets/chat_message_bubble.dart`

**ADD** this parameter to the class:
```dart
final VoidCallback? onTapAuthor;  // Callback for tapping on author to start DM
```

**ADD** to the constructor:
```dart
this.onTapAuthor,
```

**WRAP** the avatar for other users with GestureDetector:
```dart
// Avatar for other users (left side) - tappable for DM
if (!isCurrentUser) ...[
  GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTapAuthor,
    child: CircleAvatar(
      // ... existing code
    ),
  ),
  const SizedBox(width: 8),
],
```

**WRAP** the author name text with GestureDetector (inside the message bubble):
```dart
// Author name (only for other users) - tappable for DM
if (!isCurrentUser)
  GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTapAuthor,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        message.authorName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: onTapAuthor != null
              ? const Color(0xFF0056AC)
              : _getAvatarColor(message.authorName),
          decoration: onTapAuthor != null
              ? TextDecoration.underline
              : null,
        ),
      ),
    ),
  ),
```

---

### Modify `lib/screens/global_chat_screen.dart`

**ADD** import at top:
```dart
import 'direct_message_chat_screen.dart';
```

**ADD** this method to the state class:
```dart
void _startDirectMessage(ChatMessage message) {
  final currentUser = User.currentUser;
  if (currentUser.id.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please sign in to send direct messages'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Don't allow DM to yourself
  if (message.authorId == currentUser.id) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DirectMessageChatScreen(
        otherUserId: message.authorId,
        otherUserName: message.authorName,
        otherUserEmail: message.authorEmail,
      ),
    ),
  );
}
```

**UPDATE** ChatMessageBubble usage to include onTapAuthor:
```dart
return ChatMessageBubble(
  message: message,
  isCurrentUser: isCurrentUser,
  onLongPress: isCurrentUser
      ? () => _deleteMessage(message)
      : null,
  onTapAuthor: !isCurrentUser
      ? () => _startDirectMessage(message)
      : null,
);
```

---

### Modify `lib/screens/community_screen.dart`

**ADD** imports at top:
```dart
import '../services/direct_message_service.dart';
import 'conversations_list_screen.dart';
import 'direct_message_chat_screen.dart';
```

**ADD** service in state class:
```dart
final DirectMessageService _dmService = DirectMessageService();
```

**ADD** messages icon with unread badge in the header Row (after the filter button):
```dart
// Messages icon with unread badge
if (!isGuest)
  StreamBuilder<int>(
    stream: _dmService.getTotalUnreadCountStream(currentUser.id),
    builder: (context, snapshot) {
      final unreadCount = snapshot.data ?? 0;
      return IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.mail_outline,
              color: unreadCount > 0
                  ? const Color(0xFF0056AC)
                  : Colors.grey[600],
            ),
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ConversationsListScreen(),
            ),
          );
        },
      );
    },
  ),
```

**UPDATE** ForumQuestionCard to include onTapAuthor:
```dart
final canDM = !isGuest && question.authorId != User.currentUser.id;
return ForumQuestionCard(
  question: question,
  onTap: () { /* existing navigation code */ },
  onTapAuthor: canDM
      ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DirectMessageChatScreen(
                otherUserId: question.authorId,
                otherUserName: question.authorName,
                otherUserEmail: question.authorEmail,
              ),
            ),
          );
        }
      : null,
);
```

---

### Modify `lib/widgets/forum_question_card.dart`

**ADD** parameter:
```dart
final VoidCallback? onTapAuthor;  // Callback for tapping on author to start DM
```

**ADD** to constructor:
```dart
this.onTapAuthor,
```

**WRAP** the author Row with GestureDetector:
```dart
// Author and time row
Row(
  children: [
    // Tappable author for DM
    GestureDetector(
      onTap: onTapAuthor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(/* existing */),
          const SizedBox(width: 8),
          Text(
            question.authorName,
            style: TextStyle(
              fontSize: 12,
              color: onTapAuthor != null
                  ? const Color(0xFF0056AC)
                  : Colors.grey[700],
              fontWeight: onTapAuthor != null
                  ? FontWeight.w500
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
    const Spacer(),
    Text(/* time */),
  ],
),
```

---

### Modify `lib/widgets/forum_answer_card.dart`

**ADD** parameter:
```dart
final VoidCallback? onTapAuthor;  // Callback for tapping on author to start DM
```

**ADD** to constructor:
```dart
this.onTapAuthor,
```

**WRAP** the author Row with GestureDetector (similar to forum_question_card.dart)

---

### Modify `lib/screens/forum_question_detail_screen.dart`

**ADD** import:
```dart
import 'direct_message_chat_screen.dart';
```

**WRAP** the question author info with GestureDetector for DM.

**UPDATE** ForumAnswerCard usage to include onTapAuthor:
```dart
final canDMAnswer = !isGuest && answer.authorId != currentUser.id;
return ForumAnswerCard(
  answer: answer,
  isQuestionAuthor: isAuthor,
  onAccept: /* existing */,
  onTapAuthor: canDMAnswer
      ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DirectMessageChatScreen(
                otherUserId: answer.authorId,
                otherUserName: answer.authorName,
                otherUserEmail: answer.authorEmail,
              ),
            ),
          );
        }
      : null,
);
```

---

## PART 6: FIRESTORE SECURITY RULES

Add these rules to your Firestore Rules:

```javascript
// Direct Messages collection
match /direct_messages/{conversationId} {
  // Allow get (single doc) for any authenticated user - needed to check if conversation exists
  allow get: if request.auth != null;
  // Allow list (queries) only for participants
  allow list: if request.auth != null
    && request.auth.uid in resource.data.participants;
  allow create: if request.auth != null
    && request.auth.uid in request.resource.data.participants;
  allow update: if request.auth != null
    && request.auth.uid in resource.data.participants;

  // Messages subcollection
  match /messages/{messageId} {
    allow read: if request.auth != null;
    allow create: if request.auth != null;
    allow update: if request.auth != null
      && resource.data.senderId == request.auth.uid;
  }
}

// User Presence collection
match /user_presence/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

---

## PART 7: FIRESTORE INDEXES

Create these composite indexes in Firebase Console → Firestore → Indexes:

1. **Collection:** `direct_messages`
   - **Fields:** `participants` (Arrays) + `lastMessageAt` (Descending)

---

## FILES SUMMARY

### New Files (8 files):
| File | Purpose |
|------|---------|
| `lib/models/conversation.dart` | Conversation model |
| `lib/models/direct_message.dart` | DirectMessage model |
| `lib/models/user_presence.dart` | UserPresence model |
| `lib/services/direct_message_service.dart` | DM service |
| `lib/widgets/direct_message_bubble.dart` | Message bubble widget |
| `lib/widgets/conversation_list_tile.dart` | Conversation tile widget |
| `lib/screens/conversations_list_screen.dart` | Conversations list screen |
| `lib/screens/direct_message_chat_screen.dart` | DM chat screen |

### Modified Files (6 files):
| File | Changes |
|------|---------|
| `lib/screens/community_screen.dart` | Add messages icon, DM navigation |
| `lib/widgets/chat_message_bubble.dart` | Add onTapAuthor callback |
| `lib/screens/global_chat_screen.dart` | Handle tap-to-DM |
| `lib/widgets/forum_question_card.dart` | Tappable author |
| `lib/widgets/forum_answer_card.dart` | Tappable author |
| `lib/screens/forum_question_detail_screen.dart` | DM from question/answers |

---

## TESTING CHECKLIST

- [ ] Messages icon appears in Community header
- [ ] Unread count badge shows correctly
- [ ] Tap on user in Global Chat opens DM
- [ ] Tap on question author opens DM
- [ ] Tap on answer author opens DM
- [ ] Can send messages
- [ ] Can delete own messages
- [ ] Typing indicator shows
- [ ] Online status shows
- [ ] Conversation list loads correctly
