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
