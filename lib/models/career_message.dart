import 'package:cloud_firestore/cloud_firestore.dart';

enum CareerMessageType {
  text,
  system,
}

class CareerMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String content;
  final DateTime createdAt;
  final CareerMessageType type;
  final bool isStaffMessage;
  final DateTime? deletedAt;
  final String? deletedBy;

  CareerMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.content,
    required this.createdAt,
    this.type = CareerMessageType.text,
    this.isStaffMessage = false,
    this.deletedAt,
    this.deletedBy,
  });

  factory CareerMessage.fromJson(Map<String, dynamic> json, String id) {
    return CareerMessage(
      id: id,
      ticketId: json['ticketId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderEmail: json['senderEmail'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      type: CareerMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CareerMessageType.text,
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

  CareerMessage copyWith({
    String? id,
    String? ticketId,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? content,
    DateTime? createdAt,
    CareerMessageType? type,
    bool? isStaffMessage,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return CareerMessage(
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

  bool isFromUser(String userId) => senderId == userId;

  bool get isDeleted => deletedAt != null;

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
    return other is CareerMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
