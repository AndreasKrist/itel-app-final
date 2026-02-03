import 'package:cloud_firestore/cloud_firestore.dart';

/// Discount type for event vouchers
enum DiscountType {
  percentage, // e.g., 50% off
  fixed,      // e.g., $20 off
}

/// EventVoucher model - represents a voucher within an event
/// Multiple vouchers can be created for a single event
class EventVoucher {
  final String id;
  final String eventId;
  final String code;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final int? maxClaims;      // null = unlimited
  final int currentClaims;
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;
  final bool isActive;       // Staff can deactivate a voucher
  final DateTime? expiresAt; // null = follows event end time
  final bool showRemainingCount;  // Whether to show remaining claims to users

  EventVoucher({
    required this.id,
    required this.eventId,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.maxClaims,
    this.currentClaims = 0,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    this.isActive = true,
    this.expiresAt,
    this.showRemainingCount = true,
  });

  /// Check if voucher has reached max claims
  bool get isFullyClaimed {
    if (maxClaims == null) return false;
    return currentClaims >= maxClaims!;
  }

  /// Check if voucher has its own expiry and is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if voucher can still be claimed
  bool get canBeClaimed {
    return isActive && !isFullyClaimed && !isExpired;
  }

  /// Get remaining claims (null if unlimited)
  int? get remainingClaims {
    if (maxClaims == null) return null;
    return maxClaims! - currentClaims;
  }

  /// Get remaining time until voucher expires (null if no expiry)
  Duration? get remainingTime {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get formatted discount text
  String get discountText {
    if (discountType == DiscountType.percentage) {
      return '${discountValue.toInt()}% OFF';
    } else {
      return '\$${discountValue.toStringAsFixed(0)}';
    }
  }

  /// Get status text for display
  String get statusText {
    if (!isActive) return 'Inactive';
    if (isExpired) return 'Expired';
    if (isFullyClaimed) return 'Sold Out';
    return 'Available';
  }

  /// Create from Firestore document
  factory EventVoucher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventVoucher(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      code: data['code'] ?? '',
      description: data['description'] ?? '',
      discountType: data['discountType'] == 'fixed'
          ? DiscountType.fixed
          : DiscountType.percentage,
      discountValue: (data['discountValue'] ?? 0).toDouble(),
      maxClaims: data['maxClaims'],
      currentClaims: data['currentClaims'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      isActive: data['isActive'] ?? true,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      showRemainingCount: data['showRemainingCount'] ?? true,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'code': code,
      'description': description,
      'discountType': discountType == DiscountType.fixed ? 'fixed' : 'percentage',
      'discountValue': discountValue,
      'maxClaims': maxClaims,
      'currentClaims': currentClaims,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'isActive': isActive,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'showRemainingCount': showRemainingCount,
    };
  }

  /// Copy with method
  EventVoucher copyWith({
    String? id,
    String? eventId,
    String? code,
    String? description,
    DiscountType? discountType,
    double? discountValue,
    int? maxClaims,
    int? currentClaims,
    DateTime? createdAt,
    String? createdBy,
    String? createdByName,
    bool? isActive,
    DateTime? expiresAt,
    bool? showRemainingCount,
  }) {
    return EventVoucher(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      code: code ?? this.code,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      maxClaims: maxClaims ?? this.maxClaims,
      currentClaims: currentClaims ?? this.currentClaims,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      showRemainingCount: showRemainingCount ?? this.showRemainingCount,
    );
  }
}
