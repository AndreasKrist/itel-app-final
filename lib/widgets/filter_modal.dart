import 'package:flutter/material.dart';
import 'category_chip.dart';

class FilterModal extends StatefulWidget {
  final Map<String, String> activeFilters;
  final Function(Map<String, String>) onFiltersChanged;
  final Function() onApply;
  final Function() onCancel;

  const FilterModal({
    super.key,
    required this.activeFilters,
    required this.onFiltersChanged,
    required this.onApply,
    required this.onCancel,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late Map<String, String> _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = Map.from(widget.activeFilters);
  }

  void _updateFilter(String category, String value) {
    setState(() {
      if (_currentFilters[category] == value) {
        // If selecting the same value, reset to 'all'
        _currentFilters[category] = 'all';
      } else {
        // Otherwise, set the new value
        _currentFilters[category] = value;
      }
      widget.onFiltersChanged(_currentFilters);
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
                'Filter Courses',
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
          
          // Funding section
          Text(
            'Funding',
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
                label: 'All',
                isActive: _currentFilters['funding'] == 'all',
                onTap: () => _updateFilter('funding', 'all'),
              ),
              CategoryChip(
                label: 'Funding Available',
                isActive: _currentFilters['funding'] == 'available',
                onTap: () => _updateFilter('funding', 'available'),
              ),
              CategoryChip(
                label: 'No Funding',
                isActive: _currentFilters['funding'] == 'none',
                onTap: () => _updateFilter('funding', 'none'),
              ),
              CategoryChip(
                label: 'Complimentary (Free)',
                isActive: _currentFilters['funding'] == 'free',
                onTap: () => _updateFilter('funding', 'free'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Course Duration section
          Text(
            'Course Duration',
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
                label: 'All',
                isActive: _currentFilters['duration'] == 'all',
                onTap: () => _updateFilter('duration', 'all'),
              ),
              CategoryChip(
                label: 'Short (< 2 days)',
                isActive: _currentFilters['duration'] == 'short',
                onTap: () => _updateFilter('duration', 'short'),
              ),
              CategoryChip(
                label: 'Long (2+ days)',
                isActive: _currentFilters['duration'] == 'long',
                onTap: () => _updateFilter('duration', 'long'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Certification Type section
          Text(
            'Certification Type',
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
                label: 'All',
                isActive: _currentFilters['certType'] == 'all',
                onTap: () => _updateFilter('certType', 'all'),
              ),
              CategoryChip(
                label: 'ITIL',
                isActive: _currentFilters['certType'] == 'ITIL',
                onTap: () => _updateFilter('certType', 'ITIL'),
              ),
              CategoryChip(
                label: 'CCNA',
                isActive: _currentFilters['certType'] == 'CCNA',
                onTap: () => _updateFilter('certType', 'CCNA'),
              ),
              CategoryChip(
                label: 'COMPTIA',
                isActive: _currentFilters['certType'] == 'COMPTIA',
                onTap: () => _updateFilter('certType', 'COMPTIA'),
              ),
              CategoryChip(
                label: 'CEH',
                isActive: _currentFilters['certType'] == 'CEH',
                onTap: () => _updateFilter('certType', 'CEH'),
              ),
              CategoryChip(
                label: 'CCISO',
                isActive: _currentFilters['certType'] == 'CCISO',
                onTap: () => _updateFilter('certType', 'CCISO'),
              ),
              CategoryChip(
                label: 'CISM',
                isActive: _currentFilters['certType'] == 'CISM',
                onTap: () => _updateFilter('certType', 'CISM'),
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
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}