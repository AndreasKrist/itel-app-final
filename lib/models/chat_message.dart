// lib/models/chat_message.dart
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

  // Check if this message is from the current user
  bool isFromUser(String userId) => authorId == userId;
}

enum MessageType {
  text,
  system, // For join/leave notifications, etc.
}
