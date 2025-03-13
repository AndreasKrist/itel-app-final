import 'package:flutter/material.dart';
import '../models/trending_item.dart';
import '../screens/trending_detail_screen.dart';

class TrendingCard extends StatelessWidget {
  final TrendingItem item;

  const TrendingCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrendingDetailScreen(item: item),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getLightColorForType(item.type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForType(item.type),
                          size: 12,
                          color: _getColorForType(item.type),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTypeText(item.type),
                          style: TextStyle(
                            color: _getColorForType(item.type),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Title
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Category
                  Text(
                    item.category,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Right side: Date/Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      item.type == TrendingItemType.event || item.date != null
                          ? Icons.calendar_today
                          : Icons.access_time,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.date ?? item.readTime ?? '',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // View details button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrendingDetailScreen(item: item),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      color: _getColorForType(item.type),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
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
  
  Color _getColorForType(TrendingItemType type) {
    switch (type) {
      case TrendingItemType.event:
        return Colors.green[700]!;
      case TrendingItemType.news:
        return Colors.orange[700]!;
      case TrendingItemType.article:
        return Colors.blue[700]!;
    }
  }
  
  Color _getLightColorForType(TrendingItemType type) {
    switch (type) {
      case TrendingItemType.event:
        return Colors.green[50]!;
      case TrendingItemType.news:
        return Colors.orange[50]!;
      case TrendingItemType.article:
        return Colors.blue[50]!;
    }
  }
  
  IconData _getIconForType(TrendingItemType type) {
    switch (type) {
      case TrendingItemType.event:
        return Icons.event;
      case TrendingItemType.news:
        return Icons.newspaper;
      case TrendingItemType.article:
        return Icons.article;
    }
  }
  
  String _getTypeText(TrendingItemType type) {
    switch (type) {
      case TrendingItemType.event:
        return 'Event';
      case TrendingItemType.news:
        return 'News';
      case TrendingItemType.article:
        return 'Article';
    }
  }
}