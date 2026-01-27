import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a forum invitation
enum InvitationStatus {
  pending,   // Waiting for user to accept/decline
  accepted,  // User accepted and joined
  declined,  // User declined the invitation
}

/// Represents an invitation to join a forum
class ForumInvitation {
  final String id;
  final String forumId;
  final String forumTitle;
  final String invitedUserId;
  final String invitedUserName;
  final String invitedUserEmail;
  final String invitedById;
  final String invitedByName;
  final DateTime invitedAt;
  final InvitationStatus status;
  final DateTime? respondedAt;

  ForumInvitation({
    required this.id,
    required this.forumId,
    required this.forumTitle,
    required this.invitedUserId,
    required this.invitedUserName,
    required this.invitedUserEmail,
    required this.invitedById,
    required this.invitedByName,
    required this.invitedAt,
    this.status = InvitationStatus.pending,
    this.respondedAt,
  });

  factory ForumInvitation.fromJson(Map<String, dynamic> json, String id) {
    return ForumInvitation(
      id: id,
      forumId: json['forumId'] as String? ?? '',
      forumTitle: json['forumTitle'] as String? ?? '',
      invitedUserId: json['invitedUserId'] as String? ?? '',
      invitedUserName: json['invitedUserName'] as String? ?? 'Unknown',
      invitedUserEmail: json['invitedUserEmail'] as String? ?? '',
      invitedById: json['invitedById'] as String? ?? '',
      invitedByName: json['invitedByName'] as String? ?? 'Unknown',
      invitedAt: _parseTimestamp(json['invitedAt']),
      status: _stringToStatus(json['status'] as String? ?? 'pending'),
      respondedAt: json['respondedAt'] != null
          ? _parseTimestamp(json['respondedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forumId': forumId,
      'forumTitle': forumTitle,
      'invitedUserId': invitedUserId,
      'invitedUserName': invitedUserName,
      'invitedUserEmail': invitedUserEmail,
      'invitedById': invitedById,
      'invitedByName': invitedByName,
      'invitedAt': Timestamp.fromDate(invitedAt),
      'status': _statusToString(status),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  static InvitationStatus _stringToStatus(String str) {
    switch (str) {
      case 'accepted':
        return InvitationStatus.accepted;
      case 'declined':
        return InvitationStatus.declined;
      case 'pending':
      default:
        return InvitationStatus.pending;
    }
  }

  static String _statusToString(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.accepted:
        return 'accepted';
      case InvitationStatus.declined:
        return 'declined';
      case InvitationStatus.pending:
        return 'pending';
    }
  }

  bool get isPending => status == InvitationStatus.pending;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForumInvitation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
