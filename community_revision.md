# ITEL Community Revision - Implementation Guide

This document contains instructions for applying the community feature revisions to your iOS Flutter repository.

## Summary of Changes

### 1. Ask ITEL Revisions
- Changed "Contact ITEL Support" to "Contact ITEL"
- Added staff notification system with badge counts for unviewed/unreplied tickets
- Track which staff have viewed tickets (NEW/No Reply indicators)

### 2. Forum Revisions
- Staff auto-access to all forums without being listed as members
- Staff can close forums and kick any user
- Better pending forum display for staff (clear Subject/Description sections)
- Invitation system - invited users must accept before joining
- UI changes: view members and invite icons in app bar, three dots for other options

### 3. ITEL Community (Global Chat) Revisions
- Staff can remove any message without trace (clean delete)
- Staff can give cooldown (temporary chat ban with duration options)
- Staff can kick users (permanent chat ban)
- Real-time countdown display for cooldown
- Ban status checking before sending messages

---

## Claude Code Prompt for iOS Repository

Copy and paste this prompt to Claude Code on your Mac:

```
I need to apply community feature revisions to my iOS Flutter repository. These changes are already implemented in my Android repository.

Please help me:

1. CREATE two new model files (I'll provide the code below)
2. COPY and replace these files from my description

## NEW FILES TO CREATE:

### 1. Create `lib/models/chat_ban.dart`:

import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatBanType {
  cooldown,
  kicked,
}

class ChatBan {
  final String id;
  final String odGptUserId;
  final String userName;
  final String userEmail;
  final ChatBanType banType;
  final String bannedById;
  final String bannedByName;
  final DateTime bannedAt;
  final DateTime? expiresAt;
  final String? reason;

  ChatBan({
    required this.id,
    required this.odGptUserId,
    required this.userName,
    required this.userEmail,
    required this.banType,
    required this.bannedById,
    required this.bannedByName,
    required this.bannedAt,
    this.expiresAt,
    this.reason,
  });

  factory ChatBan.fromJson(Map<String, dynamic> json, String id) {
    return ChatBan(
      id: id,
      odGptUserId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown',
      userEmail: json['userEmail'] as String? ?? '',
      banType: _stringToBanType(json['banType'] as String? ?? 'cooldown'),
      bannedById: json['bannedById'] as String? ?? '',
      bannedByName: json['bannedByName'] as String? ?? 'Unknown',
      bannedAt: _parseTimestamp(json['bannedAt']),
      expiresAt: json['expiresAt'] != null ? _parseTimestamp(json['expiresAt']) : null,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': odGptUserId,
      'userName': userName,
      'userEmail': userEmail,
      'banType': _banTypeToString(banType),
      'bannedById': bannedById,
      'bannedByName': bannedByName,
      'bannedAt': Timestamp.fromDate(bannedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'reason': reason,
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }

  static ChatBanType _stringToBanType(String str) {
    switch (str) {
      case 'kicked': return ChatBanType.kicked;
      case 'cooldown':
      default: return ChatBanType.cooldown;
    }
  }

  static String _banTypeToString(ChatBanType type) {
    switch (type) {
      case ChatBanType.kicked: return 'kicked';
      case ChatBanType.cooldown: return 'cooldown';
    }
  }

  bool get isActive {
    if (banType == ChatBanType.kicked) return true;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  Duration? get remainingCooldown {
    if (banType != ChatBanType.cooldown || expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  String get remainingTimeFormatted {
    final remaining = remainingCooldown;
    if (remaining == null) return '';
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m ${remaining.inSeconds % 60}s';
    } else {
      return '${remaining.inSeconds}s';
    }
  }
}

### 2. Create `lib/models/forum_invitation.dart`:

import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus { pending, accepted, declined }

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
      respondedAt: json['respondedAt'] != null ? _parseTimestamp(json['respondedAt']) : null,
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
      case 'accepted': return InvitationStatus.accepted;
      case 'declined': return InvitationStatus.declined;
      case 'pending':
      default: return InvitationStatus.pending;
    }
  }

  static String _statusToString(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.accepted: return 'accepted';
      case InvitationStatus.declined: return 'declined';
      case InvitationStatus.pending: return 'pending';
    }
  }

  bool get isPending => status == InvitationStatus.pending;
}

## FILES TO REPLACE (copy content from description below):

Please read these files from my current iOS repo and REPLACE their entire content with the versions I'll describe:

### Models to update:
- `lib/models/support_ticket.dart` - Add viewedByStaff (List<String>) and hasStaffReply (bool) fields
- `lib/models/forum_group.dart` - Update isMember method to accept isStaff parameter

### Services to replace completely:
- `lib/services/chat_service.dart` - Add staff moderation methods
- `lib/services/forum_group_service.dart` - Complete invitation system
- `lib/services/support_ticket_service.dart` - Add staff tracking

### Screens to replace completely:
- `lib/screens/ask_itel_screen.dart` - Staff indicators, text change
- `lib/screens/community_screen.dart` - Badge notifications
- `lib/screens/forum_chat_screen.dart` - Staff access, app bar
- `lib/screens/forum_list_screen.dart` - Invitation UI
- `lib/screens/global_chat_screen.dart` - Staff moderation, ban display
- `lib/screens/support_chat_screen.dart` - Staff view tracking

I will provide the complete content for each file. Start with creating the two new model files, then I'll give you the content for each modified file one by one.
```

---

## Quick Copy Method

The easiest way to apply these changes is to:

1. Copy these files from your Android repo (`D:\Documents\ITEL\Mobile App\itel-app-final\lib\`) to your iOS repo:

**New Files (create these):**
- `lib/models/chat_ban.dart`
- `lib/models/forum_invitation.dart`

**Modified Files (replace these):**
- `lib/models/support_ticket.dart`
- `lib/models/forum_group.dart`
- `lib/services/chat_service.dart`
- `lib/services/forum_group_service.dart`
- `lib/services/support_ticket_service.dart`
- `lib/screens/ask_itel_screen.dart`
- `lib/screens/community_screen.dart`
- `lib/screens/forum_chat_screen.dart`
- `lib/screens/forum_list_screen.dart`
- `lib/screens/global_chat_screen.dart`
- `lib/screens/support_chat_screen.dart`

---

## Firestore Collections

The following new Firestore collections are used:

1. **`chat_bans`** - Stores chat bans/cooldowns
   - Fields: `userId`, `userName`, `userEmail`, `banType`, `bannedById`, `bannedByName`, `bannedAt`, `expiresAt`, `reason`

2. **`forum_invitations`** - Stores forum invitations
   - Fields: `forumId`, `forumTitle`, `invitedUserId`, `invitedUserName`, `invitedUserEmail`, `invitedById`, `invitedByName`, `invitedAt`, `status`, `respondedAt`

### Updated Fields in Existing Collections

**`support_tickets`** - Added:
- `viewedByStaff`: List<String>
- `hasStaffReply`: bool

**`forum_groups`** - Added:
- `pendingInvites`: List<Map>

---

## Key Changes Summary

1. **Staff Moderation in ITEL Community:**
   - Long-press any message to see moderation options
   - Delete (clean, no trace), Cooldown (5m/15m/1h/24h), Kick (permanent)
   - Users see ban status with countdown timer

2. **Forum Invitation System:**
   - Inviting during creation stores in `pendingInvites`
   - On approval, invites are sent
   - Users see invitations in "My Forums" tab
   - Must accept to join

3. **Staff Access:**
   - Staff can access all forums without being members
   - Staff see badges for unattended support tickets
   - Staff can close forums and kick any member
