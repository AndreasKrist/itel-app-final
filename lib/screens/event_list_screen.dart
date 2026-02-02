// lib/screens/event_list_screen.dart
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import 'event_chat_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;
    final isStaff = currentUser.isStaff;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.event, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text(
              'Events',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepOrange,
          tabs: const [
            Tab(text: 'Live'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: StreamBuilder<List<Event>>(
        stream: _eventService.getAllEventsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allEvents = snapshot.data ?? [];
          final now = DateTime.now();

          // Categorize events
          final liveEvents = allEvents.where((e) => e.isActive).toList();
          final upcomingEvents = allEvents.where((e) => e.isPending).toList();
          final pastEvents = allEvents.where((e) => e.isExpired).toList();

          // Sort
          liveEvents.sort((a, b) => a.endTime.compareTo(b.endTime)); // Ending soonest first
          upcomingEvents.sort((a, b) => a.startTime.compareTo(b.startTime)); // Starting soonest first
          pastEvents.sort((a, b) => b.endTime.compareTo(a.endTime)); // Most recently ended first

          return TabBarView(
            controller: _tabController,
            children: [
              // Live Events
              _buildEventList(
                liveEvents,
                emptyIcon: Icons.event_available,
                emptyTitle: 'No Live Events',
                emptySubtitle: 'Check back later for active events',
              ),
              // Upcoming Events
              _buildEventList(
                upcomingEvents,
                emptyIcon: Icons.schedule,
                emptyTitle: 'No Upcoming Events',
                emptySubtitle: 'Stay tuned for future events',
              ),
              // Past Events
              _buildEventList(
                pastEvents,
                emptyIcon: Icons.history,
                emptyTitle: 'No Past Events',
                emptySubtitle: 'Past events will appear here',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList(
    List<Event> events, {
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubtitle,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EventCard(
            event: event,
            onTap: () => _openEvent(event),
          ),
        );
      },
    );
  }

  void _openEvent(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventChatScreen(eventId: event.id),
      ),
    );
  }
}
