import 'package:flutter/material.dart';
import 'category_chip.dart';

class SortModal extends StatefulWidget {
  final String activeSort;
  final Function(String) onSortChanged;
  final Function() onApply;
  final Function() onCancel;

  const SortModal({
    super.key,
    required this.activeSort,
    required this.onSortChanged,
    required this.onApply,
    required this.onCancel,
  });

  @override
  State<SortModal> createState() => _SortModalState();
}

class _SortModalState extends State<SortModal> {
  late String _currentSort;

  @override
  void initState() {
    super.initState();
    _currentSort = widget.activeSort;
  }

  void _updateSort(String sort) {
    setState(() {
      if (_currentSort == sort) {
        // If selecting the same value, reset to 'none'
        _currentSort = 'none';
      } else {
        // Otherwise, set the new value
        _currentSort = sort;
      }
      widget.onSortChanged(_currentSort);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sort Courses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: widget.onCancel,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Sort By section
          Text(
            'Sort By',
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
              CategoryChip(
                label: 'Price: Low to High',
                isActive: _currentSort == 'priceLow',
                onTap: () => _updateSort('priceLow'),
              ),
              CategoryChip(
                label: 'Price: High to Low',
                isActive: _currentSort == 'priceHigh',
                onTap: () => _updateSort('priceHigh'),
              ),
              CategoryChip(
                label: 'Duration: Low to High',
                isActive: _currentSort == 'durationLow',
                onTap: () => _updateSort('durationLow'),
              ),
              CategoryChip(
                label: 'Duration: High to Low',
                isActive: _currentSort == 'durationHigh',
                onTap: () => _updateSort('durationHigh'),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Apply Sort'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}