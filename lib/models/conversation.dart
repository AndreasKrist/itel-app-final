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
