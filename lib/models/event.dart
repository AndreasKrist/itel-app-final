import 'package:cloud_firestore/cloud_firestore.dart';

/// Event model - represents an event with chat capability
/// Vouchers are created separately and linked to events
class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;
  final String createdBy;    // Staff user ID who created it
  final String createdByName;

  // Sharing to global chat
  final bool isSharedToGlobalChat;
  final DateTime? sharedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    this.isSharedToGlobalChat = false,
    this.sharedAt,
  });

  /// Check if event is currently active (within time window)
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Check if event hasn't started yet
  bool get isPending {
    return DateTime.now().isBefore(startTime);
  }

  /// Check if event has expired
  bool get isExpired {
    return DateTime.now().isAfter(endTime);
  }

  /// Get remaining time until expiry
  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }

  /// Get time until event starts (for pending events)
  Duration get timeUntilStart {
    final now = DateTime.now();
    if (now.isAfter(startTime)) return Duration.zero;
    return startTime.difference(now);
  }

  /// Get formatted remaining time string
  String get remainingTimeFormatted {
    final remaining = remainingTime;
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m ${remaining.inSeconds % 60}s';
    } else {
      return '${remaining.inSeconds}s';
    }
  }

  /// Get status text for display
  String get statusText {
    if (isExpired) return 'Ended';
    if (isPending) return 'Coming Soon';
    return 'Live Now';
  }

  /// Create from Firestore document
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      isSharedToGlobalChat: data['isSharedToGlobalChat'] ?? false,
      sharedAt: data['sharedAt'] != null
          ? (data['sharedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'isSharedToGlobalChat': isSharedToGlobalChat,
      'sharedAt': sharedAt != null ? Timestamp.fromDate(sharedAt!) : null,
    };
  }

  /// Copy with method
  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    String? createdBy,
    String? createdByName,
    bool? isSharedToGlobalChat,
    DateTime? sharedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      isSharedToGlobalChat: isSharedToGlobalChat ?? this.isSharedToGlobalChat,
      sharedAt: sharedAt ?? this.sharedAt,
    );
  }
}
