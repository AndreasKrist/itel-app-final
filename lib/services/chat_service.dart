// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference for global chat
  CollectionReference get _globalChatRef =>
      _firestore.collection('global_chat');

  // Get stream of messages (ordered by createdAt descending for latest first)
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

  // Send a new message
  Future<void> sendMessage({
    required String authorId,
    required String authorName,
    required String authorEmail,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final message = ChatMessage(
      id: '', // Firestore will generate
      authorId: authorId,
      authorName: authorName,
      authorEmail: authorEmail,
      content: content.trim(),
      createdAt: DateTime.now(),
      type: type,
    );

    await _globalChatRef.add(message.toJson());
  }

  // Delete a message (only by author)
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

  // Get message count (for stats)
  Future<int> getMessageCount() async {
    final snapshot = await _globalChatRef.count().get();
    return snapshot.count ?? 0;
  }

  // Get recent messages (one-time fetch)
  Future<List<ChatMessage>> getRecentMessages({int limit = 50}) async {
    final snapshot = await _globalChatRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      return ChatMessage.fromJson(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }
}
