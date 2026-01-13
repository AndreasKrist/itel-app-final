import 'package:cloud_firestore/cloud_firestore.dart';

class ForumAnswer {
  final String id;
  final String questionId;
  final String authorId;
  final String authorName;
  final String authorEmail;
  final String content;
  final DateTime createdAt;
  final bool isAccepted;

  ForumAnswer({
    required this.id,
    required this.questionId,
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    required this.content,
    required this.createdAt,
    this.isAccepted = false,
  });

  factory ForumAnswer.fromJson(Map<String, dynamic> json, String id) {
    return ForumAnswer(
      id: id,
      questionId: json['questionId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Unknown',
      authorEmail: json['authorEmail'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      isAccepted: json['isAccepted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAccepted': isAccepted,
    };
  }

  ForumAnswer copyWith({
    String? id,
    String? questionId,
    String? authorId,
    String? authorName,
    String? authorEmail,
    String? content,
    DateTime? createdAt,
    bool? isAccepted,
  }) {
    return ForumAnswer(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isAccepted: isAccepted ?? this.isAccepted,
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
    return other is ForumAnswer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
