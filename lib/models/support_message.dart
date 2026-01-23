import 'package:cloud_firestore/cloud_firestore.dart';

/// Message type for support messages
enum SupportMessageType {
  text,
  system, // For system notifications like "ticket created", "ticket resolved"
}

/// Represents a single message in a support ticket conversation
class SupportMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String content;
  final DateTime createdAt;
  final SupportMessageType type;
  final bool isStaffMessage;
  final DateTime? deletedAt;
  final String? deletedBy;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.content,
    required this.createdAt,
    this.type = SupportMessageType.text,
    this.isStaffMessage = false,
    this.deletedAt,
    this.deletedBy,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json, String id) {
    return SupportMessage(
      id: id,
      ticketId: json['ticketId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderEmail: json['senderEmail'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      type: SupportMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SupportMessageType.text,
      ),
      isStaffMessage: json['isStaffMessage'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null ? _parseTimestamp(json['deletedAt']) : null,
      deletedBy: json['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type.name,
      'isStaffMessage': isStaffMessage,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy,
    };
  }

  SupportMessage copyWith({
    String? id,
    String? ticketId,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? content,
    DateTime? createdAt,
    SupportMessageType? type,
    bool? isStaffMessage,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return SupportMessage(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isStaffMessage: isStaffMessage ?? this.isStaffMessage,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  /// Check if this message is from a specific user
  bool isFromUser(String userId) => senderId == userId;

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
    return other is SupportMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
