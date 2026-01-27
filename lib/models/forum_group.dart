import 'package:cloud_firestore/cloud_firestore.dart';

/// Visibility type for forums
enum ForumVisibility {
  public,   // Anyone can join directly
  private,  // Need to request and get approved by creator
}

/// Approval status for forums
enum ForumApprovalStatus {
  pending,   // Waiting for staff/admin approval
  approved,  // Approved and visible
  rejected,  // Rejected by staff/admin
}

/// Represents a forum/group where members can chat
class ForumGroup {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String creatorName;
  final String creatorEmail;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ForumVisibility visibility;
  final ForumApprovalStatus approvalStatus;
  final String? rejectionReason;
  final String? approvedBy;
  final DateTime? approvedAt;
  final int memberCount;
  final String? lastMessage;
  final String? lastMessageBy;
  final DateTime? lastMessageAt;
  final List<String> memberIds; // List of member user IDs for quick access

  ForumGroup({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.creatorEmail,
    required this.createdAt,
    required this.updatedAt,
    this.visibility = ForumVisibility.public,
    this.approvalStatus = ForumApprovalStatus.pending,
    this.rejectionReason,
    this.approvedBy,
    this.approvedAt,
    this.memberCount = 1,
    this.lastMessage,
    this.lastMessageBy,
    this.lastMessageAt,
    this.memberIds = const [],
  });

  factory ForumGroup.fromJson(Map<String, dynamic> json, String id) {
    return ForumGroup(
      id: id,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      creatorId: json['creatorId'] as String? ?? '',
      creatorName: json['creatorName'] as String? ?? 'Unknown',
      creatorEmail: json['creatorEmail'] as String? ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      visibility: _stringToVisibility(json['visibility'] as String? ?? 'public'),
      approvalStatus: _stringToApprovalStatus(json['approvalStatus'] as String? ?? 'pending'),
      rejectionReason: json['rejectionReason'] as String?,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null ? _parseTimestamp(json['approvedAt']) : null,
      memberCount: json['memberCount'] as int? ?? 1,
      lastMessage: json['lastMessage'] as String?,
      lastMessageBy: json['lastMessageBy'] as String?,
      lastMessageAt: json['lastMessageAt'] != null ? _parseTimestamp(json['lastMessageAt']) : null,
      memberIds: (json['memberIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorEmail': creatorEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'visibility': _visibilityToString(visibility),
      'approvalStatus': _approvalStatusToString(approvalStatus),
      'rejectionReason': rejectionReason,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'memberCount': memberCount,
      'lastMessage': lastMessage,
      'lastMessageBy': lastMessageBy,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'memberIds': memberIds,
    };
  }

  ForumGroup copyWith({
    String? id,
    String? title,
    String? description,
    String? creatorId,
    String? creatorName,
    String? creatorEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    ForumVisibility? visibility,
    ForumApprovalStatus? approvalStatus,
    String? rejectionReason,
    String? approvedBy,
    DateTime? approvedAt,
    int? memberCount,
    String? lastMessage,
    String? lastMessageBy,
    DateTime? lastMessageAt,
    List<String>? memberIds,
  }) {
    return ForumGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorEmail: creatorEmail ?? this.creatorEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      visibility: visibility ?? this.visibility,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      memberCount: memberCount ?? this.memberCount,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageBy: lastMessageBy ?? this.lastMessageBy,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      memberIds: memberIds ?? this.memberIds,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  static ForumVisibility _stringToVisibility(String str) {
    switch (str) {
      case 'private':
        return ForumVisibility.private;
      case 'public':
      default:
        return ForumVisibility.public;
    }
  }

  static String _visibilityToString(ForumVisibility visibility) {
    switch (visibility) {
      case ForumVisibility.private:
        return 'private';
      case ForumVisibility.public:
        return 'public';
    }
  }

  static ForumApprovalStatus _stringToApprovalStatus(String str) {
    switch (str) {
      case 'approved':
        return ForumApprovalStatus.approved;
      case 'rejected':
        return ForumApprovalStatus.rejected;
      case 'pending':
      default:
        return ForumApprovalStatus.pending;
    }
  }

  static String _approvalStatusToString(ForumApprovalStatus status) {
    switch (status) {
      case ForumApprovalStatus.approved:
        return 'approved';
      case ForumApprovalStatus.rejected:
        return 'rejected';
      case ForumApprovalStatus.pending:
        return 'pending';
    }
  }

  /// Check if user is the creator
  bool isCreator(String userId) => creatorId == userId;

  /// Check if user is a member (staff has implicit access to all forums)
  bool isMember(String userId, {bool isStaff = false}) =>
      memberIds.contains(userId) || isStaff;

  /// Check if forum is approved and visible
  bool get isApproved => approvalStatus == ForumApprovalStatus.approved;

  /// Check if forum is public
  bool get isPublic => visibility == ForumVisibility.public;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForumGroup && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
