// lib/widgets/enrolled_course_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course.dart';
import '../models/enrolled_course.dart';
import '../screens/course_outline_screen.dart';

class EnrolledCourseCard extends StatelessWidget {
  final EnrolledCourse enrollment;
  final Course course;
  final VoidCallback? onRemove;

  const EnrolledCourseCard({
    super.key,
    required this.enrollment,
    required this.course,
    this.onRemove,
  });

  // Helper function to format date
  String _formatDate(DateTime date) {
    List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Helper function to get status color
  Color _getStatusColor() {
    switch (enrollment.status) {
      case EnrollmentStatus.pending:
        return Color(0xFFFF6600);
      case EnrollmentStatus.confirmed:
        return Color(0xFF0056AC);
      case EnrollmentStatus.active:
        return Color(0xFF0056AC);
      case EnrollmentStatus.completed:
        return Color(0xFF00FF00);
      case EnrollmentStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper function to get status text
  String _getStatusText() {
    switch (enrollment.status) {
      case EnrollmentStatus.pending:
        return 'Enquiry Submitted';
      case EnrollmentStatus.confirmed:
        return 'Enrollment Confirmed';
      case EnrollmentStatus.active:
        return 'In Progress';
      case EnrollmentStatus.completed:
        return 'Completed';
      case EnrollmentStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown Status';
    }
  }

  // Helper function to get completion text based on enrollment type
  String _getCompletionText() {
    // Check if this is an enquiry course by checking if it's NOT a free/complimentary course
    // AND checking if it was originally pending or is a paid course enrollment
    bool isEnquiry = !_isFreeComplimentaryCourse(enrollment.courseId);

    return isEnquiry ? 'Enquiry Completed' : 'Course Completed';
  }

  // Helper function to check if a course is free/complimentary
  bool _isFreeComplimentaryCourse(String courseId) {
    // Check if the course price is free or has complimentary funding
    final coursePrice = course.price.toLowerCase();
    final courseFunding = course.funding?.toLowerCase() ?? '';

    return coursePrice.contains('free') ||
           coursePrice.contains('\$0') ||
           courseFunding.contains('complimentary');
  }

  // Simple method to launch course URL
  // Updated _launchCourseURL method with course deep linking

Future<void> _launchCourseURL(BuildContext context) async {
  try {
    // Base Moodle URL
    final moodleSiteUrl = 'https://lms.itel.com.sg'; // Replace with your actual Moodle URL

    // Get course ID if available
    final courseId = course.moodleCourseId;

    // Try multiple app URL schemes in order of preference
    List<String> moodleAppUrls = [];

    if (courseId != null) {
      // Check if it's a complementary course
      if (course.price == '\$0' || course.price.contains('Free') || course.funding == 'Complimentary') {
        // For complementary courses, direct to enrollment page first
        moodleAppUrls.add('itelmooodleapp://link=$moodleSiteUrl/enrol/index.php?id=$courseId');
        moodleAppUrls.add('moodlemobile://link=$moodleSiteUrl/enrol/index.php?id=$courseId');
      } else {
        // For enrolled paid courses, direct to course page
        moodleAppUrls.add('itelmooodleapp://link=$moodleSiteUrl/course/view.php?id=$courseId');
        moodleAppUrls.add('moodlemobile://link=$moodleSiteUrl/course/view.php?id=$courseId');
      }
    } else {
      // Default to site homepage if no course ID
      moodleAppUrls.add('itelmooodleapp://link=$moodleSiteUrl');
      moodleAppUrls.add('moodlemobile://link=$moodleSiteUrl');
    }

    // Try to launch apps in order of preference
    bool appLaunched = false;
    for (String appUrl in moodleAppUrls) {
      try {
        final canLaunchApp = await canLaunchUrl(Uri.parse(appUrl));
        if (canLaunchApp) {
          // Show message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening ITEL Moodle app...'))
          );

          // Launch the app with deep link to course
          await launchUrl(Uri.parse(appUrl));
          appLaunched = true;
          break;
        }
      } catch (e) {
        print('Failed to launch $appUrl: $e');
        continue;
      }
    }

    if (appLaunched) return;

    // If no app was launched, show dialog to encourage app download
    if (context.mounted) {
      final shouldContinue = await _showMoodleAppDialog(context);
      if (!shouldContinue) return;
    }

    // For browser, create a URL that will redirect to the course after login
    String webUrl;
    if (courseId != null) {
      // For complementary courses, direct to enrollment page first
      if (course.price == '\$0' || course.price.contains('Free') || course.funding == 'Complimentary') {
        // Direct to enrollment page for complementary courses
        webUrl = '$moodleSiteUrl/enrol/index.php?id=$courseId';
      } else {
        // Direct to the course page for enrolled paid courses
        webUrl = '$moodleSiteUrl/course/view.php?id=$courseId';
      }
    } else {
      // Default to login page
      webUrl = '$moodleSiteUrl/login/index.php';
    }

    // Show message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Moodle website...'))
    );

    // Launch in browser
    await launchUrl(
      Uri.parse(webUrl),
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    print('Error opening course: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Moodle. Please try again later.'))
      );
    }
  }
}

// Show dialog encouraging users to download ITEL Moodle app
Future<bool> _showMoodleAppDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Better Learning Experience'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For the best learning experience, we recommend using the ITEL Moodle mobile app.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'App benefits:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Offline course access'),
            Text('• Better mobile interface'),
            Text('• Push notifications'),
            Text('• Faster loading'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue in Browser'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(false);
              // Replace with your actual app store URLs
              const appStoreUrl = 'https://apps.apple.com/app/your-itel-moodle-app'; // iOS
              const playStoreUrl = 'https://play.google.com/store/apps/details?id=your.itel.moodle.app'; // Android

              try {
                // Try to determine platform and open appropriate store
                // For now, let's try Android first then iOS
                bool launched = false;

                try {
                  if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
                    await launchUrl(Uri.parse(playStoreUrl), mode: LaunchMode.externalApplication);
                    launched = true;
                  }
                } catch (e) {
                  print('Failed to open Play Store: $e');
                }

                if (!launched) {
                  try {
                    if (await canLaunchUrl(Uri.parse(appStoreUrl))) {
                      await launchUrl(Uri.parse(appStoreUrl), mode: LaunchMode.externalApplication);
                      launched = true;
                    }
                  } catch (e) {
                    print('Failed to open App Store: $e');
                  }
                }

                if (!launched) {
                  // Fallback: show a message with instructions
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please search for "ITEL Moodle" in your app store'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                print('Error opening app store: $e');
              }
            },
            child: const Text('Download App'),
          ),
        ],
      );
    },
  ) ?? false;
}

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course header with status badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Course Code: ${course.courseCode}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor().withOpacity(0.5)),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress indicator (if active and not completed)
          // Show progress only for paid courses, not for complementary courses, and not for completed courses
          if (enrollment.progress != null &&
              enrollment.status != EnrollmentStatus.completed &&
              !(course.price == '\$0' || course.price.contains('Free') || course.funding == 'Complimentary')) ...[
            Row(
              children: [
                Text(
                  'Progress:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  enrollment.progress!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0056AC),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Progress bar
            LinearProgressIndicator(
              value: double.tryParse(enrollment.progress!.replaceAll(RegExp(r'[^0-9.]'), ''))! / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0056AC)!),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
          ],
          
          // Simplified session info for free courses
          if (course.price == '\$0' || course.price.contains('Free') || course.funding == 'Complimentary') ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Icon(
                      Icons.computer,
                      size: 24,
                      color: Color(0xFF0056AC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course Access',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Online Session',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Access course materials anytime',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (enrollment.nextSessionDate != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Icon(
                      enrollment.isOnline ? Icons.computer : Icons.location_on,
                      size: 24,
                      color: Color(0xFF0056AC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Session',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0056AC),
                          ),
                        ),
                        Text(
                          '${_formatDate(enrollment.nextSessionDate!)} • ${enrollment.nextSessionTime}',
                          style: TextStyle(
                            color: Color(0xFF0056AC),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          enrollment.isOnline ? 'Online Session' : enrollment.location ?? 'Location TBA',
                          style: TextStyle(
                            color: Color(0xFF0056AC),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Action buttons
          Row(
            children: [
              // View outline button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseOutlineScreen(course: course),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book, size: 16, color: Colors.black,),
                  label: const Text('Course Outline',style: TextStyle(
                              color: Colors.black,),
                              ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    side: BorderSide(color: Colors.blue[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Access course button for free courses, no button for paid courses (pending)
              if (course.price == '\$0' || course.price.contains('Free') || course.funding == 'Complimentary')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchCourseURL(context),
                    icon: const Icon(Icons.login, size: 16,color: Colors.white, ),
                    label: const Text('Access Course'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0056AC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )
              else
                // For paid courses (pending enrollments), show status instead
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 16,
                          color: Color(0xFFFF6600),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Enquiry Pending',
                            style: TextStyle(
                              color: Color(0xFFFF6600),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Mark as finished button - only show if not completed
          if (onRemove != null && enrollment.status != EnrollmentStatus.completed)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.check_circle, size: 16, color: Color(0xFF0056AC),),
                label: const Text('Mark as Completed'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide(color: Colors.blue[300]!),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          // Show completed status if course is completed
          if (enrollment.status == EnrollmentStatus.completed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF00FF00),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Color(0xFF0056AC),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCompletionText(),
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}