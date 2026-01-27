import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of chat restriction
enum ChatBanType {
  cooldown,  // Temporary - cannot chat until cooldown expires
  kicked,    // Permanent - cannot chat anymore
}

/// Represents a chat ban/cooldown in ITEL Community
class ChatBan {
  final String id;
  final String odGptUserId;
  final String userName;
  final String userEmail;
  final ChatBanType banType;
  final String bannedById;
  final String bannedByName;
  final DateTime bannedAt;
  final DateTime? expiresAt;  // null for permanent kicks
  final String? reason;

  ChatBan({
    required this.id,
    required this.odGptUserId,
    required this.userName,
    required this.userEmail,
    required this.banType,
    required this.bannedById,
    required this.bannedByName,
    required this.bannedAt,
    this.expiresAt,
    this.reason,
  });

  factory ChatBan.fromJson(Map<String, dynamic> json, String id) {
    return ChatBan(
      id: id,
      odGptUserId: json['userId'] as String? ?? '',
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
      'userId': odGptUserId,
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

  static ChatBanType _stringToBanType(String str) {
    switch (str) {
      case 'kicked':
        return ChatBanType.kicked;
      case 'cooldown':
      default:
        return ChatBanType.cooldown;
    }
  }

  static String _banTypeToString(ChatBanType type) {
    switch (type) {
      case ChatBanType.kicked:
        return 'kicked';
      case ChatBanType.cooldown:
        return 'cooldown';
    }
  }

  /// Check if this ban is still active
  bool get isActive {
    if (banType == ChatBanType.kicked) return true; // Permanent
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Get remaining cooldown duration
  Duration? get remainingCooldown {
    if (banType != ChatBanType.cooldown || expiresAt == null) return null;
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
