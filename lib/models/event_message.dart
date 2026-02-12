import 'package:cloud_firestore/cloud_firestore.dart';

/// Message type for event messages
enum EventMessageType {
  text,    // Regular text message
  system,  // System message (event started, voucher claimed, etc.)
  image,   // Media message (image or video URL) — staff only
}

/// Represents a message in an event chat
class EventMessage {
  final String id;
  final String eventId;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String content;
  final DateTime createdAt;
  final EventMessageType type;
  final String? mediaUrl;
  final DateTime? deletedAt;
  final String? deletedBy;

  EventMessage({
    required this.id,
    required this.eventId,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.content,
    required this.createdAt,
    this.type = EventMessageType.text,
    this.mediaUrl,
    this.deletedAt,
    this.deletedBy,
  });

  factory EventMessage.fromJson(Map<String, dynamic> json, String id) {
    return EventMessage(
      id: id,
      eventId: json['eventId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderEmail: json['senderEmail'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      type: EventMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EventMessageType.text,
      ),
      mediaUrl: json['mediaUrl'] as String?,
      deletedAt: json['deletedAt'] != null ? _parseTimestamp(json['deletedAt']) : null,
      deletedBy: json['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type.name,
      'mediaUrl': mediaUrl,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy,
    };
  }

  EventMessage copyWith({
    String? id,
    String? eventId,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? content,
    DateTime? createdAt,
    EventMessageType? type,
    String? mediaUrl,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return EventMessage(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
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

  /// Check if this is a system message
  bool get isSystemMessage => type == EventMessageType.system;

  /// Check if this is a media message (image/video)
  bool get isMediaMessage => type == EventMessageType.image;

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
    return other is EventMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
