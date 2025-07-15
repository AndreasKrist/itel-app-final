import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../config/xendit_config.dart';
import '../models/user.dart';

class XenditService {
  final Dio _dio = Dio();
  
  XenditService() {
    _dio.options.baseUrl = XenditConfig.baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic ${base64Encode(utf8.encode('${XenditConfig.secretKey}:'))}',
    };
  }

  // Create invoice for membership payment
  Future<Map<String, dynamic>?> createInvoice({
    required String userId,
    required String userName,
    required String userEmail,
    required MembershipTier tier,
    required double amount,
  }) async {
    try {
      final invoiceData = {
        'external_id': 'membership_${tier.name}_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'description': 'ITEL ${tier.displayName} Membership',
        'invoice_duration': 86400, // 24 hours expiry
        'customer': {
          'given_names': userName,
          'email': userEmail,
        },
        'customer_notification_preference': {
          'invoice_created': ['email'],
          'invoice_reminder': ['email'], 
          'invoice_paid': ['email'],
          'invoice_expired': ['email'],
        },
        // Remove redirect URLs to prevent HugeDomains redirection
        // Payment completion will be handled by polling invoice status
        'currency': 'IDR',
        'payment_methods': XenditConfig.paymentMethods,
      };

      final response = await _dio.post('/v2/invoices', data: invoiceData);
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('Xendit API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error creating Xendit invoice: $e');
      return null;
    }
  }

  // Check invoice status
  Future<Map<String, dynamic>?> getInvoiceStatus(String invoiceId) async {
    try {
      final response = await _dio.get('/v2/invoices/$invoiceId');
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('Error checking invoice status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching invoice status: $e');
      return null;
    }
  }

  // Get payment amount for tier
  double getPaymentAmount(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.standard:
        return 0.0;
      case MembershipTier.tier1:
        return 0.0; // Free for 1 year
      case MembershipTier.tier2:
        return 299.99 * 15000; // Convert USD to IDR (approximate)
      case MembershipTier.tier3:
        return 599.99 * 15000; // Convert USD to IDR (approximate)
    }
  }

  // Test payment with minimal amount for development
  double getTestPaymentAmount(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.standard:
        return 0.0;
      case MembershipTier.tier1:
        return 0.0; // Free for 1 year
      case MembershipTier.tier2:
        return 10000.0; // IDR 10,000 for testing
      case MembershipTier.tier3:
        return 20000.0; // IDR 20,000 for testing
    }
  }

  // Verify webhook signature (for production use)
  bool verifyWebhookSignature(String rawBody, String signature, String webhookToken) {
    final expectedSignature = base64Encode(
      Hmac(sha256, utf8.encode(webhookToken)).convert(utf8.encode(rawBody)).bytes,
    );
    return signature == expectedSignature;
  }
}

// Payment result model
class PaymentResult {
  final bool success;
  final String? invoiceId;
  final String? invoiceUrl;
  final String? errorMessage;
  final Map<String, dynamic>? paymentData;

  PaymentResult({
    required this.success,
    this.invoiceId,
    this.invoiceUrl,
    this.errorMessage,
    this.paymentData,
  });

  factory PaymentResult.success({
    required String invoiceId,
    required String invoiceUrl,
    Map<String, dynamic>? paymentData,
  }) {
    return PaymentResult(
      success: true,
      invoiceId: invoiceId,
      invoiceUrl: invoiceUrl,
      paymentData: paymentData,
    );
  }

  factory PaymentResult.failure(String errorMessage) {
    return PaymentResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}