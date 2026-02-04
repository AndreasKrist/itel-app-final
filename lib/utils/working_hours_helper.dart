// lib/utils/working_hours_helper.dart
import 'package:flutter/material.dart';

/// Helper class to check and handle working hours
/// Working hours: 9:30 AM - 6 PM SGT (Singapore Time, UTC+8)
class WorkingHoursHelper {
  /// Singapore Time (SGT) is UTC+8
  static const int sgtOffset = 8;
  
  /// DEBUG MODE: Set to true to test working hours
  /// Force override the time check result
  static bool debugForceWorkingHours = false;  // Set to true = always within hours
  static bool debugForceOutsideHours = false;  // Set to true = always outside hours

  /// Check if current time is within working hours (9:30 AM - 6 PM SGT)
  static bool isWithinWorkingHours() {
    // DEBUG MODE: Force override for testing
    if (debugForceWorkingHours) return true;
    if (debugForceOutsideHours) return false;

    final now = DateTime.now().toUtc();
    final sgtTime = now.add(const Duration(hours: sgtOffset));

    // Check if it's a weekend (Saturday = 6, Sunday = 7)
    if (sgtTime.weekday == DateTime.saturday || sgtTime.weekday == DateTime.sunday) {
      return false;
    }

    // Check if time is between 9:30 AM and 6 PM
    final hour = sgtTime.hour;
    final minute = sgtTime.minute;
    // After 9:30 AM (hour > 9, or hour == 9 and minute >= 30) and before 6 PM (hour < 18)
    return (hour > 9 || (hour == 9 && minute >= 30)) && hour < 18;
  }

  /// Get current SGT time
  static DateTime getSGTTime() {
    final now = DateTime.now().toUtc();
    return now.add(const Duration(hours: sgtOffset));
  }

  /// Get working hours status message
  static String getWorkingHoursMessage() {
    if (isWithinWorkingHours()) {
      return 'We are currently online (9:30 AM - 6 PM SGT)';
    }
    
    final sgtTime = getSGTTime();
    final isWeekend = sgtTime.weekday == DateTime.saturday || sgtTime.weekday == DateTime.sunday;
    
    if (isWeekend) {
      return 'Working hours: Monday-Friday, 9:30 AM - 6 PM SGT';
    } else {
      return 'Working hours: 9:30 AM - 6 PM SGT. Your question will be answered during working hours.';
    }
  }

  /// Show working hours notice dialog (for ticket creation)
  static Future<void> showWorkingHoursNotice(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.access_time, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Outside Working Hours',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your question will be answered within working hours.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 20, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Working Hours:\nMon-Fri, 9:30 AM - 6 PM SGT',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show working hours barrier for chat (when trying to send outside hours)
  static Widget buildWorkingHoursBarrier({required Widget child}) {
    if (isWithinWorkingHours()) {
      return child;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Chat unavailable outside working hours',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mon-Fri, 9:30 AM - 6 PM SGT',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get the next working day start time (for reference)
  static DateTime? getNextWorkingDayStart() {
    var sgtTime = getSGTTime();
    
    // If it's weekend or after 6 PM, move to next working day
    for (int i = 0; i < 7; i++) {
      sgtTime = sgtTime.add(const Duration(days: 1));
      
      // Check if it's a weekday (Mon-Fri)
      if (sgtTime.weekday >= DateTime.monday && sgtTime.weekday <= DateTime.friday) {
        // Return 9:30 AM of that day
        return DateTime(sgtTime.year, sgtTime.month, sgtTime.day, 9, 30);
      }
    }
    
    return null;
  }
}
