import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionStatus {
  open,
  resolved,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForumQuestion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
