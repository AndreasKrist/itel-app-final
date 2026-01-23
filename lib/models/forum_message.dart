import 'package:cloud_firestore/cloud_firestore.dart';

/// Message type for forum messages
enum ForumMessageType {
  text,    // Regular text message
  system,  // System message (user joined, left, kicked, etc.)
}

/// Represents a message in a forum chat
class ForumMessage {
  final String id;
  final String forumId;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String content;
  final DateTime createdAt;
  final ForumMessageType type;
  final DateTime? deletedAt;
  final String? deletedBy;

  ForumMessage({
    required this.id,
    required this.forumId,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.content,
    required this.createdAt,
    this.type = ForumMessageType.text,
    this.deletedAt,
    this.deletedBy,
  });

  factory ForumMessage.fromJson(Map<String, dynamic> json, String id) {
    return ForumMessage(
      id: id,
      forumId: json['forumId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderEmail: json['senderEmail'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      type: ForumMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ForumMessageType.text,
      ),
      deletedAt: json['deletedAt'] != null ? _parseTimestamp(json['deletedAt']) : null,
      deletedBy: json['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forumId': forumId,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type.name,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy,
    };
  }

  ForumMessage copyWith({
    String? id,
    String? forumId,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? content,
    DateTime? createdAt,
    ForumMessageType? type,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return ForumMessage(
      id: id ?? this.id,
      forumId: forumId ?? this.forumId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  /// Check if this message is from a specific user
  bool isFromUser(String odGptUserId) => senderId == odGptUserId;

  /// Check if the message has been deleted
  bool get isDeleted => deletedAt != null;

  /// Get the display content (shows placeholder if deleted)
  String get displayContent {
    if (isDeleted) {
      return 'This message was deleted';
    }
    return content;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForumMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
