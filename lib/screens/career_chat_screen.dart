// lib/screens/career_chat_screen.dart
import 'package:flutter/material.dart';
import '../models/career_ticket.dart';
import '../models/career_message.dart';
import '../models/user.dart';
import '../services/career_ticket_service.dart';
import '../widgets/career_message_bubble.dart';

class CareerChatScreen extends StatefulWidget {
  final String ticketId;
  final String ticketSubject;

  const CareerChatScreen({
    super.key,
    required this.ticketId,
    required this.ticketSubject,
  });

  @override
  State<CareerChatScreen> createState() => _CareerChatScreenState();
}

class _CareerChatScreenState extends State<CareerChatScreen> {
  final CareerTicketService _ticketService = CareerTicketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _markAsViewedByStaff();
  }

  Future<void> _markAsViewedByStaff() async {
    final currentUser = User.currentUser;
    if (currentUser.isStaff && currentUser.id.isNotEmpty) {
      await _ticketService.markAsViewedByStaff(widget.ticketId, currentUser.id);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final currentUser = User.currentUser;
    if (currentUser.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to send messages'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await _ticketService.sendMessage(
        ticketId: widget.ticketId,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderEmail: currentUser.email,
        content: content,
        isStaff: currentUser.isStaff,
      );

      _messageController.clear();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteMessage(CareerMessage message) async {
    final currentUser = User.currentUser;
    if (message.senderId != currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete your own messages'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _ticketService.deleteMessage(
          ticketId: widget.ticketId,
          messageId: message.id,
          currentUserId: currentUser.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message deleted'),
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
  }

  Future<void> _showTicketOptions(CareerTicket ticket) async {
    final currentUser = User.currentUser;
    final isCreator = ticket.creatorId == currentUser.id;
    final isStaff = currentUser.isStaff;

    if (!isCreator && !isStaff) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ticket Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            if (ticket.status == CareerTicketStatus.open) ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark as Resolved'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _ticketService.updateTicketStatus(
                      widget.ticketId,
                      CareerTicketStatus.resolved,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ticket marked as resolved'),
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
                },
              ),
              if (isStaff)
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.grey),
                  title: const Text('Close Ticket'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await _ticketService.updateTicketStatus(
                        widget.ticketId,
                        CareerTicketStatus.closed,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ticket closed'),
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
                  },
                ),
            ] else if (ticket.status == CareerTicketStatus.resolved) ...[
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: const Text('Reopen Ticket'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _ticketService.updateTicketStatus(
                      widget.ticketId,
                      CareerTicketStatus.open,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ticket reopened'),
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
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;

    return StreamBuilder<CareerTicket?>(
      stream: _ticketService.getTicketStream(widget.ticketId),
      builder: (context, ticketSnapshot) {
        final ticket = ticketSnapshot.data;
        final canReply = ticket?.canReply(currentUser.id, currentUser.isStaff) ?? false;
        final isClosed = ticket?.status == CareerTicketStatus.closed;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            titleSpacing: 0,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0056AC),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0056AC).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.work_outline,
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
                        widget.ticketSubject,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: ticket?.status == CareerTicketStatus.open
                                  ? Colors.orange
                                  : ticket?.status == CareerTicketStatus.resolved
                                      ? Colors.green
                                      : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ticket?.status == CareerTicketStatus.open
                                ? 'Open'
                                : ticket?.status == CareerTicketStatus.resolved
                                    ? 'Resolved'
                                    : 'Closed',
                            style: TextStyle(
                              fontSize: 12,
                              color: ticket?.status == CareerTicketStatus.open
                                  ? Colors.orange
                                  : ticket?.status == CareerTicketStatus.resolved
                                      ? Colors.green
                                      : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (ticket != null)
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showTicketOptions(ticket),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<CareerMessage>>(
                  stream: _ticketService.getMessagesStream(widget.ticketId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - 1 - index];
                        final isCurrentUser = message.senderId == currentUser.id;

                        return CareerMessageBubble(
                          message: message,
                          isCurrentUser: isCurrentUser,
                          onLongPress: isCurrentUser
                              ? () => _deleteMessage(message)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
              if (isClosed)
                Container(
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
                        Icon(Icons.lock, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'This ticket has been closed',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!canReply)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border(
                      top: BorderSide(color: Colors.orange[200]!),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Only the ticket creator and ITEL staff can reply',
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide:
                                    const BorderSide(color: Color(0xFF0056AC)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            maxLines: 4,
                            minLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0056AC),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: IconButton(
                            onPressed: _isSending ? null : _sendMessage,
                            icon: _isSending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
