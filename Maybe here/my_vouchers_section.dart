import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
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
                  'My E-Vouchers',
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
                      'Error loading E-Vouchers',
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
                          'No E-Vouchers yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Claim E-Vouchers from flash sales in Global Chat',
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

class _VoucherItem extends StatefulWidget {
  final ClaimedVoucher voucher;

  const _VoucherItem({required this.voucher});

  @override
  State<_VoucherItem> createState() => _VoucherItemState();
}

class _VoucherItemState extends State<_VoucherItem> {
  bool _isMarking = false;

  Future<void> _showVoucherDetails() async {
    if (_isMarking) return;

    if (widget.voucher.isUsed) {
      // Already redeemed — show details only with an OK button
      await showDialog(
        context: context,
        builder: (context) => _VoucherDetailsDialog(
          voucher: widget.voucher,
          isRedeemed: true,
        ),
      );
      return;
    }

    final shouldRedeem = await showDialog<bool>(
      context: context,
      builder: (context) => _VoucherDetailsDialog(voucher: widget.voucher),
    );

    if (shouldRedeem == true) {
      await _markAsRedeemed();
    }
  }

  Future<void> _markAsRedeemed() async {
    if (widget.voucher.isUsed || _isMarking) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RedemptionFormDialog(
        voucherCode: widget.voucher.voucherCode,
        currentUser: User.currentUser,
      ),
    );

    if (result != null) {
      setState(() => _isMarking = true);
      try {
        // Save redemption info to Firestore
        await FirebaseFirestore.instance.collection('voucher_redemptions').add({
          'voucherCode': widget.voucher.voucherCode,
          'voucherDescription': widget.voucher.voucherDescription,
          'discountText': widget.voucher.discountText,
          'fullName': result['fullName'],
          'email': result['email'],
          'phoneNumber': result['phoneNumber'],
          'redeemedAt': FieldValue.serverTimestamp(),
        });

        // Send email via EmailJS
        final emailResponse = await http.post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: {
            'Content-Type': 'application/json',
            'origin': 'http://localhost',
          },
          body: jsonEncode({
            'service_id': 'service_5p96zlq',
            'template_id': 'template_al4oeh3',
            'user_id': 'm0Qqr1yrQUEXZJf6h',
            'template_params': {
              'voucher_code': widget.voucher.voucherCode,
              'discount': widget.voucher.discountText,
              'description': widget.voucher.voucherDescription,
              'original_price': widget.voucher.originalPrice != null
                  ? '\$${widget.voucher.originalPrice!.toStringAsFixed(0)}'
                  : 'N/A',
              'discounted_price': widget.voucher.discountedPrice != null
                  ? '\$${widget.voucher.discountedPrice!.toStringAsFixed(0)}'
                  : 'N/A',
              'full_name': result['fullName'],
              'email': result['email'],
              'phone_number': result['phoneNumber'],
              'redeemed_at': DateTime.now().toString(),
            },
          }),
        );
        debugPrint('EmailJS response: ${emailResponse.statusCode} - ${emailResponse.body}');

        // Send confirmation email to user
        final userEmailResponse = await http.post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: {
            'Content-Type': 'application/json',
            'origin': 'http://localhost',
          },
          body: jsonEncode({
            'service_id': 'service_5p96zlq',
            'template_id': 'template_cbpk4wa',
            'user_id': 'm0Qqr1yrQUEXZJf6h',
            'template_params': {
              'full_name': result['fullName'],
              'email': result['email'],
            },
          }),
        );
        debugPrint('User email response: ${userEmailResponse.statusCode} - ${userEmailResponse.body}');

        // Mark voucher as used
        await VoucherService().markVoucherAsUsed(widget.voucher.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'E-Voucher redeemed successfully!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Please check your email for details.'),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 6),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isMarking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUsed = widget.voucher.isUsed;
    final bgLeft = isUsed ? const Color(0xFFB0B0B0) : const Color(0xFF0056AC);
    final bgRight = isUsed ? const Color(0xFFD5D5D5) : const Color(0xFFE8F0FB);

    return GestureDetector(
      onTap: _showVoucherDetails,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isUsed
                  ? Colors.grey.withOpacity(0.14)
                  : const Color(0xFF0056AC).withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left section – discount
                Container(
                  width: 50,
                  color: bgLeft,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.voucher.discountText
                            .replaceAll(' OFF', ''),
                        style: TextStyle(
                          color: isUsed ? Colors.white70 : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'OFF',
                        style: TextStyle(
                          color: isUsed
                              ? Colors.white54
                              : Colors.white.withOpacity(0.75),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Notch divider
                _TicketDivider(color: bgLeft),
                // Right section – details + action
                Expanded(
                  child: Container(
                    color: bgRight,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Title / description — first line green (1 line), rest orange
                              Builder(
                                builder: (context) {
                                  final parts = widget.voucher.voucherDescription.split('\n');
                                  if (parts.length == 1 || isUsed) {
                                    return Text(
                                      widget.voucher.voucherDescription,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        height: 1.3,
                                        color: isUsed ? Colors.grey[600] : Colors.green[700],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      softWrap: false,
                                    );
                                  }
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        parts[0],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          height: 1.3,
                                          color: Colors.green[700],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.clip,
                                        softWrap: false,
                                      ),
                                      Text(
                                        parts.skip(1).join('\n'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          height: 1.3,
                                          color: Colors.orange[700],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.clip,
                                      ),
                                    ],
                                  );
                                },
                              ),
                              // Pricing row
                              if (widget.voucher.originalPrice != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '\$${widget.voucher.originalPrice!.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '\$${widget.voucher.discountedPrice!.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: isUsed
                                            ? Colors.grey[500]
                                            : const Color(0xFF0D8A3C),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              // Voucher code — always visible
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isUsed
                                      ? Colors.grey[300]
                                      : const Color(0xFF0056AC).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isUsed
                                        ? Colors.grey[400]!
                                        : const Color(0xFF0056AC).withOpacity(0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  widget.voucher.voucherCode,
                                  style: TextStyle(
                                    color: isUsed
                                        ? Colors.grey[600]
                                        : const Color(0xFF0056AC),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Action chip
                        _isMarking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0056AC),
                                ),
                              )
                            : _StatusChip(isUsed: isUsed),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketDivider extends StatelessWidget {
  final Color color;
  const _TicketDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      child: CustomPaint(
        painter: _TicketDividerPainter(color: color),
      ),
    );
  }
}

class _TicketDividerPainter extends CustomPainter {
  final Color color;
  const _TicketDividerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    // Fill left half solid to match left panel
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width / 2, size.height), paint);

    // Notch circles cut out from each end (top & bottom)
    final notchRadius = 10.0;
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, -1), notchRadius, bgPaint);
    canvas.drawCircle(
        Offset(size.width / 2, size.height + 1), notchRadius, bgPaint);

    // Dashed line in the center
    final dashPaint = Paint()
      ..color = color.withOpacity(0.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashHeight = 5.0;
    const dashGap = 4.0;
    double startY = 14;
    while (startY < size.height - 14) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        dashPaint,
      );
      startY += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(_TicketDividerPainter old) => old.color != color;
}

class _StatusChip extends StatelessWidget {
  final bool isUsed;
  const _StatusChip({required this.isUsed});

  @override
  Widget build(BuildContext context) {
    if (isUsed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'REDEEMED',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0056AC), Color(0xFF003D7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0056AC).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.redeem, color: Colors.white, size: 10),
          SizedBox(width: 2),
          Text(
            'REDEEM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherDetailsDialog extends StatelessWidget {
  final ClaimedVoucher voucher;
  final bool isRedeemed;
  const _VoucherDetailsDialog({required this.voucher, this.isRedeemed = false});

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final tz = dt.timeZoneName;
    return '$day $month ${dt.year}  •  $hour:$minute $tz';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0056AC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_offer, color: Color(0xFF0056AC), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'E-Voucher Details',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Detail rows
            _DetailRow(label: 'Title', value: voucher.voucherDescription),
            const SizedBox(height: 14),
            _DetailRow(label: 'Discount', value: voucher.discountText),
            if (voucher.originalPrice != null) ...[
              const SizedBox(height: 14),
              _DetailRow(
                label: 'Original Price',
                value: '\$${voucher.originalPrice!.toStringAsFixed(0)}',
                valueStyle: const TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 14),
              _DetailRow(
                label: 'Discounted Price',
                value: '\$${voucher.discountedPrice!.toStringAsFixed(0)}',
                valueStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D8A3C),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _DetailRow(
              label: 'Claimed On',
              value: _formatDateTime(voucher.claimedAt),
              valueStyle: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Actions
            if (isRedeemed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056AC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('OK'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.redeem, size: 16),
                      label: const Text('Redeem'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056AC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: valueStyle ?? const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _RedemptionFormDialog extends StatefulWidget {
  final String voucherCode;
  final User currentUser;

  const _RedemptionFormDialog({
    required this.voucherCode,
    required this.currentUser,
  });

  @override
  State<_RedemptionFormDialog> createState() => _RedemptionFormDialogState();
}

class _RedemptionFormDialogState extends State<_RedemptionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name.isNotEmpty && widget.currentUser.name != 'User Name' ? widget.currentUser.name : '');
    _emailController = TextEditingController(text: widget.currentUser.email.isNotEmpty && widget.currentUser.email != 'user@example.com' ? widget.currentUser.email : '');
    _phoneController = TextEditingController(text: widget.currentUser.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Row(
        children: [
          const Icon(Icons.redeem, color: Color(0xFF0056AC)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Redeem ${widget.voucherCode}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please fill in your details to redeem this E-Voucher.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                  prefixIconConstraints: BoxConstraints(minWidth: 40),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                  prefixIconConstraints: BoxConstraints(minWidth: 40),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  isDense: true,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  prefixIconConstraints: BoxConstraints(minWidth: 40),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  isDense: true,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'fullName': _nameController.text.trim(),
                'email': _emailController.text.trim(),
                'phoneNumber': _phoneController.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0056AC),
            foregroundColor: Colors.white,
          ),
          child: const Text('Submit & Redeem'),
        ),
      ],
    );
  }
}
