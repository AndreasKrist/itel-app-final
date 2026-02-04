// lib/screens/community_screen.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../services/direct_message_service.dart';
import '../services/support_ticket_service.dart';
import '../services/career_ticket_service.dart';
import '../services/forum_group_service.dart';
import '../services/event_service.dart';
import 'global_chat_screen.dart';
import 'conversations_list_screen.dart';
import 'ask_itel_screen.dart';
import 'career_advisory_screen.dart';
import 'forum_list_screen.dart';
import 'event_chat_screen.dart';
import 'event_list_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final DirectMessageService _dmService = DirectMessageService();
  final SupportTicketService _ticketService = SupportTicketService();
  final CareerTicketService _careerTicketService = CareerTicketService();
  final ForumGroupService _forumService = ForumGroupService();
  final EventService _eventService = EventService();

  bool _showLiveEventsTab = false;
  int _lastTabCount = 4;

  @override
  void initState() {
    super.initState();
    _initTabController(4);
  }

  void _initTabController(int length) {
    final oldIndex = _tabController?.index ?? 0;
    _tabController?.dispose();
    _tabController = TabController(length: length, vsync: this);
    _lastTabCount = length;

    // Restore tab position if possible
    if (oldIndex < length) {
      _tabController!.index = oldIndex;
    }
  }

  void _updateTabsIfNeeded(bool shouldShowLiveEvents) {
    if (_showLiveEventsTab != shouldShowLiveEvents) {
      _showLiveEventsTab = shouldShowLiveEvents;
      final newCount = shouldShowLiveEvents ? 5 : 4;
      if (_lastTabCount != newCount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _initTabController(newCount);
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo and title
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Row(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.1,
                    height: MediaQuery.of(context).size.width * 0.1,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/itel.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Connect with ITEL Community',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Messages icon with unread badge
                  // TODO: Hidden for now - set to true to enable DM feature
                  if (false && !isGuest)
                    StreamBuilder<int>(
                      stream: _dmService.getTotalUnreadCountStream(currentUser.id),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        return IconButton(
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.mail_outline,
                                color: unreadCount > 0
                                    ? const Color(0xFF0056AC)
                                    : Colors.grey[600],
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: -6,
                                  top: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ConversationsListScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),

            // Tab bar and content - wrapped in StreamBuilder to handle dynamic Live Events tab
            StreamBuilder<List<Event>>(
              stream: _eventService.getActiveEventsStream(),
              builder: (context, eventSnapshot) {
                final events = eventSnapshot.data ?? [];
                final hasEvents = events.isNotEmpty;

                // Staff always sees Live Events tab, users only see it when there are events
                final shouldShowLiveEvents = currentUser.isStaff || hasEvents;

                // Update tabs if needed
                _updateTabsIfNeeded(shouldShowLiveEvents);

                if (_tabController == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Expanded(
                  child: Column(
                    children: [
                      // Tab bar
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: const Color(0xFF0056AC),
                          unselectedLabelColor: Colors.grey[600],
                          indicatorColor: const Color(0xFF0056AC),
                          indicatorWeight: 3,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          tabs: [
                            // Live Events tab (only if shouldShowLiveEvents)
                            if (shouldShowLiveEvents)
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.flash_on, size: 20),
                                    const SizedBox(width: 4),
                                    const Text('Live Events'),
                                    if (hasEvents) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: Colors.deepOrange,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          '${events.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            // Ask ITEL tab with badge for staff
                            Tab(
                              child: currentUser.isStaff
                                  ? StreamBuilder<int>(
                                      stream: _ticketService.getUnattendedTicketsCountStream(),
                                      builder: (context, snapshot) {
                                        final count = snapshot.data ?? 0;
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.support_agent, size: 20),
                                            const SizedBox(width: 4),
                                            const Text('Ask ITEL'),
                                            if (count > 0) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 18,
                                                  minHeight: 18,
                                                ),
                                                child: Text(
                                                  count > 99 ? '99+' : '$count',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ],
                                        );
                                      },
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.support_agent, size: 20),
                                        SizedBox(width: 4),
                                        Text('Ask ITEL'),
                                      ],
                                    ),
                            ),
                            // Career Advisory tab with badge for staff
                            Tab(
                              child: currentUser.isStaff
                                  ? StreamBuilder<int>(
                                      stream: _careerTicketService.getUnattendedTicketsCountStream(),
                                      builder: (context, snapshot) {
                                        final count = snapshot.data ?? 0;
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.work_outline, size: 20),
                                            const SizedBox(width: 4),
                                            const Text('Career Advisory'),
                                            if (count > 0) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 18,
                                                  minHeight: 18,
                                                ),
                                                child: Text(
                                                  count > 99 ? '99+' : '$count',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ],
                                        );
                                      },
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.work_outline, size: 20),
                                        SizedBox(width: 4),
                                        Text('Career Advisory'),
                                      ],
                                    ),
                            ),
                            // Forum tab with badge for pending invitations
                            Tab(
                              child: !isGuest
                                  ? StreamBuilder<int>(
                                      stream: _forumService.getUserInvitationsCountStream(currentUser.id),
                                      builder: (context, snapshot) {
                                        final count = snapshot.data ?? 0;
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.forum, size: 20),
                                            const SizedBox(width: 4),
                                            const Text('Channels'),
                                            if (count > 0) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.orange,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 18,
                                                  minHeight: 18,
                                                ),
                                                child: Text(
                                                  count > 99 ? '99+' : '$count',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ],
                                        );
                                      },
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.forum, size: 20),
                                        SizedBox(width: 4),
                                        Text('Channels'),
                                      ],
                                    ),
                            ),
                            const Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat, size: 20),
                                  SizedBox(width: 4),
                                  Text('Connect'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tab content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Live Events Tab (only if shouldShowLiveEvents)
                            if (shouldShowLiveEvents) _buildLiveEventsTab(),
                            // Ask ITEL Tab (Support Chat)
                            const AskItelScreen(),
                            // Career Advisory Tab
                            const CareerAdvisoryScreen(),
                            // Forum Tab (Group Forums)
                            const ForumListScreen(),
                            // Global Chat Tab
                            const GlobalChatScreen(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      // FAB moved to ForumListScreen to avoid overlap
    );
  }

  Widget _buildLiveEventsTab() {
    final currentUser = User.currentUser;

    return StreamBuilder<List<Event>>(
      stream: _eventService.getActiveEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No live events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for flash sales and events!',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
                if (currentUser.isStaff) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EventListScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Manage Events'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: events.length + (currentUser.isStaff ? 1 : 0),
          itemBuilder: (context, index) {
            // Staff manage button at the end
            if (currentUser.isStaff && index == events.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EventListScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage All Events'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    side: const BorderSide(color: Colors.deepOrange),
                  ),
                ),
              );
            }
            return _buildEventCard(events[index]);
          },
        );
      },
    );
  }

  Widget _buildEventCard(Event event) {
    final isActive = event.isActive;
    final isPending = event.isPending;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventChatScreen(eventId: event.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [Colors.orange[400]!, Colors.deepOrange[500]!]
                : [Colors.blue[400]!, Colors.blue[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isActive ? Colors.orange : Colors.blue).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Event icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isActive ? Icons.flash_on : Icons.schedule,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Event details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: Colors.white.withOpacity(0.8),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isActive
                              ? 'Ends in ${_formatDuration(event.remainingTime)}'
                              : 'Starts in ${_formatDuration(event.timeUntilStart)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status and open button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.live_tv : Icons.upcoming,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isActive ? 'LIVE' : 'SOON',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Open',
                      style: TextStyle(
                        color: isActive ? Colors.deepOrange : Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
