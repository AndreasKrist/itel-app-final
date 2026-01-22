import 'package:cloud_firestore/cloud_firestore.dart';

/// Discount type for vouchers
enum DiscountType {
  percentage, // e.g., 50% off
  fixed,      // e.g., $20 off
}

/// Voucher model for flash sales
class Voucher {
  final String id;
  final String code;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final DateTime startTime;
  final DateTime endTime;
  final int? maxClaims;      // null = unlimited
  final int currentClaims;
  final String? courseId;    // Optional: specific course discount
  final String? paymentLink; // Optional: for future payment integration
  final DateTime createdAt;
  final String createdBy;    // Admin user ID who created it

  Voucher({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.startTime,
    required this.endTime,
    this.maxClaims,
    this.currentClaims = 0,
    this.courseId,
    this.paymentLink,
    required this.createdAt,
    required this.createdBy,
  });

  /// Check if voucher is currently active (within time window)
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Check if voucher hasn't started yet
  bool get isPending {
    return DateTime.now().isBefore(startTime);
  }

  /// Check if voucher has expired
  bool get isExpired {
    return DateTime.now().isAfter(endTime);
  }

  /// Check if voucher has reached max claims
  bool get isFullyClaimed {
    if (maxClaims == null) return false;
    return currentClaims >= maxClaims!;
  }

  /// Check if voucher can still be claimed
  bool get canBeClaimed {
    return isActive && !isFullyClaimed;
  }

  /// Get remaining time until expiry
  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }

  /// Get remaining claims (null if unlimited)
  int? get remainingClaims {
    if (maxClaims == null) return null;
    return maxClaims! - currentClaims;
  }

  /// Get formatted discount text
  String get discountText {
    if (discountType == DiscountType.percentage) {
      return '${discountValue.toInt()}% OFF';
    } else {
      return '\$${discountValue.toStringAsFixed(2)} OFF';
    }
  }

  /// Create from Firestore document
  factory Voucher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Voucher(
      id: doc.id,
      code: data['code'] ?? '',
      description: data['description'] ?? '',
      discountType: data['discountType'] == 'fixed'
          ? DiscountType.fixed
          : DiscountType.percentage,
      discountValue: (data['discountValue'] ?? 0).toDouble(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      maxClaims: data['maxClaims'],
      currentClaims: data['currentClaims'] ?? 0,
      courseId: data['courseId'],
      paymentLink: data['paymentLink'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'description': description,
      'discountType': discountType == DiscountType.fixed ? 'fixed' : 'percentage',
      'discountValue': discountValue,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'maxClaims': maxClaims,
      'currentClaims': currentClaims,
      'courseId': courseId,
      'paymentLink': paymentLink,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  /// Copy with method
  Voucher copyWith({
    String? id,
    String? code,
    String? description,
    DiscountType? discountType,
    double? discountValue,
    DateTime? startTime,
    DateTime? endTime,
    int? maxClaims,
    int? currentClaims,
    String? courseId,
    String? paymentLink,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Voucher(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxClaims: maxClaims ?? this.maxClaims,
      currentClaims: currentClaims ?? this.currentClaims,
      courseId: courseId ?? this.courseId,
      paymentLink: paymentLink ?? this.paymentLink,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
