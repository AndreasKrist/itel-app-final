import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of event chat restriction
enum EventBanType {
  cooldown,  // Temporary - cannot chat until cooldown expires
  kicked,    // Permanent - cannot chat in this event anymore
}

/// Represents a ban/cooldown in an event chat
class EventBan {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String userEmail;
  final EventBanType banType;
  final String bannedById;
  final String bannedByName;
  final DateTime bannedAt;
  final DateTime? expiresAt;  // null for permanent kicks
  final String? reason;

  EventBan({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.banType,
    required this.bannedById,
    required this.bannedByName,
    required this.bannedAt,
    this.expiresAt,
    this.reason,
  });

  factory EventBan.fromJson(Map<String, dynamic> json, String id) {
    return EventBan(
      id: id,
      eventId: json['eventId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown',
      userEmail: json['userEmail'] as String? ?? '',
      banType: _stringToBanType(json['banType'] as String? ?? 'cooldown'),
      bannedById: json['bannedById'] as String? ?? '',
      bannedByName: json['bannedByName'] as String? ?? 'Unknown',
      bannedAt: _parseTimestamp(json['bannedAt']),
      expiresAt: json['expiresAt'] != null
          ? _parseTimestamp(json['expiresAt'])
          : null,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'banType': _banTypeToString(banType),
      'bannedById': bannedById,
      'bannedByName': bannedByName,
      'bannedAt': Timestamp.fromDate(bannedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'reason': reason,
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  static EventBanType _stringToBanType(String str) {
    switch (str) {
      case 'kicked':
        return EventBanType.kicked;
      case 'cooldown':
      default:
        return EventBanType.cooldown;
    }
  }

  static String _banTypeToString(EventBanType type) {
    switch (type) {
      case EventBanType.kicked:
        return 'kicked';
      case EventBanType.cooldown:
        return 'cooldown';
    }
  }

  /// Check if this ban is still active
  bool get isActive {
    if (banType == EventBanType.kicked) return true; // Permanent
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Get remaining cooldown duration
  Duration? get remainingCooldown {
    if (banType != EventBanType.cooldown || expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Format remaining time as string
  String get remainingTimeFormatted {
    final remaining = remainingCooldown;
    if (remaining == null) return '';

    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m ${remaining.inSeconds % 60}s';
    } else {
      return '${remaining.inSeconds}s';
    }
  }
}
