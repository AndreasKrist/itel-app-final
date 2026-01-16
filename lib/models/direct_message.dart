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
