import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/courses_screen.dart';
import '../screens/course_detail_screen.dart';
import '../services/course_remote_config_service.dart';
import '../models/course.dart';

/// A utility class to handle opening external links
class LinkHandler {
  /// Opens a link in the default browser
  static Future<void> openLink(BuildContext context, String? link, {String? fallbackMessage}) async {
    if (link != null && link.isNotEmpty) {
      final Uri uri = Uri.parse(link);
      
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication, // Opens in external browser
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $link')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } else if (fallbackMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fallbackMessage)),
      );
    }
  }

  /// Opens an event registration link
  static Future<void> openEventRegistration(BuildContext context, String? eventLink) async {
    await openLink(
      context, 
      eventLink, 
      fallbackMessage: 'Registration functionality coming soon!'
    );
  }

  /// Opens a news item link
  static Future<void> openNewsLink(BuildContext context, String? newsLink) async {
    await openLink(
      context, 
      newsLink, 
      fallbackMessage: 'News details functionality coming soon!'
    );
  }

  /// Opens a related courses link - navigates to specific course or CoursesScreen
  static Future<void> openRelatedCoursesLink(BuildContext context, String? coursesLink) async {
    if (coursesLink != null && coursesLink.isNotEmpty) {
      // Check if it's a course:// scheme
      if (coursesLink.startsWith('course://')) {
        final courseId = coursesLink.replaceFirst('course://', '');
        await _navigateToSpecificCourse(context, courseId);
      } else {
        // Handle regular HTTP links
        await openLink(context, coursesLink);
      }
    } else {
      // Navigate to the CoursesScreen as fallback
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CoursesScreen(),
        ),
      );
    }
  }

  /// Navigate to a specific course by ID
  static Future<void> _navigateToSpecificCourse(BuildContext context, String courseId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Fetch courses from remote config service
      final courseService = CourseRemoteConfigService();
      final courses = await courseService.getRemoteCourses();

      // Find the specific course
      final course = courses.firstWhere(
        (c) => c.id == courseId,
        orElse: () => throw Exception('Course not found'),
      );

      // Hide loading indicator
      Navigator.pop(context);

      // Navigate to course detail
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailScreen(course: course),
        ),
      );
    } catch (e) {
      // Hide loading indicator if still showing
      Navigator.pop(context);

      // Show error and fallback to courses screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course not found. Showing all courses instead.')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CoursesScreen(),
        ),
      );
    }
  }
}