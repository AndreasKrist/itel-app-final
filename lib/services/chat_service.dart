// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ITEL/models/chat_message.dart';
import 'package:ITEL/models/chat_ban.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference for global chat
  CollectionReference get _globalChatRef =>
      _firestore.collection('global_chat');

  // Collection reference for chat bans
  CollectionReference get _chatBansRef =>
      _firestore.collection('chat_bans');

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

  // ============ STAFF MODERATION ============

  /// Staff delete message - clean removal without trace
  Future<void> staffDeleteMessage({
    required String messageId,
    required String staffId,
    required bool isStaff,
  }) async {
    if (!isStaff) {
      throw Exception('Only staff can perform this action');
    }

    final doc = await _globalChatRef.doc(messageId).get();
    if (!doc.exists) {
      throw Exception('Message not found');
    }

    // Simply delete the message - no trace
    await _globalChatRef.doc(messageId).delete();
    print('Message $messageId deleted by staff $staffId');
  }

  /// Give user a cooldown (temporary ban)
  Future<void> giveCooldown({
    required String odGptUserId,
    required String userName,
    required String userEmail,
    required String staffId,
    required String staffName,
    required Duration duration,
    String? reason,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(duration);

    // Remove any existing active ban for this user first
    final existingBans = await _chatBansRef
        .where('userId', isEqualTo: odGptUserId)
        .get();

    for (var doc in existingBans.docs) {
      await doc.reference.delete();
    }

    // Create new cooldown
    await _chatBansRef.add({
      'userId': odGptUserId,
      'userName': userName,
      'userEmail': userEmail,
      'banType': 'cooldown',
      'bannedById': staffId,
      'bannedByName': staffName,
      'bannedAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'reason': reason,
    });

    print('Cooldown given to $odGptUserId until $expiresAt');
  }

  /// Kick user (permanent ban)
  Future<void> kickUser({
    required String odGptUserId,
    required String userName,
    required String userEmail,
    required String staffId,
    required String staffName,
    String? reason,
  }) async {
    final now = DateTime.now();

    // Remove any existing bans for this user first
    final existingBans = await _chatBansRef
        .where('userId', isEqualTo: odGptUserId)
        .get();

    for (var doc in existingBans.docs) {
      await doc.reference.delete();
    }

    // Create permanent kick
    await _chatBansRef.add({
      'userId': odGptUserId,
      'userName': userName,
      'userEmail': userEmail,
      'banType': 'kicked',
      'bannedById': staffId,
      'bannedByName': staffName,
      'bannedAt': Timestamp.fromDate(now),
      'expiresAt': null, // Permanent
      'reason': reason,
    });

    print('User $odGptUserId kicked permanently');
  }

  /// Remove ban/cooldown (unban user)
  Future<void> unbanUser(String odGptUserId) async {
    final existingBans = await _chatBansRef
        .where('userId', isEqualTo: odGptUserId)
        .get();

    for (var doc in existingBans.docs) {
      await doc.reference.delete();
    }

    print('User $odGptUserId unbanned');
  }

  /// Check if user is banned or on cooldown
  Future<ChatBan?> getUserBanStatus(String odGptUserId) async {
    final snapshot = await _chatBansRef
        .where('userId', isEqualTo: odGptUserId)
        .get();

    if (snapshot.docs.isEmpty) return null;

    // Get the most recent ban
    for (var doc in snapshot.docs) {
      final ban = ChatBan.fromJson(doc.data() as Map<String, dynamic>, doc.id);

      // If it's a permanent kick, return it
      if (ban.banType == ChatBanType.kicked) {
        return ban;
      }

      // If it's a cooldown, check if it's still active
      if (ban.banType == ChatBanType.cooldown && ban.isActive) {
        return ban;
      }

      // If cooldown expired, delete it
      if (ban.banType == ChatBanType.cooldown && !ban.isActive) {
        await doc.reference.delete();
      }
    }

    return null;
  }

  /// Stream of user's ban status (for real-time UI updates)
  Stream<ChatBan?> getUserBanStatusStream(String odGptUserId) {
    return _chatBansRef
        .where('userId', isEqualTo: odGptUserId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      for (var doc in snapshot.docs) {
        final ban = ChatBan.fromJson(doc.data() as Map<String, dynamic>, doc.id);

        if (ban.banType == ChatBanType.kicked) {
          return ban;
        }

        if (ban.banType == ChatBanType.cooldown && ban.isActive) {
          return ban;
        }
      }

      return null;
    });
  }

  /// Get all active bans (for staff view)
  Stream<List<ChatBan>> getAllBansStream() {
    return _chatBansRef
        .orderBy('bannedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatBan.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .where((ban) => ban.isActive)
          .toList();
    });
  }
}
