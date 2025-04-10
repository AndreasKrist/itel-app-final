// File: lib/widgets/enrolled_course_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course.dart';
import '../models/enrolled_course.dart';
import '../screens/course_outline_screen.dart';
import '../services/moodle_service.dart';

class EnrolledCourseCard extends StatelessWidget {
  final EnrolledCourse enrollment;
  final Course course;
  // Add Moodle service
  final MoodleService _moodleService = MoodleService();

  EnrolledCourseCard({
    super.key,
    required this.enrollment,
    required this.course,
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
        return Colors.orange;
      case EnrollmentStatus.confirmed:
        return Colors.blue;
      case EnrollmentStatus.active:
        return Colors.green;
      case EnrollmentStatus.completed:
        return Colors.purple;
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

  // Launch the course URL with improved error handling
  Future<void> _launchCourseURL(BuildContext context) async {
    if (enrollment.isOnline) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connecting to Moodle...'))
        );
        
        // Get Moodle site URL - you could make this a configurable setting
        final moodleSiteUrl = 'https://online.itel.com.sg';
        
        // Determine whether to use Moodle app or browser
        final useBrowser = true; // For now, always use browser to avoid the error
        
        if (useBrowser) {
          // Skip token retrieval and directly open course in browser
          String webUrl;
          if (course.moodleCourseId != null) {
            webUrl = '$moodleSiteUrl/course/view.php?id=${course.moodleCourseId}';
          } else {
            webUrl = '$moodleSiteUrl/my/';
          }
          
          print('Launching browser URL: $webUrl');
          final success = await launchUrl(
            Uri.parse(webUrl),
            mode: LaunchMode.externalApplication,
          );
          
          if (!success) {
            throw Exception('Could not launch Moodle URL');
          }
        } else {
          // This is the original method that's having issues - we'll skip this for now
          // Get Moodle token (or authenticate if needed)
          String? token;
          try {
            token = await _moodleService.getMoodleToken();
            
            if (token == null) {
              // Try to authenticate with Google
              final success = await _moodleService.authenticateWithGoogle();
              if (success) {
                token = await _moodleService.getMoodleToken();
              }
            }
          } catch (e) {
            print('Error getting Moodle token: $e');
            // Continue without token
          }
          
          // Fallback to browser if we couldn't get a token
          if (token == null) {
            String webUrl;
            if (course.moodleCourseId != null) {
              webUrl = '$moodleSiteUrl/course/view.php?id=${course.moodleCourseId}';
            } else {
              webUrl = moodleSiteUrl;
            }
            
            await launchUrl(
              Uri.parse(webUrl),
              mode: LaunchMode.externalApplication,
            );
            return;
          }
          
          // Format for course deep link with token
          String moodleUrl;
          if (course.moodleCourseId != null) {
            moodleUrl = 'moodlemobile://link=$moodleSiteUrl&token=$token&courseid=${course.moodleCourseId}';
          } else {
            moodleUrl = 'moodlemobile://link=$moodleSiteUrl&token=$token';
          }
          
          // Try to launch Moodle app
          final canOpenApp = await canLaunchUrl(Uri.parse(moodleUrl));
          
          if (canOpenApp) {
            await launchUrl(Uri.parse(moodleUrl));
          } else {
            // Fallback: open browser
            String webUrl;
            if (course.moodleCourseId != null) {
              webUrl = '$moodleSiteUrl/course/view.php?id=${course.moodleCourseId}';
            } else {
              webUrl = moodleSiteUrl;
            }
            
            await launchUrl(
              Uri.parse(webUrl),
              mode: LaunchMode.externalApplication,
            );
          }
        }
      } catch (e) {
        print('Error opening Moodle: $e');
        // Handle error gracefully
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not access Moodle. Opening course in browser instead.'),
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Fallback option: just open the main Moodle site
          try {
            await launchUrl(
              Uri.parse('https://online.itel.com.sg'),
              mode: LaunchMode.externalApplication,
            );
          } catch (browserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cannot open Moodle: $browserError')),
            );
          }
        }
      }
    } else {
      // For offline courses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course location: ${enrollment.location ?? "Not available"}')),
      );
    }
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
          
          // Progress indicator (if active)
          if (enrollment.progress != null) ...[
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
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Progress bar
            LinearProgressIndicator(
              value: double.tryParse(enrollment.progress!.replaceAll(RegExp(r'[^0-9.]'), ''))! / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
          ],
          
          // Next session details
          if (enrollment.nextSessionDate != null) ...[
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
                      color: Colors.blue[700],
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
                            color: Colors.blue[800],
                          ),
                        ),
                        Text(
                          '${_formatDate(enrollment.nextSessionDate!)} • ${enrollment.nextSessionTime}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          enrollment.isOnline ? 'Online Session' : enrollment.location ?? 'Location TBA',
                          style: TextStyle(
                            color: Colors.blue[600],
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
                  icon: const Icon(Icons.menu_book, size: 16),
                  label: const Text('Course Outline'),
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
              
              // Access course button (or location details)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchCourseURL(context),
                  icon: Icon(
                    enrollment.isOnline ? Icons.login : Icons.place,
                    size: 16,
                  ),
                  label: Text(enrollment.isOnline ? 'Access Course' : 'View Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}