import 'dart:async';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../screens/event_chat_screen.dart';
import '../screens/event_list_screen.dart';

class ActiveEventFloatingWidget extends StatefulWidget {
  const ActiveEventFloatingWidget({super.key});

  @override
  State<ActiveEventFloatingWidget> createState() =>
      _ActiveEventFloatingWidgetState();
}

class _ActiveEventFloatingWidgetState extends State<ActiveEventFloatingWidget>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Pulse animation for live events
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Timer for countdown update
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Event>>(
      stream: _eventService.getActiveEventsStream(),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];

        // Filter to only active events (not pending)
        final activeEvents = events.where((e) => e.isActive).toList();

        if (activeEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort by end time - show event ending soonest
        activeEvents.sort((a, b) => a.endTime.compareTo(b.endTime));
        final newestEvent = activeEvents.first;
        final hasMultipleEvents = activeEvents.length > 1;

        return Positioned(
          left: 16, // Changed to left side to avoid FAB overlap
          bottom: 90, // Above bottom navigation bar
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: GestureDetector(
              onTap: () => _handleTap(newestEvent, hasMultipleEvents),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[400]!, Colors.deepOrange[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Event icon with live indicator
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.event,
                            color: Colors.white,
                            size: 28,
                          ),
                          // Live indicator dot
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Countdown timer
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatRemainingTime(newestEvent.remainingTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Multiple events indicator
                      if (hasMultipleEvents) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${activeEvents.length - 1}',
                            style: TextStyle(
                              color: Colors.deepOrange[600],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(Event event, bool hasMultiple) {
    if (hasMultiple) {
      // Open event list if multiple events
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EventListScreen(),
        ),
      );
    } else {
      // Open single event directly
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventChatScreen(eventId: event.id),
        ),
      );
    }
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
