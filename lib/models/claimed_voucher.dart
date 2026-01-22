import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking claimed vouchers with timing analytics
class ClaimedVoucher {
  final String id;
  final String odGptUserId;      // User who claimed
  final String odGptUserEmail;   // User's email
  final String odGptUserName;    // User's name for display
  final String voucherId;        // Reference to voucher
  final String voucherCode;      // Copy of voucher code
  final String voucherDescription; // Copy of voucher description
  final String discountText;     // e.g., "50% OFF"
  final DateTime claimedAt;      // When they claimed
  final int claimDelaySeconds;   // How fast they claimed (analytics)
  final DateTime voucherStartTime; // When voucher started (to calculate delay)
  final bool isUsed;             // Whether voucher has been redeemed
  final DateTime? usedAt;        // When it was used

  ClaimedVoucher({
    required this.id,
    required this.odGptUserId,
    required this.odGptUserEmail,
    required this.odGptUserName,
    required this.voucherId,
    required this.voucherCode,
    required this.voucherDescription,
    required this.discountText,
    required this.claimedAt,
    required this.claimDelaySeconds,
    required this.voucherStartTime,
    this.isUsed = false,
    this.usedAt,
  });

  /// Get human-readable claim speed for analytics
  String get claimSpeedText {
    if (claimDelaySeconds < 5) {
      return 'Lightning fast! (<5s)';
    } else if (claimDelaySeconds < 30) {
      return 'Very quick (<30s)';
    } else if (claimDelaySeconds < 60) {
      return 'Quick (<1min)';
    } else if (claimDelaySeconds < 300) {
      return 'Within 5 minutes';
    } else if (claimDelaySeconds < 600) {
      return 'Within 10 minutes';
    } else {
      final minutes = claimDelaySeconds ~/ 60;
      return 'After $minutes minutes';
    }
  }

  /// Create from Firestore document
  factory ClaimedVoucher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClaimedVoucher(
      id: doc.id,
      odGptUserId: data['odGptUserId'] ?? '',
      odGptUserEmail: data['odGptUserEmail'] ?? '',
      odGptUserName: data['odGptUserName'] ?? '',
      voucherId: data['voucherId'] ?? '',
      voucherCode: data['voucherCode'] ?? '',
      voucherDescription: data['voucherDescription'] ?? '',
      discountText: data['discountText'] ?? '',
      claimedAt: (data['claimedAt'] as Timestamp).toDate(),
      claimDelaySeconds: data['claimDelaySeconds'] ?? 0,
      voucherStartTime: (data['voucherStartTime'] as Timestamp).toDate(),
      isUsed: data['isUsed'] ?? false,
      usedAt: data['usedAt'] != null
          ? (data['usedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'odGptUserId': odGptUserId,
      'odGptUserEmail': odGptUserEmail,
      'odGptUserName': odGptUserName,
      'voucherId': voucherId,
      'voucherCode': voucherCode,
      'voucherDescription': voucherDescription,
      'discountText': discountText,
      'claimedAt': Timestamp.fromDate(claimedAt),
      'claimDelaySeconds': claimDelaySeconds,
      'voucherStartTime': Timestamp.fromDate(voucherStartTime),
      'isUsed': isUsed,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
    };
  }

  /// Copy with method
  ClaimedVoucher copyWith({
    String? id,
    String? odGptUserId,
    String? odGptUserEmail,
    String? odGptUserName,
    String? voucherId,
    String? voucherCode,
    String? voucherDescription,
    String? discountText,
    DateTime? claimedAt,
    int? claimDelaySeconds,
    DateTime? voucherStartTime,
    bool? isUsed,
    DateTime? usedAt,
  }) {
    return ClaimedVoucher(
      id: id ?? this.id,
      odGptUserId: odGptUserId ?? this.odGptUserId,
      odGptUserEmail: odGptUserEmail ?? this.odGptUserEmail,
      odGptUserName: odGptUserName ?? this.odGptUserName,
      voucherId: voucherId ?? this.voucherId,
      voucherCode: voucherCode ?? this.voucherCode,
      voucherDescription: voucherDescription ?? this.voucherDescription,
      discountText: discountText ?? this.discountText,
      claimedAt: claimedAt ?? this.claimedAt,
      claimDelaySeconds: claimDelaySeconds ?? this.claimDelaySeconds,
      voucherStartTime: voucherStartTime ?? this.voucherStartTime,
      isUsed: isUsed ?? this.isUsed,
      usedAt: usedAt ?? this.usedAt,
    );
  }
}
