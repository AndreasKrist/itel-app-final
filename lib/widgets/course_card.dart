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
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.22,
          maxHeight: MediaQuery.of(context).size.height * 0.32,
        ),
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
                      if (course.certType != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            course.certType!,
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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
                        color: isDiscountEligible ? Colors.green[600] : Colors.blue[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isDiscountEligible)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
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
                          color: isFavorite ? Colors.orange : Colors.grey,
                          size: 24,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const Spacer(), // This pushes everything below to the bottom
            // Optional status text (funding/progress/completion) - made bigger
            if (course.funding != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  course.funding!,
                  style: TextStyle(
                    color: course.funding!.contains('Eligible') ? Colors.green[600] : Colors.grey[600],
                    fontSize: 14, // Increased from 12 to 14
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (course.progress != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  course.progress!,
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 14, // Increased from 12 to 14
                    fontWeight: FontWeight.w600, // Made bolder
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (course.completionDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Completed ${course.completionDate}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 14, // Increased from 12 to 14
                    fontWeight: FontWeight.w600, // Made bolder
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Bottom row with rating/duration on left and View Details on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: Rating and Duration - made bigger
                Row(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: 18), // Increased from 16 to 18
                        const SizedBox(width: 4),
                        Text(
                          course.rating.toString(),
                          style: const TextStyle(
                            fontSize: 14, // Increased from 12 to 14
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.grey[400], size: 18), // Increased from 16 to 18
                        const SizedBox(width: 4),
                        Text(
                          course.duration,
                          style: const TextStyle(
                            fontSize: 14, // Increased from 12 to 14
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Right side: View Details button
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
                    'View Details',
                    style: TextStyle(
                      color: Colors.orange,
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