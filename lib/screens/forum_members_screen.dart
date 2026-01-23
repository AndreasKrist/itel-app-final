// lib/screens/forum_members_screen.dart
import 'package:flutter/material.dart';
import '../models/forum_group.dart';
import '../models/forum_member.dart';
import '../models/forum_kick_log.dart';
import '../models/user.dart';
import '../services/forum_group_service.dart';

class ForumMembersScreen extends StatefulWidget {
  final String forumId;

  const ForumMembersScreen({super.key, required this.forumId});

  @override
  State<ForumMembersScreen> createState() => _ForumMembersScreenState();
}

class _ForumMembersScreenState extends State<ForumMembersScreen>
    with SingleTickerProviderStateMixin {
  final ForumGroupService _forumService = ForumGroupService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;

    return StreamBuilder<ForumGroup?>(
      stream: _forumService.getForumStream(widget.forumId),
      builder: (context, forumSnapshot) {
        final forum = forumSnapshot.data;
        final isCreator = forum?.isCreator(currentUser.id) ?? false;
        final isStaff = currentUser.isStaff;
        final canManage = isCreator || isStaff;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('Members'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0056AC),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF0056AC),
              tabs: const [
                Tab(text: 'Members'),
                Tab(text: 'Kick Log'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMembersTab(forum, canManage, isStaff, currentUser),
              _buildKickLogTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersTab(
      ForumGroup? forum, bool canManage, bool isStaff, User currentUser) {
    return StreamBuilder<List<ForumMember>>(
      stream: _forumService.getMembersStream(widget.forumId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final members = snapshot.data ?? [];

        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No members',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Sort: creator first, then by join date
        final sortedMembers = List<ForumMember>.from(members);
        sortedMembers.sort((a, b) {
          if (a.isCreator && !b.isCreator) return -1;
          if (!a.isCreator && b.isCreator) return 1;
          return a.joinedAt.compareTo(b.joinedAt);
        });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sortedMembers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final member = sortedMembers[index];
            final isCurrentUser = member.odGptUserId == currentUser.id;
            final canKick = canManage && !member.isCreator && !isCurrentUser;

            return Card(
              child: ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getAvatarColor(member.userName),
                      child: Text(
                        member.userName.isNotEmpty
                            ? member.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (member.isCreator)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.userName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (member.isCreator)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Creator',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (isCurrentUser && !member.isCreator)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF0056AC),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  member.userEmail,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: canKick
                    ? IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () =>
                            _showKickDialog(member, isStaff, forum!),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKickLogTab() {
    return StreamBuilder<List<ForumKickLog>>(
      stream: _forumService.getKickLogsStream(widget.forumId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No kick history',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kick actions will be logged here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final log = logs[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.red[100],
                          child: const Icon(
                            Icons.person_remove,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.kickedUserName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                log.kickedUserEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: log.kickedByStaff
                                ? Colors.purple[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            log.kickedByStaff ? 'By Staff' : 'By Creator',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: log.kickedByStaff
                                  ? Colors.purple
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reason:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.reason.isNotEmpty
                                ? log.reason
                                : 'No reason provided',
                            style: TextStyle(
                              fontSize: 14,
                              color: log.reason.isNotEmpty
                                  ? Colors.black87
                                  : Colors.grey,
                              fontStyle: log.reason.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'Kicked by ${log.kickedByName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(log.kickedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showKickDialog(
      ForumMember member, bool isStaff, ForumGroup forum) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${member.userName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Are you sure you want to remove ${member.userName} from the forum?'),
            if (!isStaff) ...[
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (required)',
                  hintText: 'Why are you removing this member?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (!isStaff && reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final currentUser = User.currentUser;
        await _forumService.kickMember(
          forumId: widget.forumId,
          odGptUserId: member.odGptUserId,
          kickedById: currentUser.id,
          kickedByName: currentUser.name,
          kickedByEmail: currentUser.email,
          kickedByStaff: isStaff,
          reason: isStaff
              ? 'Removed by ITEL staff'
              : reasonController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.userName} has been removed'),
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

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF0056AC),
      const Color(0xFFFF6600),
      const Color(0xFF4CAF50),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFFFF5722),
      const Color(0xFF3F51B5),
    ];
    if (name.isEmpty) return colors[0];
    final index = name.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
