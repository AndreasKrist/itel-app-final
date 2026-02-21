import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/event.dart';

/// Service to schedule local notifications for event countdown warnings.
/// Uses Timer + show() approach for reliable cross-device compatibility.
/// Tracks which thresholds have already been notified to avoid duplicates
/// and to fire missed notifications on app resume.
class EventNotificationService {
  static final EventNotificationService _instance =
      EventNotificationService._internal();
  factory EventNotificationService() => _instance;
  EventNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Set to true to re-enable event countdown notifications in the future.
  static const bool _enabled = false;

  bool _initialized = false;

  /// Active timers per event
  final Map<String, List<Timer>> _activeTimers = {};

  /// Track which thresholds have already been notified per event
  /// so we don't send duplicates and can detect missed ones on resume
  final Map<String, Set<int>> _notifiedThresholds = {};

  /// Thresholds in minutes before event end
  static const List<int> _thresholds = [15, 10, 5, 1];

  /// Initialize the notification plugin. Call once at app startup.
  Future<void> initialize() async {
    if (!_enabled) return;
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Request notification permission on Android 13+
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// Generate a unique notification ID from eventId and threshold.
  int _notificationId(String eventId, int minutesBefore) {
    return '${eventId}_$minutesBefore'.hashCode.abs() % 2147483647;
  }

  /// Show a notification. Wrapped in try-catch to prevent crashes.
  Future<void> _showNotification({required int id, required String title, required String body}) async {
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_countdown',
            'Event Countdown',
            channelDescription: 'Notifications for event countdown warnings',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      print('[EventNotif] Failed to show notification: $e');
    }
  }

  String _bodyForThreshold(int minutes) {
    return minutes == 1
        ? 'An event will end very soon!'
        : 'An event will end in $minutes minutes!';
  }

  /// Schedule countdown notifications for an event using Timers.
  /// Safe to call multiple times (e.g., on app resume) — it will:
  /// 1. Fire any missed notifications that should have gone out while app was sleeping
  /// 2. Re-schedule timers for upcoming thresholds
  /// 3. Skip thresholds that were already notified
  void scheduleEventNotifications(Event event) {
    if (!_enabled) return;
    if (!_initialized) return;

    // Cancel existing timers (we'll re-create them)
    final existingTimers = _activeTimers.remove(event.id);
    if (existingTimers != null) {
      for (final timer in existingTimers) {
        timer.cancel();
      }
    }

    final now = DateTime.now();

    if (event.isExpired) return;

    // Initialize notified set for this event if needed
    _notifiedThresholds.putIfAbsent(event.id, () => {});
    final notified = _notifiedThresholds[event.id]!;

    final timers = <Timer>[];
    for (final minutes in _thresholds) {
      // Skip if already notified for this threshold
      if (notified.contains(minutes)) continue;

      final notifyAt = event.endTime.subtract(Duration(minutes: minutes));
      final delay = notifyAt.difference(now);

      if (delay.isNegative) {
        // This threshold has passed — fire it now (missed while app was sleeping)
        notified.add(minutes);
        // Only show the most relevant missed one (smallest minutes = most urgent)
        // We'll handle this after the loop
      } else {
        // Schedule for the future
        final timer = Timer(delay, () {
          notified.add(minutes);
          _showNotification(
            id: _notificationId(event.id, minutes),
            title: 'Welcome to ITEL',
            body: _bodyForThreshold(minutes),
          );
        });
        timers.add(timer);
      }
    }

    // Fire the most relevant missed notification (the one closest to "now")
    // e.g., if 15min and 10min were both missed, only show the 10min one
    final missedThresholds = _thresholds
        .where((m) => notified.contains(m) && !_wasPreviouslyNotified(event.id, m))
        .toList();

    if (missedThresholds.isNotEmpty) {
      // Show only the most urgent missed one (smallest number)
      final mostUrgent = missedThresholds.last; // last because _thresholds is [15,10,5,1]
      _showNotification(
        id: _notificationId(event.id, mostUrgent),
        title: 'Welcome to ITEL',
        body: _bodyForThreshold(mostUrgent),
      );
      // Mark all missed as "previously notified" so we don't re-fire on next resume
      _previouslyNotified.addAll(
        missedThresholds.map((m) => '${event.id}_$m'),
      );
    }

    _activeTimers[event.id] = timers;
  }

  /// Track which missed notifications we've already fired on resume
  final Set<String> _previouslyNotified = {};

  bool _wasPreviouslyNotified(String eventId, int minutes) {
    return _previouslyNotified.contains('${eventId}_$minutes');
  }

  /// Cancel all scheduled notifications for a specific event.
  void cancelEventNotifications(String eventId) {
    final timers = _activeTimers.remove(eventId);
    if (timers != null) {
      for (final timer in timers) {
        timer.cancel();
      }
    }
    _notifiedThresholds.remove(eventId);
    _previouslyNotified.removeWhere((key) => key.startsWith('${eventId}_'));
  }

  /// Cancel all event notifications.
  void cancelAll() {
    for (final entry in _activeTimers.entries) {
      for (final timer in entry.value) {
        timer.cancel();
      }
    }
    _activeTimers.clear();
    _notifiedThresholds.clear();
    _previouslyNotified.clear();
    _plugin.cancelAll();
  }
}
