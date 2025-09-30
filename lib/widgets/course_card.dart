import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../screens/course_detail_screen.dart';





class CourseCard extends StatelessWidget {
  final Course course;
  final Function(Course)? onFavoriteToggle;

  const CourseCard({
    super.key,
    required this.course,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isFavorite = User.currentUser.favoriteCoursesIds.contains(course.id);
    final userTier = User.currentUser.tier;
    final isDiscountEligible = course.isDiscountEligible() && userTier != MembershipTier.standard;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(course: course),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with limited width to make room for favorite icon
                      Text(
                        course.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textScaleFactor: MediaQuery.textScaleFactorOf(context).clamp(0.8, 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.category,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Show original price with strikethrough for PRO members
                    if (isDiscountEligible)
                      Text(
                        course.price,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      isDiscountEligible
                          ? course.getDiscountedPrice(userTier)
                          : course.price,
                      style: TextStyle(
                        color: isDiscountEligible ? Color(0xFF00FF00) : Color(0xFF0056AC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isDiscountEligible)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFF0056AC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${(userTier.discountPercentage * 100).toInt()}% OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // Favorite button under the price
                    if (onFavoriteToggle != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          if (onFavoriteToggle != null) {
                            onFavoriteToggle!(course);
                          }
                        },
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Color(0xFFFF6600) : Colors.grey,
                          size: 24,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Single row with funding, progress/completion, duration, and Course Overview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: Funding, Progress/Completion, and Duration
                Expanded(
                  child: Row(
                    children: [
                      // Funding status
                      if (course.funding != null) ...[
                        course.funding!.contains('Eligible')
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xD9013220),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Funded',
                                style: TextStyle(
                                  color: Color(0xFF00FF00),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          : Text(
                              course.funding!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        const SizedBox(width: 12),
                      ],
                      // Progress status
                      if (course.progress != null) ...[
                        Text(
                          course.progress!,
                          style: TextStyle(
                            color: Color(0xFFFF6600),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 12),
                      ],
                      // Completion date
                      if (course.completionDate != null) ...[
                        Text(
                          'Completed ${course.completionDate}',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 12),
                      ],
                      // Duration
                      Icon(Icons.access_time, color: Colors.grey[400], size: 18),
                      const SizedBox(width: 4),
                      Text(
                        course.duration,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right side: Course Overview button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(course: course),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Course Overview',
                    style: TextStyle(
                      color: Color(0xFFFF6600),
                      fontWeight: FontWeight.w500,
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