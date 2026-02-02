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
                  'My e-Vouchers',
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
                      'Error loading e-Vouchers',
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
                          'No e-Vouchers yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Claim e-Vouchers from flash sales in Global Chat',
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

  Future<void> _markAsRedeemed() async {
    if (widget.voucher.isUsed || _isMarking) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Redeemed'),
        content: Text(
          'Mark e-Voucher "${widget.voucher.voucherCode}" as redeemed?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Mark Redeemed'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isMarking = true);
      try {
        await VoucherService().markVoucherAsUsed(widget.voucher.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('e-Voucher marked as redeemed'),
              backgroundColor: Colors.green,
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
    return GestureDetector(
      onTap: widget.voucher.isUsed ? null : _markAsRedeemed,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.voucher.isUsed
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
                widget.voucher.discountText,
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
                    widget.voucher.voucherCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.voucher.voucherDescription,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Claimed: ${widget.voucher.claimSpeedText}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            // Status badge - tappable when active
            _isMarking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.voucher.isUsed
                          ? Colors.grey[600]
                          : Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.voucher.isUsed ? 'REDEEMED' : 'ACTIVE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!widget.voucher.isUsed) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.touch_app,
                            color: Colors.white,
                            size: 12,
                          ),
                        ],
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
