import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of kick action
enum KickType {
  kickedByCreator,  // Kicked by forum creator (requires reason)
  kickedByStaff,    // Kicked by ITEL staff (no reason required)
  forumRemoved,     // Forum was removed by staff
}

/// Represents a kick/removal log entry in a forum
class ForumKickLog {
  final String id;
  final String forumId;
  final String forumTitle;
  final String kickedUserId;
  final String kickedUserName;
  final String kickedUserEmail;
  final String kickedById;
  final String kickedByName;
  final String kickedByEmail;
  final bool kickedByStaff;
  final KickType kickType;
  final String reason; // Required for creator kicks
  final DateTime kickedAt;

  ForumKickLog({
    required this.id,
    required this.forumId,
    required this.forumTitle,
    required this.kickedUserId,
    required this.kickedUserName,
    required this.kickedUserEmail,
    required this.kickedById,
    required this.kickedByName,
    required this.kickedByEmail,
    required this.kickedByStaff,
    required this.kickType,
    required this.reason,
    required this.kickedAt,
  });

  factory ForumKickLog.fromJson(Map<String, dynamic> json, String id) {
    return ForumKickLog(
      id: id,
      forumId: json['forumId'] as String? ?? '',
      forumTitle: json['forumTitle'] as String? ?? '',
      kickedUserId: json['kickedUserId'] as String? ?? '',
      kickedUserName: json['kickedUserName'] as String? ?? 'Unknown',
      kickedUserEmail: json['kickedUserEmail'] as String? ?? '',
      kickedById: json['kickedById'] as String? ?? '',
      kickedByName: json['kickedByName'] as String? ?? 'Unknown',
      kickedByEmail: json['kickedByEmail'] as String? ?? '',
      kickedByStaff: json['kickedByStaff'] as bool? ?? false,
      kickType: _stringToKickType(json['kickType'] as String? ?? 'kickedByCreator'),
      reason: json['reason'] as String? ?? '',
      kickedAt: _parseTimestamp(json['kickedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forumId': forumId,
      'forumTitle': forumTitle,
      'kickedUserId': kickedUserId,
      'kickedUserName': kickedUserName,
      'kickedUserEmail': kickedUserEmail,
      'kickedById': kickedById,
      'kickedByName': kickedByName,
      'kickedByEmail': kickedByEmail,
      'kickedByStaff': kickedByStaff,
      'kickType': _kickTypeToString(kickType),
      'reason': reason,
      'kickedAt': Timestamp.fromDate(kickedAt),
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  static KickType _stringToKickType(String str) {
    switch (str) {
      case 'kickedByStaff':
        return KickType.kickedByStaff;
      case 'forumRemoved':
        return KickType.forumRemoved;
      case 'kickedByCreator':
      default:
        return KickType.kickedByCreator;
    }
  }

  static String _kickTypeToString(KickType type) {
    switch (type) {
      case KickType.kickedByStaff:
        return 'kickedByStaff';
      case KickType.forumRemoved:
        return 'forumRemoved';
      case KickType.kickedByCreator:
        return 'kickedByCreator';
    }
  }

  /// Get display text for kick type
  String get kickTypeDisplay {
    switch (kickType) {
      case KickType.kickedByStaff:
        return 'Kicked by staff';
      case KickType.forumRemoved:
        return 'Forum removed';
      case KickType.kickedByCreator:
        return 'Kicked by creator';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForumKickLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
