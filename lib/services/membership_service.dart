import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'user_preferences_service.dart';
import 'xendit_service.dart';

class MembershipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserPreferencesService _preferencesService = UserPreferencesService();
  final XenditService _xenditService = XenditService();

  // Create payment invoice for membership
  Future<PaymentResult> createPaymentInvoice({
    required String userId,
    required MembershipTier tier,
    required User currentUser,
  }) async {
    try {
      // For Tier 1 (free), skip payment
      if (tier == MembershipTier.tier1) {
        return PaymentResult.success(
          invoiceId: 'free_tier_${DateTime.now().millisecondsSinceEpoch}',
          invoiceUrl: '',
        );
      }

      // Get payment amount (use test amount for development)
      final amount = _xenditService.getTestPaymentAmount(tier);
      
      // Create invoice with Xendit
      final invoiceData = await _xenditService.createInvoice(
        userId: userId,
        userName: currentUser.name,
        userEmail: currentUser.email,
        tier: tier,
        amount: amount,
      );

      if (invoiceData != null) {
        return PaymentResult.success(
          invoiceId: invoiceData['id'],
          invoiceUrl: invoiceData['invoice_url'],
          paymentData: invoiceData,
        );
      } else {
        return PaymentResult.failure('Failed to create payment invoice');
      }
    } catch (e) {
      print('Error creating payment invoice: $e');
      return PaymentResult.failure('Payment service error: ${e.toString()}');
    }
  }

  // Process membership purchase after payment
  Future<bool> processMembershipPurchase({
    required String userId,
    required MembershipTier tier,
    required User currentUser,
    String? invoiceId,
  }) async {
    try {
      // Calculate expiry date
      DateTime expiryDate;
      if (tier == MembershipTier.tier1) {
        expiryDate = DateTime.now().add(const Duration(days: 365)); // 1 year free
      } else {
        expiryDate = DateTime.now().add(const Duration(days: 365)); // 1 year paid (lifetime in your case)
      }
      
      // Save payment record if invoice exists
      if (invoiceId != null) {
        await _savePaymentRecord(
          userId: userId,
          invoiceId: invoiceId,
          tier: tier,
          amount: _xenditService.getTestPaymentAmount(tier),
        );
      }
      
      // Update user profile with new tier
      await _preferencesService.saveUserProfile(
        userId: userId,
        name: currentUser.name,
        email: currentUser.email,
        phone: currentUser.phone,
        company: currentUser.company,
        tier: tier,
        membershipExpiryDate: _formatDate(expiryDate),
        favoriteCoursesIds: currentUser.favoriteCoursesIds,
        enrolledCourses: currentUser.enrolledCourses,
      );
      
      // Update local user
      User.currentUser = currentUser.copyWith(
        tier: tier,
        membershipExpiryDate: _formatDate(expiryDate),
      );
      
      return true;
    } catch (e) {
      print('Error processing membership purchase: $e');
      return false;
    }
  }

  // Save payment record to Firestore
  Future<void> _savePaymentRecord({
    required String userId,
    required String invoiceId,
    required MembershipTier tier,
    required double amount,
  }) async {
    try {
      await _firestore.collection('payments').add({
        'userId': userId,
        'invoiceId': invoiceId,
        'tier': tier.name,
        'amount': amount,
        'currency': 'IDR',
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving payment record: $e');
    }
  }

  // Verify payment status with Xendit
  Future<bool> verifyPayment(String invoiceId) async {
    try {
      final invoiceData = await _xenditService.getInvoiceStatus(invoiceId);
      return invoiceData != null && invoiceData['status'] == 'PAID';
    } catch (e) {
      print('Error verifying payment: $e');
      return false;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }
  
  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}