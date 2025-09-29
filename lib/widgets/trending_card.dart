import 'package:flutter/material.dart';
import '../models/trending_item.dart';
import '../screens/trending_detail_screen.dart';
import '../screens/course_detail_screen.dart';
import '../models/course.dart';
import '../utils/link_handler.dart';
import '../services/course_remote_config_service.dart';

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
          _handleCoursePromotion(context, item);
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
              flex: 3, // Give more space to content
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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

                      const SizedBox(width: 12),

                      // Date/Time on same row as type indicator
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              item.type == TrendingItemType.upcomingEvents || item.date != null
                                  ? Icons.calendar_today
                                  : Icons.access_time,
                              color: Colors.grey[400],
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.date ?? item.readTime ?? '',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Title with better text handling
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Category and View Details on same row
                  Row(
                    children: [
                      // Category
                      Expanded(
                        child: Text(
                          item.category,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // View details button on the right side of category row
                      TextButton(
                        onPressed: () {
                          if (item.type == TrendingItemType.courseAssessor && item.customLink != null) {
                            LinkHandler.openLink(
                              context,
                              item.customLink!,
                              fallbackMessage: 'Opening PTSA assessment...'
                            );
                          } else if (item.type == TrendingItemType.coursePromotion && item.customLink != null) {
                            _handleCoursePromotion(context, item);
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View Details',
                          style: TextStyle(
                            color: Color(0xFFFF6600)!,
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
          ],
        ),
      ),
    );
  }

  Future<void> _handleCoursePromotion(BuildContext context, TrendingItem item) async {
    // Extract course ID from customLink (format: course://ID)
    String courseId = item.customLink!.replaceFirst('course://', '');

    // First try to find the course locally
    Course? course = Course.sampleCourses.firstWhere(
      (c) => c.id == courseId,
      orElse: () => Course(id: '', title: '', category: '', rating: 0.0, duration: '', price: ''),
    );

    // If found locally, navigate directly
    if (course.id.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailScreen(course: course),
        ),
      );
      return;
    }

    // If not found locally, show loading and fetch from GitHub
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Fetch courses from GitHub
      final courseService = CourseRemoteConfigService();
      final remoteCourses = await courseService.getRemoteCourses();

      // Find the course in remote data
      final remoteCourse = remoteCourses.firstWhere(
        (c) => c.id == courseId,
        orElse: () => Course(id: '', title: '', category: '', rating: 0.0, duration: '', price: ''),
      );

      // Close loading dialog
      Navigator.pop(context);

      if (remoteCourse.id.isNotEmpty) {
        // Navigate to course detail with remote course data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(course: remoteCourse),
          ),
        );
      } else {
        // Course not found even in remote data
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course not found (ID: $courseId)')),
        );
      }
    } catch (e) {
      // Close loading dialog and show error
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading course: ${e.toString()}')),
      );
    }
  }

  Color _getColorForType(TrendingItemType type) {
    return Color(0xFF0056AC)!;
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
        return Icons.build;
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
        return 'Tool';
    }
  }
}