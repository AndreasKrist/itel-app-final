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
        height: 200, // Fixed height for uniform card sizes
        padding: const EdgeInsets.all(16),
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
            Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(course.rating.toString()),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                    const SizedBox(width: 4),
                    Text(course.duration),
                  ],
                ),
              ],
            ),
            if (course.funding != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  course.funding!,
                  style: TextStyle(
                    color: course.funding!.contains('Eligible') ? Colors.green[600] : Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (course.progress != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  course.progress!,
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (course.completionDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Completed ${course.completionDate}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Consultant is only shown for enrolled courses in the profile screen, not here
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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