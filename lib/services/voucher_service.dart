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
    bool showRemainingCount = true,
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
      showRemainingCount: showRemainingCount,
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
        throw Exception('e-Voucher not found');
      }

      final voucher = Voucher.fromFirestore(voucherDoc);

      // Validate voucher can be claimed
      if (!voucher.isActive) {
        if (voucher.isPending) {
          throw Exception('This e-Voucher is not active yet');
        } else {
          throw Exception('This e-Voucher has expired');
        }
      }

      if (voucher.isFullyClaimed) {
        throw Exception('This e-Voucher has reached maximum claims');
      }

      // Check if user already claimed this voucher
      final existingClaim = await _claimedVouchersRef
          .where('odGptUserId', isEqualTo: userId)
          .where('voucherId', isEqualTo: voucherId)
          .limit(1)
          .get();

      if (existingClaim.docs.isNotEmpty) {
        throw Exception('You have already claimed this e-Voucher');
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
