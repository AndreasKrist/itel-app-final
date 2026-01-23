import 'package:cloud_firestore/cloud_firestore.dart';

/// Role of a member in a forum
enum ForumMemberRole {
  creator,  // Forum creator - full control
  member,   // Regular member - can chat
}

/// Represents a member in a forum
class ForumMember {
  final String id;
  final String forumId;
  final String odGptUserId;
  final String userName;
  final String userEmail;
  final ForumMemberRole role;
  final DateTime joinedAt;
  final String? invitedBy; // User ID who invited this member
  final bool isActive; // False if kicked

  ForumMember({
    required this.id,
    required this.forumId,
    required this.odGptUserId,
    required this.userName,
    required this.userEmail,
    this.role = ForumMemberRole.member,
    required this.joinedAt,
    this.invitedBy,
    this.isActive = true,
  });

  factory ForumMember.fromJson(Map<String, dynamic> json, String id) {
    return ForumMember(
      id: id,
      forumId: json['forumId'] as String? ?? '',
      odGptUserId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown',
      userEmail: json['userEmail'] as String? ?? '',
      role: _stringToRole(json['role'] as String? ?? 'member'),
      joinedAt: _parseTimestamp(json['joinedAt']),
      invitedBy: json['invitedBy'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forumId': forumId,
      'userId': odGptUserId,
      'userName': userName,
      'userEmail': userEmail,
      'role': _roleToString(role),
      'joinedAt': Timestamp.fromDate(joinedAt),
      'invitedBy': invitedBy,
      'isActive': isActive,
    };
  }

  ForumMember copyWith({
    String? id,
    String? forumId,
    String? odGptUserId,
    String? userName,
    String? userEmail,
    ForumMemberRole? role,
    DateTime? joinedAt,
    String? invitedBy,
    bool? isActive,
  }) {
    return ForumMember(
      id: id ?? this.id,
      forumId: forumId ?? this.forumId,
      odGptUserId: odGptUserId ?? this.odGptUserId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      invitedBy: invitedBy ?? this.invitedBy,
      isActive: isActive ?? this.isActive,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  static ForumMemberRole _stringToRole(String str) {
    switch (str) {
      case 'creator':
        return ForumMemberRole.creator;
      case 'member':
      default:
        return ForumMemberRole.member;
    }
  }

  static String _roleToString(ForumMemberRole role) {
    switch (role) {
      case ForumMemberRole.creator:
        return 'creator';
      case ForumMemberRole.member:
        return 'member';
    }
  }

  /// Check if member is the creator
  bool get isCreator => role == ForumMemberRole.creator;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForumMember && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
