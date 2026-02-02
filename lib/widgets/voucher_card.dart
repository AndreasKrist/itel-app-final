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
          content: Text('Please sign in to claim e-Vouchers'),
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
