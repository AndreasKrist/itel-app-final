import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import '../models/user.dart';
import '../services/xendit_service.dart';

class PaymentScreen extends StatefulWidget {
  final MembershipTier tier;
  final String invoiceUrl;
  final String invoiceId;
  final Function(bool success, String? invoiceId) onPaymentComplete;

  const PaymentScreen({
    super.key,
    required this.tier,
    required this.invoiceUrl,
    required this.invoiceId,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _paymentCompleted = false;
  final XenditService _xenditService = XenditService();
  Timer? _statusCheckTimer;
  String _paymentStatus = 'PENDING';
  bool _showManualComplete = false;

  @override
  void initState() {
    super.initState();
    _resetState();
    _initializeWebView();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _resetState() {
    // Reset all state variables for fresh start
    _isLoading = true;
    _isProcessing = false;
    _paymentCompleted = false;
    _paymentStatus = 'PENDING';
    _showManualComplete = false;
    _statusCheckTimer?.cancel();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _handleUrlChange(url);
            // Inject CSS to improve mobile layout
            _controller.runJavaScript('''
              var meta = document.createElement('meta');
              meta.name = 'viewport';
              meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
              document.getElementsByTagName('head')[0].appendChild(meta);
              
              // Add custom CSS for better mobile layout
              var style = document.createElement('style');
              style.innerHTML = `
                body { 
                  font-size: 14px !important; 
                  margin: 0 !important; 
                  padding: 0 !important; 
                  overflow-x: hidden !important;
                }
                .container { 
                  max-width: 100% !important; 
                  padding: 10px !important; 
                  margin: 0 auto !important;
                  box-sizing: border-box !important;
                }
                input, select, button { 
                  font-size: 16px !important; 
                  max-width: 100% !important;
                }
                .form-group { 
                  margin-bottom: 15px !important; 
                }
                .btn { 
                  padding: 12px 20px !important; 
                  font-size: 16px !important; 
                  max-width: 100% !important;
                }
                
                /* Fix for thank you page */
                .thank-you-page, .success-page, .completion-page {
                  max-width: 100% !important;
                  padding: 20px !important;
                  margin: 0 auto !important;
                  box-sizing: border-box !important;
                }
                
                .thank-you-content, .success-content {
                  max-width: 100% !important;
                  padding: 15px !important;
                  margin: 0 !important;
                  box-sizing: border-box !important;
                }
                
                /* Fix overlapping issues */
                * {
                  max-width: 100% !important;
                  box-sizing: border-box !important;
                }
                
                .row, .col-12, .col-md-12 {
                  max-width: 100% !important;
                  margin: 0 !important;
                  padding: 10px !important;
                }
                
                .card, .card-body {
                  max-width: 100% !important;
                  margin: 0 !important;
                  padding: 15px !important;
                }
              `;
              document.head.appendChild(style);
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.invoiceUrl));
  }

  void _startStatusPolling() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_paymentCompleted && mounted) {
        _checkInvoiceStatus();
        _checkPageContent();
      }
    });
  }
  
  // Check if we're on a thank you or completion page
  Future<void> _checkPageContent() async {
    if (_paymentCompleted) return;
    
    try {
      final pageContent = await _controller.runJavaScriptReturningResult(
        'document.body.innerText.toLowerCase()'
      );
      
      String content = pageContent.toString().toLowerCase();
      
      if (content.contains('thank you') || 
          content.contains('payment successful') ||
          content.contains('transaction complete') ||
          content.contains('completed successfully')) {
        print('Detected success page content');
        
        // First try automatic completion
        _handlePaymentSuccess();
        
        // Also show manual complete button as backup
        if (!_showManualComplete) {
          setState(() {
            _showManualComplete = true;
          });
        }
      }
    } catch (e) {
      print('Error checking page content: $e');
    }
  }

  void _handleUrlChange(String url) {
    print('URL changed to: $url');
    // Check for Xendit success/failure pages and thank you pages
    if (url.contains('status=paid') || 
        url.contains('paid') || 
        url.contains('success') || 
        url.contains('thank') || 
        url.contains('complete') ||
        url.contains('invoice/success')) {
      _handlePaymentSuccess();
    } else if (url.contains('status=failed') || 
               url.contains('failed') || 
               url.contains('expired') || 
               url.contains('cancel')) {
      _handlePaymentFailure();
    }
  }

  Future<void> _checkInvoiceStatus() async {
    if (_isProcessing || _paymentCompleted) return;
    
    try {
      final invoiceData = await _xenditService.getInvoiceStatus(widget.invoiceId);
      if (invoiceData != null && mounted) {
        final status = invoiceData['status'];
        setState(() {
          _paymentStatus = status;
        });
        
        if (status == 'PAID') {
          _handlePaymentSuccess();
        } else if (status == 'EXPIRED') {
          _handlePaymentFailure();
        }
      }
    } catch (e) {
      print('Error checking invoice status: $e');
    }
  }

  void _handlePaymentSuccess() {
    if (_paymentCompleted) return;
    
    setState(() {
      _paymentCompleted = true;
      _isProcessing = true;
    });
    
    _statusCheckTimer?.cancel();
    
    // Show success message briefly before closing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Processing membership...'),
        backgroundColor: Color(0xFF00FF00),
        duration: Duration(seconds: 2),
      ),
    );
    
    // Delay to show success message then close regardless of page state
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onPaymentComplete(true, widget.invoiceId);
        Navigator.pop(context);
      }
    });
    
    // Fallback: Force close after 5 seconds if still open
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _paymentCompleted) {
        widget.onPaymentComplete(true, widget.invoiceId);
        Navigator.pop(context);
      }
    });
  }

  void _handlePaymentFailure() {
    if (_paymentCompleted) return;
    
    setState(() {
      _paymentCompleted = true;
    });
    
    _statusCheckTimer?.cancel();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment failed or expired'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onPaymentComplete(false, null);
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment - ${widget.tier.displayName}'),
        backgroundColor: Color(0xFF0056AC),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showExitConfirmation();
          },
        ),
        actions: [
          if (!_paymentCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_paymentStatus),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(_paymentStatus),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // WebView with better mobile handling
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: WebViewWidget(controller: _controller),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading payment page...'),
                  ],
                ),
              ),
            ),
          
          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing payment...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border(top: BorderSide(color: Colors.blue[200]!)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF0056AC), size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Test Mode: Use test payment methods',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Test Cards: 4000000000000002 (Success) • 4000000000000069 (Failed)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, color: Color(0xFF0056AC), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Status: ${_getStatusText(_paymentStatus)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0056AC),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _showManualComplete && !_paymentCompleted
          ? FloatingActionButton.extended(
              onPressed: () {
                print('Manual payment completion triggered');
                _handlePaymentSuccess();
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete Payment'),
              backgroundColor: Color(0xFF00FF00),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PAID':
        return Color(0xFF00FF00);
      case 'EXPIRED':
        return Colors.red;
      case 'PENDING':
        return Color(0xFFFF6600);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PAID':
        return 'Paid';
      case 'EXPIRED':
        return 'Expired';
      case 'PENDING':
        return 'Pending';
      default:
        return 'Unknown';
    }
  }

  void _showExitConfirmation() {
    if (_paymentCompleted) {
      Navigator.pop(context);
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_paymentStatus == 'PAID' ? 'Payment Completed' : 'Cancel Payment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_paymentStatus == 'PAID')
              const Text('Payment has been completed successfully!')
            else ...[
              const Text('Are you sure you want to cancel the payment?'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFFF6600), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Payment can be completed later using the same invoice.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_paymentStatus != 'PAID')
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue Payment'),
            ),
          ElevatedButton(
            onPressed: () {
              _statusCheckTimer?.cancel();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close payment screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _paymentStatus == 'PAID' ? Color(0xFF00FF00) : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(_paymentStatus == 'PAID' ? 'Continue' : 'Cancel Payment'),
          ),
        ],
      ),
    );
  }
}