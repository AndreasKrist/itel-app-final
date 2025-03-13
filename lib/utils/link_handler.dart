import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// Opens a related courses link
  static Future<void> openRelatedCoursesLink(BuildContext context, String? coursesLink) async {
    await openLink(
      context, 
      coursesLink, 
      fallbackMessage: 'Related courses functionality coming soon!'
    );
  }
}