import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a join request
enum JoinRequestStatus {
  pending,   // Waiting for creator approval
  approved,  // Approved - user is now a member
  rejected,  // Rejected by creator
}

/// Represents a request to join a private forum
class ForumJoinRequest {
  final String id;
  final String forumId;
  final String odGptUserId;
  final String userName;
  final String userEmail;
  final DateTime requestedAt;
  final JoinRequestStatus status;
  final String? processedBy; // User ID who approved/rejected
  final DateTime? processedAt;
  final String? rejectionReason;

  ForumJoinRequest({
    required this.id,
    required this.forumId,
    required this.odGptUserId,
    required this.userName,
    required this.userEmail,
    required this.requestedAt,
    this.status = JoinRequestStatus.pending,
    this.processedBy,
    this.processedAt,
    this.rejectionReason,
  });

  factory ForumJoinRequest.fromJson(Map<String, dynamic> json, String id) {
    return ForumJoinRequest(
      id: id,
      forumId: json['forumId'] as String? ?? '',
      odGptUserId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown',
      userEmail: json['userEmail'] as String? ?? '',
      requestedAt: _parseTimestamp(json['requestedAt']),
      status: _stringToStatus(json['status'] as String? ?? 'pending'),
      processedBy: json['processedBy'] as String?,
      processedAt: json['processedAt'] != null ? _parseTimestamp(json['processedAt']) : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forumId': forumId,
      'userId': odGptUserId,
      'userName': userName,
      'userEmail': userEmail,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': _statusToString(status),
      'processedBy': processedBy,
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  ForumJoinRequest copyWith({
    String? id,
    String? forumId,
    String? odGptUserId,
    String? userName,
    String? userEmail,
    DateTime? requestedAt,
    JoinRequestStatus? status,
    String? processedBy,
    DateTime? processedAt,
    String? rejectionReason,
  }) {
    return ForumJoinRequest(
      id: id ?? this.id,
      forumId: forumId ?? this.forumId,
      odGptUserId: odGptUserId ?? this.odGptUserId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      processedBy: processedBy ?? this.processedBy,
      processedAt: processedAt ?? this.processedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  static JoinRequestStatus _stringToStatus(String str) {
    switch (str) {
      case 'approved':
        return JoinRequestStatus.approved;
      case 'rejected':
        return JoinRequestStatus.rejected;
      case 'pending':
      default:
        return JoinRequestStatus.pending;
    }
  }

  static String _statusToString(JoinRequestStatus status) {
    switch (status) {
      case JoinRequestStatus.approved:
        return 'approved';
      case JoinRequestStatus.rejected:
        return 'rejected';
      case JoinRequestStatus.pending:
        return 'pending';
    }
  }

  /// Check if request is pending
  bool get isPending => status == JoinRequestStatus.pending;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForumJoinRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
