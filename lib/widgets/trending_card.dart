import 'package:flutter/material.dart';
import '../models/trending_item.dart';
import '../screens/trending_detail_screen.dart';
import '../screens/course_detail_screen.dart';
import '../models/course.dart';
import '../utils/link_handler.dart';

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
        if (item.type == TrendingItemType.courseAssessor && item.customLink != null) {
          LinkHandler.openLink(
            context, 
            item.customLink!,
            fallbackMessage: 'Opening PTSA assessment...'
          );
        } else if (item.type == TrendingItemType.coursePromotion && item.customLink != null) {
          // Extract course ID from customLink (format: course://ID)
          String courseId = item.customLink!.replaceFirst('course://', '');
          // Find the course by ID
          Course? course = Course.sampleCourses.firstWhere(
            (c) => c.id == courseId,
            orElse: () => Course(id: '', title: '', category: '', rating: 0.0, duration: '', price: ''),
          );
          if (course.id.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailScreen(course: course),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Course not found')),
            );
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrendingDetailScreen(item: item),
            ),
          );
        }
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
                      item.type == TrendingItemType.upcomingEvents || item.date != null
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
                    if (item.type == TrendingItemType.courseAssessor && item.customLink != null) {
                      LinkHandler.openLink(
                        context, 
                        item.customLink!,
                        fallbackMessage: 'Opening PTSA assessment...'
                      );
                    } else if (item.type == TrendingItemType.coursePromotion && item.customLink != null) {
                      // Extract course ID from customLink (format: course://ID)
                      String courseId = item.customLink!.replaceFirst('course://', '');
                      // Find the course by ID
                      Course? course = Course.sampleCourses.firstWhere(
                        (c) => c.id == courseId,
                        orElse: () => Course(id: '', title: '', category: '', rating: 0.0, duration: '', price: ''),
                      );
                      if (course.id.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetailScreen(course: course),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Course not found')),
                        );
                      }
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrendingDetailScreen(item: item),
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      color: Colors.orange[700]!,
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
    return Colors.blue[700]!;
  }
  
  Color _getLightColorForType(TrendingItemType type) {
    return Colors.blue[50]!;
  }
  
  IconData _getIconForType(TrendingItemType type) {
    switch (type) {
      case TrendingItemType.upcomingEvents:
        return Icons.event;
      case TrendingItemType.coursePromotion:
        return Icons.school;
      case TrendingItemType.featuredArticles:
        return Icons.article;
      case TrendingItemType.techTipsOfTheWeek:
        return Icons.lightbulb;
      case TrendingItemType.courseAssessor:
        return Icons.assessment;
    }
  }
  
  String _getTypeText(TrendingItemType type) {
    switch (type) {
      case TrendingItemType.upcomingEvents:
        return 'Event';
      case TrendingItemType.coursePromotion:
        return 'Course';
      case TrendingItemType.featuredArticles:
        return 'Article';
      case TrendingItemType.techTipsOfTheWeek:
        return 'Tech Tip';
      case TrendingItemType.courseAssessor:
        return 'Assessment';
    }
  }
}