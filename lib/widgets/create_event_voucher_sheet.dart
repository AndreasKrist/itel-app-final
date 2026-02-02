import 'package:flutter/material.dart';
import '../models/event_voucher.dart';
import '../models/user.dart';
import '../services/event_service.dart';

/// Sheet for staff to create vouchers inside an event
class CreateEventVoucherSheet extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const CreateEventVoucherSheet({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<CreateEventVoucherSheet> createState() => _CreateEventVoucherSheetState();
}

class _CreateEventVoucherSheetState extends State<CreateEventVoucherSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _maxClaimsController = TextEditingController();

  final EventService _eventService = EventService();

  DiscountType _discountType = DiscountType.percentage;
  bool _hasMaxClaims = false;
  bool _hasExpiry = false;
  DateTime? _expiresAt;
  bool _isCreating = false;

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _maxClaimsController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiresAt ?? now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    setState(() {
      _expiresAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _createVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final currentUser = User.currentUser;

      await _eventService.createEventVoucher(
        eventId: widget.eventId,
        code: _codeController.text.trim().toUpperCase(),
        description: _descriptionController.text.trim(),
        discountType: _discountType,
        discountValue: double.parse(_discountController.text.trim()),
        maxClaims: _hasMaxClaims && _maxClaimsController.text.isNotEmpty
            ? int.parse(_maxClaimsController.text.trim())
            : null,
        expiresAt: _hasExpiry ? _expiresAt : null,
        createdBy: currentUser.id,
        createdByName: currentUser.name,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
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
                          gradient: LinearGradient(
                            colors: [Colors.green[400]!, Colors.green[700]!],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_offer,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add e-Voucher',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'For: ${widget.eventTitle}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                              if (value.trim().length < 3) {
                                return 'Code must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Voucher Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'e-Voucher Description',
                              hintText: 'e.g., 50% off Flutter Course',
                              prefixIcon: Icon(Icons.text_snippet),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter an e-Voucher description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

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
                          const SizedBox(height: 20),

                          // Max Claims Section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Limit number of claims'),
                                  subtitle: const Text(
                                    'Set a maximum number of people who can claim',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  value: _hasMaxClaims,
                                  onChanged: (value) {
                                    setState(() {
                                      _hasMaxClaims = value;
                                    });
                                  },
                                ),
                                if (_hasMaxClaims) ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _maxClaimsController,
                                    decoration: const InputDecoration(
                                      labelText: 'Maximum Claims',
                                      hintText: 'e.g., 100',
                                      prefixIcon: Icon(Icons.people),
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Voucher Expiry Section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Set e-Voucher expiry'),
                                  subtitle: const Text(
                                    'e-Voucher expires at specific time (otherwise follows event)',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  value: _hasExpiry,
                                  onChanged: (value) {
                                    setState(() {
                                      _hasExpiry = value;
                                      if (value && _expiresAt == null) {
                                        _expiresAt = DateTime.now().add(const Duration(hours: 1));
                                      }
                                    });
                                  },
                                ),
                                if (_hasExpiry) ...[
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: _pickExpiryDateTime,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time, color: Colors.orange[700]),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Expires At',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  _expiresAt != null
                                                      ? '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year} ${_expiresAt!.hour.toString().padLeft(2, '0')}:${_expiresAt!.minute.toString().padLeft(2, '0')}'
                                                      : 'Tap to set',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.edit, size: 18, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Create Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isCreating ? null : _createVoucher,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add),
                                        SizedBox(width: 8),
                                        Text(
                                          'Create e-Voucher',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
}
