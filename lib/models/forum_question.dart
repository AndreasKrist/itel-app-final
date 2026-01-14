import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionStatus {
  open,
  resolved,
}

/// Approval status for question moderation
enum ApprovalStatus {
  pending,   // Waiting for admin/staff approval
  approved,  // Approved and visible to public
  rejected,  // Rejected by moderator
}

class ForumQuestion {
  final String id;
  final String authorId;
  final String authorName;
  final String authorEmail;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int answerCount;
  final QuestionStatus status;
  final String? acceptedAnswerId;
  final ApprovalStatus approvalStatus;  // Moderation status

  ForumQuestion({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    required this.title,
    required this.content,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.answerCount = 0,
    this.status = QuestionStatus.open,
    this.acceptedAnswerId,
    this.approvalStatus = ApprovalStatus.pending,  // Default to pending
  });

  factory ForumQuestion.fromJson(Map<String, dynamic> json, String id) {
    return ForumQuestion(
      id: id,
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Unknown',
      authorEmail: json['authorEmail'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      answerCount: json['answerCount'] as int? ?? 0,
      status: _stringToStatus(json['status'] as String? ?? 'open'),
      acceptedAnswerId: json['acceptedAnswerId'] as String?,
      approvalStatus: _stringToApprovalStatus(json['approvalStatus'] as String? ?? 'pending'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'title': title,
      'content': content,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'answerCount': answerCount,
      'status': _statusToString(status),
      'acceptedAnswerId': acceptedAnswerId,
      'approvalStatus': _approvalStatusToString(approvalStatus),
    };
  }

  ForumQuestion copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorEmail,
    String? title,
    String? content,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? answerCount,
    QuestionStatus? status,
    String? acceptedAnswerId,
    ApprovalStatus? approvalStatus,
  }) {
    return ForumQuestion(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      answerCount: answerCount ?? this.answerCount,
      status: status ?? this.status,
      acceptedAnswerId: acceptedAnswerId ?? this.acceptedAnswerId,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  static QuestionStatus _stringToStatus(String statusString) {
    switch (statusString) {
      case 'resolved':
        return QuestionStatus.resolved;
      case 'open':
      default:
        return QuestionStatus.open;
    }
  }

  static String _statusToString(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.resolved:
        return 'resolved';
      case QuestionStatus.open:
        return 'open';
    }
  }

  static ApprovalStatus _stringToApprovalStatus(String statusString) {
    switch (statusString) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      case 'pending':
      default:
        return ApprovalStatus.pending;
    }
  }

  static String _approvalStatusToString(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.approved:
        return 'approved';
      case ApprovalStatus.rejected:
        return 'rejected';
      case ApprovalStatus.pending:
        return 'pending';
    }
  }

  /// Check if question is visible to public (approved)
  bool get isApproved => approvalStatus == ApprovalStatus.approved;

  /// Check if question is pending moderation
  bool get isPending => approvalStatus == ApprovalStatus.pending;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForumQuestion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
