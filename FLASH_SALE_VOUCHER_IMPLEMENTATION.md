# Flash Sale Voucher System Implementation Guide

This guide documents the complete implementation of a Flash Sale Voucher system for the ITEL Flutter app.

## Features Implemented
- Flash sale vouchers appear in Global Chat with countdown timer
- Admin can create vouchers with time-limited windows (5min, 1hr, etc.)
- Users can claim vouchers within the active period
- Claimed vouchers appear in user's Profile under "My Vouchers"
- Claim timing analytics (tracks how fast users claimed)
- Maximum claim limits per voucher (optional)

---

## FIRESTORE SETUP

### Collections Structure

```
vouchers/{voucherId}
  - code: "FLASH50"
  - description: "50% off Flutter Course"
  - discountType: "percentage" | "fixed"
  - discountValue: 50
  - startTime: Timestamp
  - endTime: Timestamp
  - maxClaims: 100 (optional, null = unlimited)
  - currentClaims: 0
  - courseId: (optional)
  - paymentLink: (optional)
  - createdAt: Timestamp
  - createdBy: "userId"

user_vouchers/{claimId}
  - odGptUserId: "userId"
  - odGptUserEmail: "user@email.com"
  - odGptUserName: "User Name"
  - voucherId: "voucherId"
  - voucherCode: "FLASH50"
  - voucherDescription: "50% off Flutter Course"
  - discountText: "50% OFF"
  - claimedAt: Timestamp
  - claimDelaySeconds: 5
  - voucherStartTime: Timestamp
  - isUsed: false
  - usedAt: null
```

### Firestore Security Rules

Add these rules to your existing Firestore rules:

```javascript
// Vouchers collection (Flash Sales)
match /vouchers/{voucherId} {
  allow read: if true;
  // Admin can do everything
  allow create, delete: if request.auth != null
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
  // Admin can update anything, users can only increment currentClaims
  allow update: if request.auth != null
    && (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
        || (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['currentClaims'])
            && request.resource.data.currentClaims == resource.data.currentClaims + 1));
}

// User Vouchers collection (Claimed vouchers)
match /user_vouchers/{claimId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
  allow update: if request.auth != null
    && resource.data.odGptUserId == request.auth.uid;
}
```

### Firestore Indexes Required

Create this composite index in Firebase Console → Firestore → Indexes:

| Collection ID | Fields |
|---------------|--------|
| `user_vouchers` | `odGptUserId` Ascending, `claimedAt` Descending |

---

## PART 1: MODIFY EXISTING FILES

### File 1: `lib/models/user.dart` (MODIFY EXISTING FILE)

Add `canManageVouchers` permission to `UserRoleExtension`:

```dart
// Find this extension and add the new permission:
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.staff:
        return 'ITEL Staff';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  bool get canAnswerQuestions => this == UserRole.staff || this == UserRole.admin;
  bool get canModerateQuestions => this == UserRole.staff || this == UserRole.admin;
  bool get canManageVouchers => this == UserRole.admin;  // ADD THIS LINE
}
```

Also add helper method to the `User` class (after `isStaff` getter):

```dart
  /// Helper method to check if user is ITEL staff
  bool get isStaff => role.canAnswerQuestions;

  /// Helper method to check if user can manage vouchers (admin only)
  bool get canManageVouchers => role.canManageVouchers;  // ADD THIS
```

---

## PART 2: CREATE NEW MODEL FILES

### File 2: `lib/models/voucher.dart` (CREATE NEW FILE)

```dart
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
```

### File 3: `lib/models/claimed_voucher.dart` (CREATE NEW FILE)

```dart
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
```

---

## PART 3: CREATE SERVICE FILE

### File 4: `lib/services/voucher_service.dart` (CREATE NEW FILE)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voucher.dart';
import '../models/claimed_voucher.dart';

class VoucherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _vouchersRef => _firestore.collection('vouchers');
  CollectionReference get _claimedVouchersRef =>
      _firestore.collection('user_vouchers');

  // ============ VOUCHER MANAGEMENT (Admin) ============

  /// Create a new voucher (admin only)
  Future<String> createVoucher({
    required String code,
    required String description,
    required DiscountType discountType,
    required double discountValue,
    required DateTime startTime,
    required DateTime endTime,
    int? maxClaims,
    String? courseId,
    String? paymentLink,
    required String createdBy,
  }) async {
    final voucher = Voucher(
      id: '',
      code: code.toUpperCase(),
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      startTime: startTime,
      endTime: endTime,
      maxClaims: maxClaims,
      currentClaims: 0,
      courseId: courseId,
      paymentLink: paymentLink,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );

    final docRef = await _vouchersRef.add(voucher.toFirestore());
    return docRef.id;
  }

  /// Get stream of all vouchers (for admin view)
  Stream<List<Voucher>> getAllVouchersStream() {
    return _vouchersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Voucher.fromFirestore(doc)).toList();
    });
  }

  /// Get stream of active vouchers (for users in global chat)
  Stream<List<Voucher>> getActiveVouchersStream() {
    final now = DateTime.now();
    return _vouchersRef
        .where('endTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('endTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Voucher.fromFirestore(doc))
          .where((v) => v.isActive || v.isPending) // Include pending too
          .toList();
    });
  }

  /// Get a single voucher by ID
  Future<Voucher?> getVoucher(String voucherId) async {
    final doc = await _vouchersRef.doc(voucherId).get();
    if (!doc.exists) return null;
    return Voucher.fromFirestore(doc);
  }

  /// Delete a voucher (admin only)
  Future<void> deleteVoucher(String voucherId) async {
    await _vouchersRef.doc(voucherId).delete();
  }

  // ============ CLAIMING VOUCHERS (Users) ============

  /// Claim a voucher
  /// Returns the claimed voucher or throws an error
  Future<ClaimedVoucher> claimVoucher({
    required String voucherId,
    required String userId,
    required String userEmail,
    required String userName,
  }) async {
    // Use transaction to ensure atomic operation
    return await _firestore.runTransaction<ClaimedVoucher>((transaction) async {
      // Get the voucher
      final voucherDoc = await transaction.get(_vouchersRef.doc(voucherId));
      if (!voucherDoc.exists) {
        throw Exception('Voucher not found');
      }

      final voucher = Voucher.fromFirestore(voucherDoc);

      // Validate voucher can be claimed
      if (!voucher.isActive) {
        if (voucher.isPending) {
          throw Exception('This voucher is not active yet');
        } else {
          throw Exception('This voucher has expired');
        }
      }

      if (voucher.isFullyClaimed) {
        throw Exception('This voucher has reached maximum claims');
      }

      // Check if user already claimed this voucher
      final existingClaim = await _claimedVouchersRef
          .where('odGptUserId', isEqualTo: userId)
          .where('voucherId', isEqualTo: voucherId)
          .limit(1)
          .get();

      if (existingClaim.docs.isNotEmpty) {
        throw Exception('You have already claimed this voucher');
      }

      // Calculate claim delay in seconds
      final now = DateTime.now();
      final claimDelaySeconds = now.difference(voucher.startTime).inSeconds;

      // Create claimed voucher record
      final claimedVoucher = ClaimedVoucher(
        id: '',
        odGptUserId: userId,
        odGptUserEmail: userEmail,
        odGptUserName: userName,
        voucherId: voucherId,
        voucherCode: voucher.code,
        voucherDescription: voucher.description,
        discountText: voucher.discountText,
        claimedAt: now,
        claimDelaySeconds: claimDelaySeconds,
        voucherStartTime: voucher.startTime,
        isUsed: false,
      );

      // Increment voucher claim count
      transaction.update(_vouchersRef.doc(voucherId), {
        'currentClaims': FieldValue.increment(1),
      });

      // Add claimed voucher (outside transaction since we need the doc ID)
      // We'll do this after the transaction
      return claimedVoucher;
    }).then((claimedVoucher) async {
      // Add the claimed voucher document
      final docRef =
          await _claimedVouchersRef.add(claimedVoucher.toFirestore());
      return claimedVoucher.copyWith(id: docRef.id);
    });
  }

  /// Check if user has already claimed a voucher
  Future<bool> hasUserClaimedVoucher({
    required String userId,
    required String voucherId,
  }) async {
    final snapshot = await _claimedVouchersRef
        .where('odGptUserId', isEqualTo: userId)
        .where('voucherId', isEqualTo: voucherId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get user's claimed voucher for a specific voucher (if exists)
  Future<ClaimedVoucher?> getUserClaimedVoucher({
    required String userId,
    required String voucherId,
  }) async {
    final snapshot = await _claimedVouchersRef
        .where('odGptUserId', isEqualTo: userId)
        .where('voucherId', isEqualTo: voucherId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return ClaimedVoucher.fromFirestore(snapshot.docs.first);
  }

  // ============ USER'S VOUCHERS (Profile) ============

  /// Get stream of user's claimed vouchers
  Stream<List<ClaimedVoucher>> getUserVouchersStream(String userId) {
    return _claimedVouchersRef
        .where('odGptUserId', isEqualTo: userId)
        .orderBy('claimedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ClaimedVoucher.fromFirestore(doc))
          .toList();
    });
  }

  /// Get user's claimed vouchers (one-time fetch)
  Future<List<ClaimedVoucher>> getUserVouchers(String userId) async {
    final snapshot = await _claimedVouchersRef
        .where('odGptUserId', isEqualTo: userId)
        .orderBy('claimedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ClaimedVoucher.fromFirestore(doc))
        .toList();
  }

  /// Mark a claimed voucher as used
  Future<void> markVoucherAsUsed(String claimedVoucherId) async {
    await _claimedVouchersRef.doc(claimedVoucherId).update({
      'isUsed': true,
      'usedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ============ ANALYTICS (Admin) ============

  /// Get all claims for a specific voucher (for analytics)
  Future<List<ClaimedVoucher>> getVoucherClaims(String voucherId) async {
    final snapshot = await _claimedVouchersRef
        .where('voucherId', isEqualTo: voucherId)
        .orderBy('claimDelaySeconds')
        .get();

    return snapshot.docs
        .map((doc) => ClaimedVoucher.fromFirestore(doc))
        .toList();
  }

  /// Get claim statistics for a voucher
  Future<Map<String, dynamic>> getVoucherClaimStats(String voucherId) async {
    final claims = await getVoucherClaims(voucherId);

    if (claims.isEmpty) {
      return {
        'totalClaims': 0,
        'fastestClaimSeconds': null,
        'averageClaimSeconds': null,
        'claimsWithin5Seconds': 0,
        'claimsWithin30Seconds': 0,
        'claimsWithin1Minute': 0,
        'claimsWithin5Minutes': 0,
      };
    }

    final delays = claims.map((c) => c.claimDelaySeconds).toList();
    final totalClaims = claims.length;
    final fastestClaim = delays.reduce((a, b) => a < b ? a : b);
    final averageClaim = delays.reduce((a, b) => a + b) / totalClaims;

    return {
      'totalClaims': totalClaims,
      'fastestClaimSeconds': fastestClaim,
      'averageClaimSeconds': averageClaim.round(),
      'claimsWithin5Seconds': delays.where((d) => d <= 5).length,
      'claimsWithin30Seconds': delays.where((d) => d <= 30).length,
      'claimsWithin1Minute': delays.where((d) => d <= 60).length,
      'claimsWithin5Minutes': delays.where((d) => d <= 300).length,
    };
  }
}
```

---

## PART 4: CREATE WIDGET FILES

### File 5: `lib/widgets/voucher_card.dart` (CREATE NEW FILE)

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../models/user.dart';
import '../services/voucher_service.dart';

class VoucherCard extends StatefulWidget {
  final Voucher voucher;
  final VoidCallback? onClaimed;

  const VoucherCard({
    super.key,
    required this.voucher,
    this.onClaimed,
  });

  @override
  State<VoucherCard> createState() => _VoucherCardState();
}

class _VoucherCardState extends State<VoucherCard> {
  final VoucherService _voucherService = VoucherService();
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isClaiming = false;
  bool _hasClaimed = false;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _checkIfClaimed();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    setState(() {
      _remainingTime = widget.voucher.remainingTime;
    });
  }

  Future<void> _checkIfClaimed() async {
    final currentUser = User.currentUser;
    if (currentUser.id.isEmpty) return;

    final claimed = await _voucherService.hasUserClaimedVoucher(
      userId: currentUser.id,
      voucherId: widget.voucher.id,
    );

    if (mounted) {
      setState(() {
        _hasClaimed = claimed;
      });
    }
  }

  Future<void> _claimVoucher() async {
    final currentUser = User.currentUser;

    if (currentUser.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to claim vouchers'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isClaiming = true);

    try {
      await _voucherService.claimVoucher(
        voucherId: widget.voucher.id,
        userId: currentUser.id,
        userEmail: currentUser.email,
        userName: currentUser.name,
      );

      if (mounted) {
        setState(() {
          _hasClaimed = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Claimed ${widget.voucher.code}! Check your profile.'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        widget.onClaimed?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  String _formatCountdown(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final voucher = widget.voucher;
    final isExpired = voucher.isExpired;
    final isPending = voucher.isPending;
    final isFullyClaimed = voucher.isFullyClaimed;
    final canClaim = voucher.canBeClaimed && !_hasClaimed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired || isFullyClaimed
              ? [Colors.grey[400]!, Colors.grey[500]!]
              : [const Color(0xFF0056AC), const Color(0xFF003D7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isExpired || isFullyClaimed
                    ? Colors.grey
                    : const Color(0xFF0056AC))
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'FLASH SALE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (!isExpired && !isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _formatCountdown(_remainingTime),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellow.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'COMING SOON',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'EXPIRED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Discount + Code row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      voucher.discountText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        voucher.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Description
                Text(
                  voucher.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Claims info + Claim button row
                Row(
                  children: [
                    if (voucher.maxClaims != null) ...[
                      Icon(
                        Icons.people_outline,
                        color: Colors.white.withOpacity(0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${voucher.currentClaims}/${voucher.maxClaims}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Claim button
                    ElevatedButton(
                      onPressed: canClaim ? _claimVoucher : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasClaimed
                            ? Colors.green
                            : (canClaim ? Colors.white : Colors.white54),
                        foregroundColor:
                            _hasClaimed ? Colors.white : const Color(0xFF0056AC),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isClaiming
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _hasClaimed
                                  ? 'CLAIMED!'
                                  : (isFullyClaimed
                                      ? 'FULL'
                                      : (isExpired
                                          ? 'EXPIRED'
                                          : (isPending
                                              ? 'SOON'
                                              : 'CLAIM'))),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### File 6: `lib/widgets/create_voucher_sheet.dart` (CREATE NEW FILE)

```dart
import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../models/user.dart';
import '../services/voucher_service.dart';

class CreateVoucherSheet extends StatefulWidget {
  const CreateVoucherSheet({super.key});

  @override
  State<CreateVoucherSheet> createState() => _CreateVoucherSheetState();
}

class _CreateVoucherSheetState extends State<CreateVoucherSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _maxClaimsController = TextEditingController();

  final VoucherService _voucherService = VoucherService();

  DiscountType _discountType = DiscountType.percentage;
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  bool _hasMaxClaims = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _maxClaimsController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );
    if (time == null) return;

    setState(() {
      _startTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      // Ensure end time is after start time
      if (_endTime.isBefore(_startTime)) {
        _endTime = _startTime.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _selectEndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime.isAfter(_startTime) ? _endTime : _startTime,
      firstDate: _startTime,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
    );
    if (time == null) return;

    final newEndTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (newEndTime.isBefore(_startTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _endTime = newEndTime;
    });
  }

  void _setQuickDuration(Duration duration) {
    setState(() {
      _startTime = DateTime.now();
      _endTime = DateTime.now().add(duration);
    });
  }

  Future<void> _createVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final currentUser = User.currentUser;

      await _voucherService.createVoucher(
        code: _codeController.text.trim(),
        description: _descriptionController.text.trim(),
        discountType: _discountType,
        discountValue: double.parse(_discountController.text.trim()),
        startTime: _startTime,
        endTime: _endTime,
        maxClaims: _hasMaxClaims && _maxClaimsController.text.isNotEmpty
            ? int.parse(_maxClaimsController.text.trim())
            : null,
        createdBy: currentUser.id,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voucher created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating voucher: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0056AC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_offer,
                          color: Color(0xFF0056AC),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Flash Sale Voucher',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'This will appear in Global Chat',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Voucher Code
                          TextFormField(
                            controller: _codeController,
                            decoration: const InputDecoration(
                              labelText: 'Voucher Code',
                              hintText: 'e.g., FLASH50',
                              prefixIcon: Icon(Icons.confirmation_number),
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a voucher code';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'e.g., 50% off Flutter Course',
                              prefixIcon: Icon(Icons.description),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Discount Type
                          const Text(
                            'Discount Type',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<DiscountType>(
                            segments: const [
                              ButtonSegment(
                                value: DiscountType.percentage,
                                label: Text('Percentage (%)'),
                                icon: Icon(Icons.percent),
                              ),
                              ButtonSegment(
                                value: DiscountType.fixed,
                                label: Text('Fixed (\$)'),
                                icon: Icon(Icons.attach_money),
                              ),
                            ],
                            selected: {_discountType},
                            onSelectionChanged: (selection) {
                              setState(() {
                                _discountType = selection.first;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Discount Value
                          TextFormField(
                            controller: _discountController,
                            decoration: InputDecoration(
                              labelText: 'Discount Value',
                              hintText: _discountType == DiscountType.percentage
                                  ? 'e.g., 50'
                                  : 'e.g., 20.00',
                              prefixIcon: Icon(
                                _discountType == DiscountType.percentage
                                    ? Icons.percent
                                    : Icons.attach_money,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a discount value';
                              }
                              final num = double.tryParse(value.trim());
                              if (num == null || num <= 0) {
                                return 'Please enter a valid positive number';
                              }
                              if (_discountType == DiscountType.percentage &&
                                  num > 100) {
                                return 'Percentage cannot exceed 100%';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Quick Duration Buttons
                          const Text(
                            'Quick Duration',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _QuickDurationChip(
                                label: '5 min',
                                onTap: () =>
                                    _setQuickDuration(const Duration(minutes: 5)),
                              ),
                              _QuickDurationChip(
                                label: '15 min',
                                onTap: () =>
                                    _setQuickDuration(const Duration(minutes: 15)),
                              ),
                              _QuickDurationChip(
                                label: '30 min',
                                onTap: () =>
                                    _setQuickDuration(const Duration(minutes: 30)),
                              ),
                              _QuickDurationChip(
                                label: '1 hour',
                                onTap: () =>
                                    _setQuickDuration(const Duration(hours: 1)),
                              ),
                              _QuickDurationChip(
                                label: '24 hours',
                                onTap: () =>
                                    _setQuickDuration(const Duration(hours: 24)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Start Time
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.play_arrow,
                                color: Colors.green),
                            title: const Text('Start Time'),
                            subtitle: Text(_formatDateTime(_startTime)),
                            trailing: TextButton(
                              onPressed: _selectStartTime,
                              child: const Text('Change'),
                            ),
                          ),

                          // End Time
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading:
                                const Icon(Icons.stop, color: Colors.red),
                            title: const Text('End Time'),
                            subtitle: Text(_formatDateTime(_endTime)),
                            trailing: TextButton(
                              onPressed: _selectEndTime,
                              child: const Text('Change'),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Duration display
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer,
                                    color: Color(0xFF0056AC), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Duration: ${_formatDuration(_endTime.difference(_startTime))}',
                                  style: const TextStyle(
                                    color: Color(0xFF0056AC),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Max Claims
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Limit number of claims'),
                            subtitle: const Text(
                                'Set a maximum number of people who can claim'),
                            value: _hasMaxClaims,
                            onChanged: (value) {
                              setState(() {
                                _hasMaxClaims = value;
                              });
                            },
                          ),
                          if (_hasMaxClaims) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _maxClaimsController,
                              decoration: const InputDecoration(
                                labelText: 'Maximum Claims',
                                hintText: 'e.g., 100',
                                prefixIcon: Icon(Icons.people),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_hasMaxClaims) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter maximum claims';
                                  }
                                  final num = int.tryParse(value.trim());
                                  if (num == null || num <= 0) {
                                    return 'Please enter a valid positive number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 32),

                          // Create Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isCreating ? null : _createVoucher,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0056AC),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isCreating
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Create Voucher',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

class _QuickDurationChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDurationChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.grey[100],
    );
  }
}
```

### File 7: `lib/widgets/my_vouchers_section.dart` (CREATE NEW FILE)

```dart
import 'package:flutter/material.dart';
import '../models/claimed_voucher.dart';
import '../models/user.dart';
import '../services/voucher_service.dart';

class MyVouchersSection extends StatelessWidget {
  const MyVouchersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;

    if (currentUser.id.isEmpty) {
      return const SizedBox.shrink();
    }

    final voucherService = VoucherService();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_offer,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'My Vouchers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<ClaimedVoucher>>(
            stream: voucherService.getUserVouchersStream(currentUser.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error loading vouchers',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              final vouchers = snapshot.data ?? [];

              if (vouchers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No vouchers yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Claim vouchers from flash sales in Global Chat',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: vouchers.map((voucher) {
                  return _VoucherItem(voucher: voucher);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VoucherItem extends StatelessWidget {
  final ClaimedVoucher voucher;

  const _VoucherItem({required this.voucher});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: voucher.isUsed
              ? [Colors.grey[300]!, Colors.grey[400]!]
              : [const Color(0xFF0056AC), const Color(0xFF003D7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Discount badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              voucher.discountText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Voucher details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher.voucherCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  voucher.voucherDescription,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Claimed: ${voucher.claimSpeedText}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: voucher.isUsed
                  ? Colors.grey[600]
                  : Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              voucher.isUsed ? 'USED' : 'ACTIVE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## PART 5: MODIFY SCREEN FILES

### File 8: `lib/screens/global_chat_screen.dart` (MODIFY EXISTING FILE)

Add imports at top of file:

```dart
import '../models/voucher.dart';
import '../services/voucher_service.dart';
import '../widgets/voucher_card.dart';
import '../widgets/create_voucher_sheet.dart';
```

Add VoucherService to state class:

```dart
class _GlobalChatScreenState extends State<GlobalChatScreen> {
  final ChatService _chatService = ChatService();
  final VoucherService _voucherService = VoucherService();  // ADD THIS
  // ... rest of existing code
```

Add method to show create voucher sheet (before build method):

```dart
void _showCreateVoucherSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const CreateVoucherSheet(),
  );
}
```

Modify the build method to wrap everything in a Stack and add vouchers section. The full build method should be:

```dart
@override
Widget build(BuildContext context) {
  final currentUser = User.currentUser;
  final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;
  final canManageVouchers = currentUser.canManageVouchers;

  return Stack(
    children: [
      Column(
        children: [
          // Active Vouchers Section
          StreamBuilder<List<Voucher>>(
            stream: _voucherService.getActiveVouchersStream(),
            builder: (context, voucherSnapshot) {
              final vouchers = voucherSnapshot.data ?? [];
              final activeVouchers = vouchers
                  .where((v) => v.isActive || v.isPending)
                  .toList();

              if (activeVouchers.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flash_on,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'FLASH SALES',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${activeVouchers.length} active',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 200,  // Adjust this height as needed
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      itemCount: activeVouchers.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: MediaQuery.of(context).size.width * 0.85,
                          child: VoucherCard(
                            voucher: activeVouchers[index],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                ],
              );
            },
          ),

          // Chat messages (existing StreamBuilder for messages)
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              // ... your existing chat messages code
            ),
          ),

          // Message input (existing code)
          // ... your existing message input code

          // Guest prompt (existing code)
          // ... your existing guest prompt code
        ],
      ),

      // Admin FAB for creating vouchers
      if (canManageVouchers)
        Positioned(
          right: 16,
          bottom: isGuest ? 80 : 100,
          child: FloatingActionButton.extended(
            onPressed: _showCreateVoucherSheet,
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.local_offer),
            label: const Text('Create Voucher'),
          ),
        ),
    ],
  );
}
```

### File 9: `lib/screens/profile_screen.dart` (MODIFY EXISTING FILE)

Add import at top:

```dart
import '../widgets/my_vouchers_section.dart';
```

In the `_buildProfileTab()` method, add MyVouchersSection after the stats cards and before "My Enrolled Courses" section:

```dart
// Find this section (after the stats row with Courses Enrolled, Completed, etc.)
// Add this before "// Enrolled Courses section":

            // My Vouchers Section - visible to all users
            const MyVouchersSection(),

            const SizedBox(height: 24),

            // Enrolled Courses section  (this already exists)
```

---

## TESTING

1. **Set yourself as admin in Firebase:**
   ```
   users/{yourUserId}/role: "admin"
   ```

2. **Test admin creating voucher:**
   - Open Global Chat
   - Tap orange "Create Voucher" FAB (only visible to admin)
   - Fill form and create

3. **Test user claiming voucher:**
   - Voucher appears at top of Global Chat
   - Tap "CLAIM" button
   - Check Profile → My Vouchers section

4. **Check Firebase data:**
   - `vouchers` collection should have the voucher
   - `user_vouchers` collection should have the claim with timing data

---

## Summary of Files

| Action | File Path |
|--------|-----------|
| MODIFY | `lib/models/user.dart` |
| CREATE | `lib/models/voucher.dart` |
| CREATE | `lib/models/claimed_voucher.dart` |
| CREATE | `lib/services/voucher_service.dart` |
| CREATE | `lib/widgets/voucher_card.dart` |
| CREATE | `lib/widgets/create_voucher_sheet.dart` |
| CREATE | `lib/widgets/my_vouchers_section.dart` |
| MODIFY | `lib/screens/global_chat_screen.dart` |
| MODIFY | `lib/screens/profile_screen.dart` |
