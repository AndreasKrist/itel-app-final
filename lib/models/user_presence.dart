// lib/models/user_presence.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents typing status for a specific conversation
class TypingStatus {
  final bool isTyping;
  final DateTime updatedAt;

  TypingStatus({
    required this.isTyping,
    required this.updatedAt,
  });

  factory TypingStatus.fromJson(Map<String, dynamic> json) {
    return TypingStatus(
      isTyping: json['isTyping'] as bool? ?? false,
      updatedAt: _parseTimestamp(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isTyping': isTyping,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Check if typing status is still valid (not stale)
  /// Typing indicators older than 5 seconds are considered stale
  bool get isValid {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    return diff.inSeconds < 5 && isTyping;
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }
}

/// Represents user's online presence and typing status
class UserPresence {
  final String userId;
  final bool isOnline;
  final DateTime lastSeen;
  final Map<String, TypingStatus> typing;

  UserPresence({
    required this.userId,
    required this.isOnline,
    required this.lastSeen,
    this.typing = const {},
  });

  factory UserPresence.fromJson(Map<String, dynamic> json, String id) {
    // Parse typing status map
    final typingJson = json['typing'] as Map<String, dynamic>? ?? {};
    final typing = <String, TypingStatus>{};
    typingJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        typing[key] = TypingStatus.fromJson(value);
      }
    });

    return UserPresence(
      userId: id,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: _parseTimestamp(json['lastSeen']),
      typing: typing,
    );
  }

  Map<String, dynamic> toJson() {
    final typingJson = <String, dynamic>{};
    typing.forEach((key, value) {
      typingJson[key] = value.toJson();
    });

    return {
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'typing': typingJson,
    };
  }

  UserPresence copyWith({
    String? userId,
    bool? isOnline,
    DateTime? lastSeen,
    Map<String, TypingStatus>? typing,
  }) {
    return UserPresence(
      userId: userId ?? this.userId,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      typing: typing ?? this.typing,
    );
  }

  /// Check if user is currently typing in a specific conversation
  bool isTypingIn(String conversationId) {
    final status = typing[conversationId];
    return status?.isValid ?? false;
  }

  /// Get a human-readable last seen text
  String getLastSeenText() {
    if (isOnline) {
      return 'Online';
    }

    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.inMinutes < 1) {
      return 'Last seen just now';
    } else if (diff.inMinutes < 60) {
      return 'Last seen ${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return 'Last seen ${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return 'Last seen ${diff.inDays}d ago';
    } else {
      return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  /// Create a default offline presence
  static UserPresence offline(String userId) {
    return UserPresence(
      userId: userId,
      isOnline: false,
      lastSeen: DateTime.now(),
      typing: {},
    );
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
    return other is UserPresence && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
