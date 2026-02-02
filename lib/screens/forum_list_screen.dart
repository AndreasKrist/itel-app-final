// lib/screens/forum_list_screen.dart
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/forum_group.dart';
import '../models/forum_invitation.dart';
import '../models/user.dart';
import '../services/event_service.dart';
import '../services/forum_group_service.dart';
import '../widgets/event_card.dart';
import '../widgets/create_event_sheet.dart';
import 'create_forum_screen.dart';
import 'event_chat_screen.dart';
import 'forum_chat_screen.dart';

class ForumListScreen extends StatefulWidget {
  const ForumListScreen({super.key});

  @override
  State<ForumListScreen> createState() => _ForumListScreenState();
}

class _ForumListScreenState extends State<ForumListScreen>
    with SingleTickerProviderStateMixin {
  final ForumGroupService _forumService = ForumGroupService();
  final EventService _eventService = EventService();
  late TabController _tabController;
  String _filter = 'all'; // all, my_forums, public, private
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    final currentUser = User.currentUser;
    final isStaff = currentUser.isStaff;
    _tabController = TabController(length: isStaff ? 3 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;
    final isStaff = currentUser.isStaff;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0056AC),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF0056AC),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: [
                const Tab(text: 'All Forums'),
                const Tab(text: 'My Forums'),
                if (isStaff) const Tab(text: 'Pending'),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllForumsTab(isGuest, currentUser),
                _buildMyForumsTab(isGuest, currentUser),
                if (isStaff) _buildPendingForumsTab(currentUser),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isGuest
          ? null
          : isStaff
              ? _buildStaffFab()
              : FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateForumScreen(),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF0056AC),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Create Forum',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
    );
  }

  /// Build expandable FAB for staff users with Create Forum and Create Event options
  Widget _buildStaffFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded options (shown when _isFabExpanded is true)
        if (_isFabExpanded) ...[
          // Create Event option
          _FabOption(
            icon: Icons.event,
            label: 'Create Event',
            color: Colors.deepOrange,
            onTap: () {
              setState(() => _isFabExpanded = false);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const CreateEventSheet(),
              );
            },
          ),
          const SizedBox(height: 12),
          // Create Forum option
          _FabOption(
            icon: Icons.forum,
            label: 'Create Forum',
            color: const Color(0xFF0056AC),
            onTap: () {
              setState(() => _isFabExpanded = false);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateForumScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        // Main FAB button
        FloatingActionButton(
          onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded),
          backgroundColor: _isFabExpanded ? Colors.grey[700] : const Color(0xFF0056AC),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: _isFabExpanded ? 0.125 : 0, // 45 degrees rotation
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildAllForumsTab(bool isGuest, User currentUser) {
    return StreamBuilder<List<ForumGroup>>(
      stream: _forumService.getApprovedForumsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error.toString());
        }

        final forums = snapshot.data ?? [];

        if (forums.isEmpty) {
          return _buildEmptyView(
            'No forums yet',
            'Be the first to create a forum!',
            showCreateButton: !isGuest,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: Column(
            children: [
              // Live Events section
              StreamBuilder<List<Event>>(
                stream: _eventService.getActiveEventsStream(),
                builder: (context, eventSnapshot) {
                  final allEvents = eventSnapshot.data ?? [];
                  // Filter to active and pending events
                  final activeEvents = allEvents.where((e) => e.isActive || e.isPending).toList();

                  if (activeEvents.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Sort by active first, then by end time
                  activeEvents.sort((a, b) {
                    if (a.isActive && !b.isActive) return -1;
                    if (!a.isActive && b.isActive) return 1;
                    return a.endTime.compareTo(b.endTime);
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.event,
                                color: Colors.deepOrange,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Live Events',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: activeEvents.any((e) => e.isActive) ? Colors.green : Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${activeEvents.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Horizontal scrolling event cards
                      SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: activeEvents.length,
                          itemBuilder: (context, index) {
                            final event = activeEvents[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: EventCardCompact(
                                event: event,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventChatScreen(eventId: event.id),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),

              // Show invitation alert banner if not guest
              if (!isGuest)
                StreamBuilder<int>(
                  stream: _forumService.getUserInvitationsCountStream(currentUser.id),
                  builder: (context, invSnapshot) {
                    // Debug: print any errors
                    if (invSnapshot.hasError) {
                      print('Invitation count error: ${invSnapshot.error}');
                    }
                    final invCount = invSnapshot.data ?? 0;
                    if (invCount == 0) return const SizedBox.shrink();

                    return GestureDetector(
                      onTap: () {
                        // Switch to My Forums tab
                        _tabController.animateTo(1);
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[400]!, Colors.orange[600]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.mail,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'You have $invCount pending invitation${invCount > 1 ? 's' : ''}!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Tap here to view and respond',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Forums list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: forums.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final forum = forums[index];
                    return _buildForumCard(forum, currentUser);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyForumsTab(bool isGuest, User currentUser) {
    if (isGuest) {
      return _buildGuestView();
    }

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: CustomScrollView(
        slivers: [
          // Pending invitations section
          StreamBuilder<List<ForumInvitation>>(
            stream: _forumService.getUserInvitationsStream(currentUser.id),
            builder: (context, invitationsSnapshot) {
              // Debug: print any errors
              if (invitationsSnapshot.hasError) {
                print('Invitations error: ${invitationsSnapshot.error}');
              }

              final invitations = invitationsSnapshot.data ?? [];

              if (invitations.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.mail,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pending Invitations',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                  Text(
                                    'You have ${invitations.length} forum invitation${invitations.length > 1 ? 's' : ''} waiting',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${invitations.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Invitation cards
                      ...invitations.map((invitation) => _buildInvitationCard(invitation)),
                      const SizedBox(height: 8),
                      const Divider(thickness: 1),
                      const SizedBox(height: 8),
                      // My Forums label
                      Text(
                        'My Forums',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // My forums section
          StreamBuilder<List<ForumGroup>>(
            stream: _forumService.getUserForumsStream(currentUser.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: _buildErrorView(snapshot.error.toString()),
                );
              }

              final forums = snapshot.data ?? [];

              if (forums.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyView(
                    'No forums yet',
                    'Join or create a forum to get started!',
                    showCreateButton: true,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final forum = forums[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMyForumCard(forum, currentUser),
                      );
                    },
                    childCount: forums.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(ForumInvitation invitation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[50]!, Colors.orange[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[300]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with invitation badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mail, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'FORUM INVITATION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Forum title
            Text(
              invitation.forumTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Invited by info
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.orange[300],
                  child: Text(
                    invitation.invitedByName.isNotEmpty
                        ? invitation.invitedByName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Invited by ${invitation.invitedByName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _declineInvitation(invitation),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptInvitation(invitation),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept & Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
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

  Future<void> _acceptInvitation(ForumInvitation invitation) async {
    try {
      await _forumService.acceptInvitation(invitation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You joined "${invitation.forumTitle}"!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to the forum
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForumChatScreen(forumId: invitation.forumId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineInvitation(ForumInvitation invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Invitation'),
        content: Text('Decline invitation to join "${invitation.forumTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _forumService.declineInvitation(invitation.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invitation declined'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildPendingForumsTab(User currentUser) {
    return StreamBuilder<List<ForumGroup>>(
      stream: _forumService.getPendingForumsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error.toString());
        }

        final forums = snapshot.data ?? [];

        if (forums.isEmpty) {
          return _buildEmptyView(
            'No pending forums',
            'All forums have been reviewed!',
            showCreateButton: false,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: forums.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final forum = forums[index];
              return _buildPendingForumCard(forum, currentUser);
            },
          ),
        );
      },
    );
  }

  Widget _buildForumCard(ForumGroup forum, User currentUser,
      {bool showJoinStatus = true}) {
    final isStaff = currentUser.isStaff;
    final isMember = forum.isMember(currentUser.id, isStaff: isStaff);
    final isCreator = forum.isCreator(currentUser.id);
    final isGuest = currentUser.id.isEmpty;
    final canAccess = isMember || isStaff;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: canAccess
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ForumChatScreen(forumId: forum.id),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Forum icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0056AC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      forum.isPublic ? Icons.public : Icons.lock,
                      color: const Color(0xFF0056AC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          forum.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'by ${forum.creatorName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Visibility badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: forum.isPublic
                          ? Colors.green[50]
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      forum.isPublic ? 'Public' : 'Private',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: forum.isPublic ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              if (forum.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  forum.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${forum.memberCount} members',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  if (forum.lastMessageAt != null)
                    Text(
                      _formatDate(forum.lastMessageAt!),
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                ],
              ),
              if (showJoinStatus && !isMember && !isGuest && !isStaff) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleJoin(forum, currentUser),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0056AC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                        forum.isPublic ? 'Join Forum' : 'Request to Join'),
                  ),
                ),
              ],
              // Staff badge (staff can access without being a member)
              if (isStaff && !isMember) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings, size: 14, color: Colors.purple),
                      SizedBox(width: 4),
                      Text(
                        'Staff Access',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isMember && !isCreator && !isStaff) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0056AC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: Color(0xFF0056AC)),
                      SizedBox(width: 4),
                      Text(
                        'Member',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0056AC),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isCreator) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Creator',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyForumCard(ForumGroup forum, User currentUser) {
    final isCreator = forum.isCreator(currentUser.id);
    final isRejected = forum.approvalStatus == ForumApprovalStatus.rejected;
    final isPending = forum.approvalStatus == ForumApprovalStatus.pending;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: (isRejected || isPending)
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ForumChatScreen(forumId: forum.id),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Forum icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isRejected
                          ? Colors.red.withOpacity(0.1)
                          : isPending
                              ? Colors.orange.withOpacity(0.1)
                              : const Color(0xFF0056AC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isRejected
                          ? Icons.cancel
                          : isPending
                              ? Icons.hourglass_empty
                              : forum.isPublic
                                  ? Icons.public
                                  : Icons.lock,
                      color: isRejected
                          ? Colors.red
                          : isPending
                              ? Colors.orange
                              : const Color(0xFF0056AC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          forum.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'by ${forum.creatorName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRejected
                          ? Colors.red[50]
                          : isPending
                              ? Colors.orange[50]
                              : forum.isPublic
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isRejected
                          ? 'Rejected'
                          : isPending
                              ? 'Pending'
                              : forum.isPublic
                                  ? 'Public'
                                  : 'Private',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isRejected
                            ? Colors.red
                            : isPending
                                ? Colors.orange
                                : forum.isPublic
                                    ? Colors.green
                                    : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              // Show rejection reason
              if (isRejected && forum.rejectionReason != null && forum.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
                          const SizedBox(width: 6),
                          Text(
                            'Rejection Reason:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        forum.rejectionReason!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Show pending message
              if (isPending) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Waiting for staff approval',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (forum.description.isNotEmpty && !isRejected && !isPending) ...[
                const SizedBox(height: 12),
                Text(
                  forum.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${forum.memberCount} members',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  if (forum.lastMessageAt != null && !isRejected && !isPending)
                    Text(
                      _formatDate(forum.lastMessageAt!),
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                ],
              ),
              if (isCreator && !isRejected && !isPending) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Creator',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingForumCard(ForumGroup forum, User currentUser) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with creator info and status
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.hourglass_empty,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'by ${forum.creatorName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        forum.creatorEmail,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: forum.isPublic ? Colors.green[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            forum.isPublic ? Icons.public : Icons.lock,
                            size: 10,
                            color: forum.isPublic ? Colors.green : Colors.blue,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            forum.isPublic ? 'Public' : 'Private',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: forum.isPublic ? Colors.green : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Subject section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0056AC).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0056AC).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.title, size: 14, color: const Color(0xFF0056AC)),
                      const SizedBox(width: 6),
                      Text(
                        'SUBJECT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0056AC),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    forum.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Description section
            if (forum.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          'DESCRIPTION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      forum.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectForum(forum, currentUser),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveForum(forum, currentUser),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
      ),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Sign in to join forums',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create or join forums to chat with others',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(String title, String subtitle,
      {bool showCreateButton = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            if (showCreateButton) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateForumScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Forum'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0056AC),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading forums',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0056AC),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleJoin(ForumGroup forum, User currentUser) async {
    try {
      if (forum.isPublic) {
        // For public forums, add directly (no invitation needed)
        await _forumService.addMemberDirectly(
          forumId: forum.id,
          odGptUserId: currentUser.id,
          userName: currentUser.name,
          userEmail: currentUser.email,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully joined the forum!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to forum
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForumChatScreen(forumId: forum.id),
            ),
          );
        }
      } else {
        await _forumService.requestJoin(
          forumId: forum.id,
          odGptUserId: currentUser.id,
          userName: currentUser.name,
          userEmail: currentUser.email,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Join request sent! Waiting for approval.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveForum(ForumGroup forum, User currentUser) async {
    try {
      await _forumService.approveForum(
        forumId: forum.id,
        approvedById: currentUser.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Forum approved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectForum(ForumGroup forum, User currentUser) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Forum'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject "${forum.title}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (required)',
                hintText: 'Explain why this forum is being rejected',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _forumService.rejectForum(
          forumId: forum.id,
          rejectedById: currentUser.id,
          reason: reasonController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Forum rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return 'Just now';
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// FAB option widget for the expandable staff FAB
class _FabOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FabOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Icon button
        FloatingActionButton.small(
          heroTag: 'fab_$label',
          onPressed: onTap,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}
