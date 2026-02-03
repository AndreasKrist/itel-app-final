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
  bool _showRemainingCount = true;
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
        showRemainingCount: _hasMaxClaims ? _showRemainingCount : true,
        createdBy: currentUser.id,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('e-Voucher created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating e-Voucher: $e'),
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
                              'Create Flash Sale e-Voucher',
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
                              labelText: 'e-Voucher Code',
                              hintText: 'e.g., FLASH50',
                              prefixIcon: Icon(Icons.confirmation_number),
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter an e-Voucher code';
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
                            const SizedBox(height: 12),
                            // Show/Hide remaining count
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Show remaining count'),
                              subtitle: const Text(
                                  'Users can see how many vouchers are left'),
                              value: _showRemainingCount,
                              onChanged: (value) {
                                setState(() {
                                  _showRemainingCount = value;
                                });
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
                                      'Create e-Voucher',
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
