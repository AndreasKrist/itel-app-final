# Community, Ask ITEL & Forum Implementation Guide

This document provides a comprehensive implementation guide for the Community section overhaul, including the Ask ITEL support ticket system and Forum group chat system.

## Overview

The Community section has been restructured from 2 tabs to 3 tabs:
1. **Ask ITEL** - Support ticket system where users can contact ITEL staff
2. **Forum** - Group forums where users can create and join community groups
3. **ITEL Community** - Global chat (existing implementation)

### Key Features

**Ask ITEL (Support Tickets):**
- Users create support tickets with subject and initial message
- Only ticket creator and ITEL staff can reply
- Staff can see all tickets; users see only their own
- Tickets have status: Open, Resolved, Closed
- Extended FAB with "Create Question" label

**Forum System:**
- Users create forums (requires staff approval)
- Public forums: anyone can join directly
- Private forums: need creator approval to join
- Forum visibility: Public/Private badge
- Join requests for private forums
- Creator can invite members to existing forums
- Creator can kick members (requires reason)
- Staff can kick members (no reason required)
- Staff can approve/reject forums (rejection reason is required)
- Users can see rejected/pending forums in "My Forums" with reason displayed
- Kick logs for audit trail
- Extended FAB with "Create Forum" label

## File Structure

```
lib/
├── models/
│   ├── support_ticket.dart
│   ├── support_message.dart
│   ├── forum_group.dart
│   ├── forum_member.dart
│   ├── forum_message.dart
│   ├── forum_join_request.dart
│   └── forum_kick_log.dart
├── services/
│   ├── support_ticket_service.dart
│   └── forum_group_service.dart
├── screens/
│   ├── community_screen.dart (modified)
│   ├── ask_itel_screen.dart
│   ├── support_chat_screen.dart
│   ├── forum_list_screen.dart
│   ├── create_forum_screen.dart
│   ├── forum_chat_screen.dart
│   └── forum_members_screen.dart
└── widgets/
    └── support_message_bubble.dart
```

---

## 1. Models

### 1.1 SupportTicket Model

Create `lib/models/support_ticket.dart`:

```dart
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
```

### 1.2 SupportMessage Model

Create `lib/models/support_message.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Message type for support messages
enum SupportMessageType {
  text,
  system, // For system notifications like "ticket created", "ticket resolved"
}

/// Represents a single message in a support ticket conversation
class SupportMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String content;
  final DateTime createdAt;
  final SupportMessageType type;
  final bool isStaffMessage;
  final DateTime? deletedAt;
  final String? deletedBy;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.content,
    required this.createdAt,
    this.type = SupportMessageType.text,
    this.isStaffMessage = false,
    this.deletedAt,
    this.deletedBy,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json, String id) {
    return SupportMessage(
      id: id,
      ticketId: json['ticketId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderEmail: json['senderEmail'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      type: SupportMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SupportMessageType.text,
      ),
      isStaffMessage: json['isStaffMessage'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null ? _parseTimestamp(json['deletedAt']) : null,
      deletedBy: json['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type.name,
      'isStaffMessage': isStaffMessage,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy,
    };
  }

  SupportMessage copyWith({
    String? id,
    String? ticketId,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? content,
    DateTime? createdAt,
    SupportMessageType? type,
    bool? isStaffMessage,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return SupportMessage(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isStaffMessage: isStaffMessage ?? this.isStaffMessage,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  /// Check if this message is from a specific user
  bool isFromUser(String userId) => senderId == userId;

  /// Check if the message has been deleted
  bool get isDeleted => deletedAt != null;

  /// Get the display content (shows placeholder if deleted)
  String get displayContent {
    if (isDeleted) {
      return 'This message was deleted';
    }
    return content;
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
    return other is SupportMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
```

### 1.3 ForumGroup Model

Create `lib/models/forum_group.dart`:

```dart
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

  /// Check if user is a member
  bool isMember(String userId) => memberIds.contains(userId);

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
```

### 1.4 ForumMember Model

Create `lib/models/forum_member.dart`:

```dart
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
```

### 1.5 ForumMessage Model

Create `lib/models/forum_message.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Message type for forum messages
enum ForumMessageType {
  text,    // Regular text message
  system,  // System message (user joined, left, kicked, etc.)
}

/// Represents a message in a forum chat
class ForumMessage {
  final String id;
  final String forumId;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String content;
  final DateTime createdAt;
  final ForumMessageType type;
  final DateTime? deletedAt;
  final String? deletedBy;

  ForumMessage({
    required this.id,
    required this.forumId,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.content,
    required this.createdAt,
    this.type = ForumMessageType.text,
    this.deletedAt,
    this.deletedBy,
  });

  factory ForumMessage.fromJson(Map<String, dynamic> json, String id) {
    return ForumMessage(
      id: id,
      forumId: json['forumId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderEmail: json['senderEmail'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      type: ForumMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ForumMessageType.text,
      ),
      deletedAt: json['deletedAt'] != null ? _parseTimestamp(json['deletedAt']) : null,
      deletedBy: json['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forumId': forumId,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type.name,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy,
    };
  }

  ForumMessage copyWith({
    String? id,
    String? forumId,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? content,
    DateTime? createdAt,
    ForumMessageType? type,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return ForumMessage(
      id: id ?? this.id,
      forumId: forumId ?? this.forumId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  /// Check if this message is from a specific user
  bool isFromUser(String odGptUserId) => senderId == odGptUserId;

  /// Check if the message has been deleted
  bool get isDeleted => deletedAt != null;

  /// Get the display content (shows placeholder if deleted)
  String get displayContent {
    if (isDeleted) {
      return 'This message was deleted';
    }
    return content;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForumMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
```

### 1.6 ForumJoinRequest Model

Create `lib/models/forum_join_request.dart`:

```dart
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
```

### 1.7 ForumKickLog Model

Create `lib/models/forum_kick_log.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of kick action
enum KickType {
  kickedByCreator,  // Kicked by forum creator (requires reason)
  kickedByStaff,    // Kicked by ITEL staff (no reason required)
  forumRemoved,     // Forum was removed by staff
}

/// Represents a kick/removal log entry in a forum
class ForumKickLog {
  final String id;
  final String forumId;
  final String forumTitle;
  final String kickedUserId;
  final String kickedUserName;
  final String kickedUserEmail;
  final String kickedById;
  final String kickedByName;
  final String kickedByEmail;
  final bool kickedByStaff;
  final KickType kickType;
  final String reason; // Required for creator kicks
  final DateTime kickedAt;

  ForumKickLog({
    required this.id,
    required this.forumId,
    required this.forumTitle,
    required this.kickedUserId,
    required this.kickedUserName,
    required this.kickedUserEmail,
    required this.kickedById,
    required this.kickedByName,
    required this.kickedByEmail,
    required this.kickedByStaff,
    required this.kickType,
    required this.reason,
    required this.kickedAt,
  });

  factory ForumKickLog.fromJson(Map<String, dynamic> json, String id) {
    return ForumKickLog(
      id: id,
      forumId: json['forumId'] as String? ?? '',
      forumTitle: json['forumTitle'] as String? ?? '',
      kickedUserId: json['kickedUserId'] as String? ?? '',
      kickedUserName: json['kickedUserName'] as String? ?? 'Unknown',
      kickedUserEmail: json['kickedUserEmail'] as String? ?? '',
      kickedById: json['kickedById'] as String? ?? '',
      kickedByName: json['kickedByName'] as String? ?? 'Unknown',
      kickedByEmail: json['kickedByEmail'] as String? ?? '',
      kickedByStaff: json['kickedByStaff'] as bool? ?? false,
      kickType: _stringToKickType(json['kickType'] as String? ?? 'kickedByCreator'),
      reason: json['reason'] as String? ?? '',
      kickedAt: _parseTimestamp(json['kickedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forumId': forumId,
      'forumTitle': forumTitle,
      'kickedUserId': kickedUserId,
      'kickedUserName': kickedUserName,
      'kickedUserEmail': kickedUserEmail,
      'kickedById': kickedById,
      'kickedByName': kickedByName,
      'kickedByEmail': kickedByEmail,
      'kickedByStaff': kickedByStaff,
      'kickType': _kickTypeToString(kickType),
      'reason': reason,
      'kickedAt': Timestamp.fromDate(kickedAt),
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  static KickType _stringToKickType(String str) {
    switch (str) {
      case 'kickedByStaff':
        return KickType.kickedByStaff;
      case 'forumRemoved':
        return KickType.forumRemoved;
      case 'kickedByCreator':
      default:
        return KickType.kickedByCreator;
    }
  }

  static String _kickTypeToString(KickType type) {
    switch (type) {
      case KickType.kickedByStaff:
        return 'kickedByStaff';
      case KickType.forumRemoved:
        return 'forumRemoved';
      case KickType.kickedByCreator:
        return 'kickedByCreator';
    }
  }

  /// Get display text for kick type
  String get kickTypeDisplay {
    switch (kickType) {
      case KickType.kickedByStaff:
        return 'Kicked by staff';
      case KickType.forumRemoved:
        return 'Forum removed';
      case KickType.kickedByCreator:
        return 'Kicked by creator';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForumKickLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
```

---

## 2. Services

Due to the length of the services, please refer to the actual source files:
- `lib/services/support_ticket_service.dart`
- `lib/services/forum_group_service.dart`

The services handle all Firestore operations including:

**SupportTicketService:**
- `getAllTicketsStream()` - For staff to see all tickets
- `getUserTicketsStream(userId)` - For users to see their tickets
- `getTicketStream(ticketId)` - Stream single ticket
- `createTicket()` - Create new ticket with initial message
- `updateTicketStatus()` - Change ticket status
- `deleteTicket()` - Delete ticket and all messages
- `getMessagesStream(ticketId)` - Stream messages
- `sendMessage()` - Send message (validates user can reply)
- `deleteMessage()` - Soft delete message

**ForumGroupService:**
- `getApprovedForumsStream()` - Public view of approved forums
- `getAllForumsStream()` - Staff moderation view
- `getPendingForumsStream()` - Staff approval queue
- `getUserForumsStream(userId)` - User's forums (includes rejected/pending if creator)
- `getForumStream(forumId)` - Single forum stream
- `createForum()` - Create with initial members
- `approveForum()` - Staff approves forum
- `rejectForum()` - Staff rejects forum (reason required)
- `removeForum()` - Staff removes forum (logs for all members)
- `getMembersStream(forumId)` - Active members
- `getMember()` - Get specific member
- `addMember()` - Add member with system message
- `kickMember()` - Kick with reason and log
- `leaveForum()` - Member leaves voluntarily
- `getJoinRequestsStream()` - Pending join requests
- `requestJoin()` - Request to join private forum
- `approveJoinRequest()` - Creator approves request
- `rejectJoinRequest()` - Creator rejects request
- `getMessagesStream()` - Forum messages
- `sendMessage()` - Send message
- `deleteMessage()` - Soft delete message
- `getKickLogsStream()` - Kick history
- `getUserKickLogs()` - User's kick history
- `searchUsersByEmail()` - For inviting members

---

## 3. Screens

Due to the length of the screens, please refer to the actual source files:
- `lib/screens/community_screen.dart`
- `lib/screens/ask_itel_screen.dart`
- `lib/screens/support_chat_screen.dart`
- `lib/screens/forum_list_screen.dart`
- `lib/screens/create_forum_screen.dart`
- `lib/screens/forum_chat_screen.dart`
- `lib/screens/forum_members_screen.dart`

### Key UI Patterns:

**Extended FAB with Text Label:**
```dart
floatingActionButton: FloatingActionButton.extended(
  onPressed: () => _action(),
  backgroundColor: const Color(0xFF0056AC),
  icon: const Icon(Icons.add, color: Colors.white),
  label: const Text(
    'Create Forum', // or 'Create Question'
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
  ),
),
```

**Rejected Forum Card with Reason:**
```dart
// Show rejection reason
if (isRejected && forum.rejectionReason != null && forum.rejectionReason!.isNotEmpty) ...[
  const SizedBox(height: 12),
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
            const SizedBox(width: 6),
            Text(
              'Rejection Reason:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          forum.rejectionReason!,
          style: TextStyle(
            fontSize: 13,
            color: Colors.red[700],
          ),
        ),
      ],
    ),
  ),
],
```

**Required Rejection Reason Validation:**
```dart
TextButton(
  onPressed: () {
    if (reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for rejection'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.pop(context, true);
  },
  style: TextButton.styleFrom(foregroundColor: Colors.red),
  child: const Text('Reject'),
),
```

**Invite Members Dialog with StatefulBuilder:**
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (context) => StatefulBuilder(
    builder: (context, setModalState) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        // ... invite members UI
      ),
    ),
  ),
);
```

---

## 4. Widgets

### SupportMessageBubble Widget

Create `lib/widgets/support_message_bubble.dart` with the content from the actual file.

Key features:
- Handles system messages (centered, gray background)
- Handles deleted messages (placeholder text)
- Shows staff badge for staff messages
- Different styling for current user vs others
- Long press to delete own messages

---

## 5. Firestore Security Rules

Add these rules to your Firebase Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper function to check if user is staff
    function isStaff() {
      return request.auth != null &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isStaff == true;
    }

    // Support Tickets
    match /support_tickets/{ticketId} {
      allow read: if request.auth != null &&
                  (resource.data.creatorId == request.auth.uid || isStaff());
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
                    (resource.data.creatorId == request.auth.uid || isStaff());
      allow delete: if request.auth != null &&
                    (resource.data.creatorId == request.auth.uid || isStaff());

      // Messages subcollection
      match /messages/{messageId} {
        allow read: if request.auth != null &&
                    (get(/databases/$(database)/documents/support_tickets/$(ticketId)).data.creatorId == request.auth.uid || isStaff());
        allow create: if request.auth != null &&
                      (get(/databases/$(database)/documents/support_tickets/$(ticketId)).data.creatorId == request.auth.uid || isStaff());
        allow update: if request.auth != null && resource.data.senderId == request.auth.uid;
        allow delete: if false;
      }
    }

    // Forum Groups
    match /forum_groups/{forumId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
                    (resource.data.creatorId == request.auth.uid ||
                     resource.data.memberIds.hasAny([request.auth.uid]) ||
                     isStaff());
      allow delete: if request.auth != null && isStaff();

      // Members subcollection
      match /members/{memberId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
        allow update: if request.auth != null &&
                      (get(/databases/$(database)/documents/forum_groups/$(forumId)).data.creatorId == request.auth.uid || isStaff());
        allow delete: if false;
      }

      // Messages subcollection
      match /messages/{messageId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null &&
                      get(/databases/$(database)/documents/forum_groups/$(forumId)).data.memberIds.hasAny([request.auth.uid]);
        allow update: if request.auth != null && resource.data.senderId == request.auth.uid;
        allow delete: if false;
      }

      // Join requests subcollection
      match /join_requests/{requestId} {
        allow read: if request.auth != null &&
                    (get(/databases/$(database)/documents/forum_groups/$(forumId)).data.creatorId == request.auth.uid ||
                     resource.data.userId == request.auth.uid ||
                     isStaff());
        allow create: if request.auth != null;
        allow update: if request.auth != null &&
                      (get(/databases/$(database)/documents/forum_groups/$(forumId)).data.creatorId == request.auth.uid || isStaff());
        allow delete: if false;
      }
    }

    // Forum Kick Logs
    match /forum_kick_logs/{logId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if false;
      allow delete: if false;
    }
  }
}
```

---

## 6. Firestore Indexes

Create the following composite indexes in Firebase Console:

### Support Tickets Collection
1. Collection: `support_tickets`
   - Field: `creatorId` (Ascending)
   - Field: `updatedAt` (Descending)

2. Collection: `support_tickets`
   - Field: `updatedAt` (Descending)

### Forum Groups Collection
1. Collection: `forum_groups`
   - Field: `approvalStatus` (Ascending)
   - Field: `updatedAt` (Descending)

2. Collection: `forum_groups`
   - Field: `memberIds` (Arrays)
   - Field: `approvalStatus` (Ascending)
   - Field: `updatedAt` (Descending)

3. Collection: `forum_groups`
   - Field: `creatorId` (Ascending)
   - Field: `approvalStatus` (Ascending)

4. Collection: `forum_groups`
   - Field: `approvalStatus` (Ascending)
   - Field: `createdAt` (Descending)

### Forum Members Subcollection
1. Collection Group: `members`
   - Field: `isActive` (Ascending)
   - Field: `joinedAt` (Ascending)

### Forum Join Requests Subcollection
1. Collection: `forum_groups/{forumId}/join_requests`
   - Field: `status` (Ascending)
   - Field: `requestedAt` (Ascending)

### Forum Kick Logs Collection
1. Collection: `forum_kick_logs`
   - Field: `forumId` (Ascending)
   - Field: `kickedAt` (Descending)

---

## 7. Testing Checklist

### Ask ITEL (Support Tickets)
- [ ] Guest users see sign-in message
- [ ] Users can create tickets with subject and message
- [ ] Users see only their tickets
- [ ] Staff see all tickets
- [ ] Extended FAB shows "Create Question"
- [ ] Can send messages in ticket
- [ ] Can delete own messages
- [ ] Can mark ticket as resolved
- [ ] Staff can close tickets
- [ ] Can reopen resolved tickets

### Forum System
- [ ] Guest users see forums but cannot join
- [ ] Users can create forums (pending approval)
- [ ] Staff see "Pending" tab
- [ ] Staff can approve forums
- [ ] Staff can reject forums (reason required)
- [ ] Creator sees rejected forums with reason in "My Forums"
- [ ] Creator sees pending forums with status in "My Forums"
- [ ] Extended FAB shows "Create Forum"
- [ ] Public forums allow direct join
- [ ] Private forums show "Request to Join"
- [ ] Creator sees join requests
- [ ] Creator can approve/reject join requests
- [ ] Creator can invite members to existing forums
- [ ] Creator can kick members (reason required)
- [ ] Staff can kick members (no reason required)
- [ ] Kick logs are recorded and visible
- [ ] Members can leave forums
- [ ] Messages can be sent and deleted
- [ ] System messages appear for joins/leaves/kicks

---

## 8. Color Constants

Primary colors used throughout:
- Primary Blue: `Color(0xFF0056AC)`
- Secondary Orange: `Color(0xFFFF6600)`
- Success Green: `Colors.green`
- Warning Orange: `Colors.orange`
- Error Red: `Colors.red`

---

## Notes

1. The `User.currentUser` is assumed to have `id`, `name`, `email`, and `isStaff` properties.
2. All timestamps use Firestore `Timestamp` for storage and `DateTime` for local manipulation.
3. Soft delete is used for messages (sets `deletedAt` instead of removing).
4. The `memberIds` array in `ForumGroup` enables efficient membership queries.
5. Field name is `updatedAt` (not `lastActivityAt`) - ensure indexes match this.
