// lib/screens/ask_itel_screen.dart
import 'package:flutter/material.dart';
import '../models/support_ticket.dart';
import '../models/user.dart';
import '../services/support_ticket_service.dart';
import 'support_chat_screen.dart';

class AskItelScreen extends StatefulWidget {
  const AskItelScreen({super.key});

  @override
  State<AskItelScreen> createState() => _AskItelScreenState();
}

class _AskItelScreenState extends State<AskItelScreen> {
  final SupportTicketService _ticketService = SupportTicketService();
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;
    final isStaff = currentUser.isStaff;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Filter indicator
          if (_filterStatus != 'all')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _filterStatus == 'open'
                          ? Colors.orange[50]
                          : _filterStatus == 'resolved'
                              ? Colors.green[50]
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _filterStatus == 'open'
                            ? Colors.orange[200]!
                            : _filterStatus == 'resolved'
                                ? Colors.green[200]!
                                : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _filterStatus == 'open'
                              ? Icons.support_agent
                              : _filterStatus == 'resolved'
                                  ? Icons.check_circle
                                  : Icons.lock,
                          size: 14,
                          color: _filterStatus == 'open'
                              ? const Color(0xFFFF6600)
                              : _filterStatus == 'resolved'
                                  ? Colors.green
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Showing: ${_filterStatus == 'open' ? 'Open' : _filterStatus == 'resolved' ? 'Resolved' : 'Closed'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _filterStatus == 'open'
                                ? const Color(0xFFFF6600)
                                : _filterStatus == 'resolved'
                                    ? Colors.green
                                    : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _filterStatus = 'all'),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: _filterStatus == 'open'
                                ? const Color(0xFFFF6600)
                                : _filterStatus == 'resolved'
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Guest message
          if (isGuest)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sign in to contact ITEL support',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Tickets list
          Expanded(
            child: isGuest
                ? _buildGuestView()
                : StreamBuilder<List<SupportTicket>>(
                    stream: isStaff
                        ? _ticketService.getAllTicketsStream()
                        : _ticketService.getUserTicketsStream(currentUser.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading conversations...'),
                            ],
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading conversations',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
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

                      var tickets = snapshot.data ?? [];

                      // Apply filter
                      if (_filterStatus == 'open') {
                        tickets = tickets
                            .where((t) => t.status == TicketStatus.open)
                            .toList();
                      } else if (_filterStatus == 'resolved') {
                        tickets = tickets
                            .where((t) => t.status == TicketStatus.resolved)
                            .toList();
                      } else if (_filterStatus == 'closed') {
                        tickets = tickets
                            .where((t) => t.status == TicketStatus.closed)
                            .toList();
                      }

                      if (tickets.isEmpty) {
                        return _buildEmptyView(isStaff);
                      }

                      return RefreshIndicator(
                        onRefresh: () async => setState(() {}),
                        child: ListView.separated(
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width * 0.04),
                          itemCount: tickets.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            return _buildTicketCard(ticket, isStaff);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: isGuest
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showCreateTicketDialog(),
              backgroundColor: const Color(0xFF0056AC),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create Question',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
            Icon(Icons.support_agent, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'ITEL Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to start a conversation with our support team',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(bool isStaff) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _filterStatus == 'all'
                  ? (isStaff ? 'No support tickets' : 'No conversations yet')
                  : 'No $_filterStatus tickets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isStaff
                  ? 'Support requests will appear here'
                  : 'Tap + to start a conversation with ITEL support',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket, bool isStaff) {
    final currentUser = User.currentUser;
    final statusColor = ticket.status == TicketStatus.open
        ? const Color(0xFFFF6600)
        : ticket.status == TicketStatus.resolved
            ? Colors.green
            : Colors.grey;

    final statusIcon = ticket.status == TicketStatus.open
        ? Icons.support_agent
        : ticket.status == TicketStatus.resolved
            ? Icons.check_circle
            : Icons.lock;

    // Staff-specific indicators
    final bool isUnviewedByCurrentStaff = isStaff &&
        ticket.status == TicketStatus.open &&
        !ticket.hasBeenViewedByStaff(currentUser.id);
    final bool needsStaffReply = isStaff &&
        ticket.status == TicketStatus.open &&
        !ticket.hasStaffReply;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SupportChatScreen(
                ticketId: ticket.id,
                ticketSubject: ticket.subject,
              ),
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
                  // NEW badge for staff - unviewed ticket
                  if (isUnviewedByCurrentStaff) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          ticket.status == TicketStatus.open
                              ? 'Open'
                              : ticket.status == TicketStatus.resolved
                                  ? 'Resolved'
                                  : 'Closed',
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isStaff) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ticket.creatorName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    // No Reply indicator for staff
                    if (needsStaffReply)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.reply, size: 10, color: Colors.orange[700]),
                            const SizedBox(width: 2),
                            Text(
                              'No Reply',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              if (ticket.lastMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  ticket.lastMessage!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '${ticket.messageCount} messages',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(ticket.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return 'Just now';
        }
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showCreateTicketDialog() {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact ITEL'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'Brief description of your issue',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Describe your issue in detail',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 500,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final subject = subjectController.text.trim();
              final message = messageController.text.trim();

              if (subject.isEmpty || message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final currentUser = User.currentUser;
                final ticketId = await _ticketService.createTicket(
                  creatorId: currentUser.id,
                  creatorName: currentUser.name,
                  creatorEmail: currentUser.email,
                  subject: subject,
                  initialMessage: message,
                );

                if (mounted) {
                  // Navigate to the new ticket chat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SupportChatScreen(
                        ticketId: ticketId,
                        ticketSubject: subject,
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating ticket: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0056AC),
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildFilterItem(
      String value, String label, IconData icon) {
    Color iconColor;
    if (value == 'open') {
      iconColor =
          _filterStatus == 'open' ? const Color(0xFFFF6600) : Colors.grey;
    } else if (value == 'resolved') {
      iconColor = _filterStatus == 'resolved' ? Colors.green : Colors.grey;
    } else if (value == 'closed') {
      iconColor = _filterStatus == 'closed' ? Colors.grey : Colors.grey;
    } else {
      iconColor =
          _filterStatus == 'all' ? const Color(0xFF0056AC) : Colors.grey;
    }

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
