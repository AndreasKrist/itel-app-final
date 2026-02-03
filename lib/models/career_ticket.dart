import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of the career advisory ticket
enum CareerTicketStatus {
  open,      // Active ticket, awaiting response
  resolved,  // Issue resolved
  closed,    // Ticket closed
}

/// Represents a career advisory ticket
class CareerTicket {
  final String id;
  final String creatorId;
  final String creatorName;
  final String creatorEmail;
  final String subject;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CareerTicketStatus status;
  final String? lastMessage;
  final String? lastMessageBy;
  final DateTime? lastMessageAt;
  final int messageCount;
  final List<String> viewedByStaff;
  final bool hasStaffReply;

  CareerTicket({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.creatorEmail,
    required this.subject,
    required this.createdAt,
    required this.updatedAt,
    this.status = CareerTicketStatus.open,
    this.lastMessage,
    this.lastMessageBy,
    this.lastMessageAt,
    this.messageCount = 0,
    this.viewedByStaff = const [],
    this.hasStaffReply = false,
  });

  factory CareerTicket.fromJson(Map<String, dynamic> json, String id) {
    return CareerTicket(
      id: id,
      creatorId: json['creatorId'] as String? ?? '',
      creatorName: json['creatorName'] as String? ?? 'Unknown',
      creatorEmail: json['creatorEmail'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      status: _stringToStatus(json['status'] as String? ?? 'open'),
      lastMessage: json['lastMessage'] as String?,
      lastMessageBy: json['lastMessageBy'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? _parseTimestamp(json['lastMessageAt'])
          : null,
      messageCount: json['messageCount'] as int? ?? 0,
      viewedByStaff: List<String>.from(json['viewedByStaff'] ?? []),
      hasStaffReply: json['hasStaffReply'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorEmail': creatorEmail,
      'subject': subject,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': _statusToString(status),
      'lastMessage': lastMessage,
      'lastMessageBy': lastMessageBy,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'messageCount': messageCount,
      'viewedByStaff': viewedByStaff,
      'hasStaffReply': hasStaffReply,
    };
  }

  CareerTicket copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? creatorEmail,
    String? subject,
    DateTime? createdAt,
    DateTime? updatedAt,
    CareerTicketStatus? status,
    String? lastMessage,
    String? lastMessageBy,
    DateTime? lastMessageAt,
    int? messageCount,
    List<String>? viewedByStaff,
    bool? hasStaffReply,
  }) {
    return CareerTicket(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorEmail: creatorEmail ?? this.creatorEmail,
      subject: subject ?? this.subject,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageBy: lastMessageBy ?? this.lastMessageBy,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messageCount: messageCount ?? this.messageCount,
      viewedByStaff: viewedByStaff ?? this.viewedByStaff,
      hasStaffReply: hasStaffReply ?? this.hasStaffReply,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  static CareerTicketStatus _stringToStatus(String statusString) {
    switch (statusString) {
      case 'resolved':
        return CareerTicketStatus.resolved;
      case 'closed':
        return CareerTicketStatus.closed;
      case 'open':
      default:
        return CareerTicketStatus.open;
    }
  }

  static String _statusToString(CareerTicketStatus status) {
    switch (status) {
      case CareerTicketStatus.resolved:
        return 'resolved';
      case CareerTicketStatus.closed:
        return 'closed';
      case CareerTicketStatus.open:
        return 'open';
    }
  }

  bool get isOpen => status == CareerTicketStatus.open;

  bool hasBeenViewedByStaff(String staffId) => viewedByStaff.contains(staffId);

  bool get needsStaffAttention => status == CareerTicketStatus.open && !hasStaffReply;

  bool canReply(String userId, bool isStaff) {
    return creatorId == userId || isStaff;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CareerTicket && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
