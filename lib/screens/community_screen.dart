// lib/screens/community_screen.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/direct_message_service.dart';
import '../services/support_ticket_service.dart';
import '../services/forum_group_service.dart';
import 'global_chat_screen.dart';
import 'conversations_list_screen.dart';
import 'ask_itel_screen.dart';
import 'forum_list_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DirectMessageService _dmService = DirectMessageService();
  final SupportTicketService _ticketService = SupportTicketService();
  final ForumGroupService _forumService = ForumGroupService();

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
                          'Connect with ITEL community',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Messages icon with unread badge
                  if (!isGuest)
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
                                  const Text('Forum'),
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
                              Text('Forum'),
                            ],
                          ),
                  ),
                  const Tab(
                    icon: Icon(Icons.chat, size: 20),
                    text: 'ITEL Community',
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  // Ask ITEL Tab (Support Chat)
                  AskItelScreen(),
                  // Forum Tab (Group Forums)
                  ForumListScreen(),
                  // Global Chat Tab
                  GlobalChatScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
