import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of the support ticket
enum TicketStatus {
  open,      // Active ticket, awaiting response
  resolved,  // Issue resolved
  closed,    // Ticket closed
}

/// Represents a support ticket in Ask ITEL
class SupportTicket {
  final String id;
  final String creatorId;
  final String creatorName;
  final String creatorEmail;
  final String subject;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TicketStatus status;
  final String? lastMessage;
  final String? lastMessageBy;
  final DateTime? lastMessageAt;
  final int messageCount;
  final List<String> viewedByStaff;  // Staff IDs who have opened this ticket
  final bool hasStaffReply;          // Whether any staff has replied

  SupportTicket({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.creatorEmail,
    required this.subject,
    required this.createdAt,
    required this.updatedAt,
    this.status = TicketStatus.open,
    this.lastMessage,
    this.lastMessageBy,
    this.lastMessageAt,
    this.messageCount = 0,
    this.viewedByStaff = const [],
    this.hasStaffReply = false,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json, String id) {
    return SupportTicket(
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

  SupportTicket copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? creatorEmail,
    String? subject,
    DateTime? createdAt,
    DateTime? updatedAt,
    TicketStatus? status,
    String? lastMessage,
    String? lastMessageBy,
    DateTime? lastMessageAt,
    int? messageCount,
    List<String>? viewedByStaff,
    bool? hasStaffReply,
  }) {
    return SupportTicket(
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

  static TicketStatus _stringToStatus(String statusString) {
    switch (statusString) {
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      case 'open':
      default:
        return TicketStatus.open;
    }
  }

  static String _statusToString(TicketStatus status) {
    switch (status) {
      case TicketStatus.resolved:
        return 'resolved';
      case TicketStatus.closed:
        return 'closed';
      case TicketStatus.open:
        return 'open';
    }
  }

  /// Check if the ticket is still open
  bool get isOpen => status == TicketStatus.open;

  /// Check if a specific staff member has viewed this ticket
  bool hasBeenViewedByStaff(String staffId) => viewedByStaff.contains(staffId);

  /// Check if this ticket needs attention (open + no staff reply yet)
  bool get needsStaffAttention => status == TicketStatus.open && !hasStaffReply;

  /// Check if a user can reply to this ticket
  bool canReply(String userId, bool isStaff) {
    return creatorId == userId || isStaff;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupportTicket && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
