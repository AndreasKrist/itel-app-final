// lib/screens/event_chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event.dart';
import '../models/event_voucher.dart';
import '../models/event_message.dart';
import '../models/event_ban.dart';
import '../models/claimed_voucher.dart';
import '../models/user.dart';
import '../services/event_service.dart';
import '../widgets/create_event_voucher_sheet.dart';
import 'direct_message_chat_screen.dart';

class EventChatScreen extends StatefulWidget {
  final String eventId;

  const EventChatScreen({super.key, required this.eventId});

  @override
  State<EventChatScreen> createState() => _EventChatScreenState();
}

class _EventChatScreenState extends State<EventChatScreen> {
  final EventService _eventService = EventService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isSending = false;
  bool _isVoucherExpanded = true;
  Set<String> _claimedVoucherIds = {};
  Map<String, ClaimedVoucher> _claimedVouchersMap = {};
  Map<String, bool> _claimingVouchers = {};

  @override
  void initState() {
    super.initState();
    _loadClaimedVouchers();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadClaimedVouchers() async {
    final currentUser = User.currentUser;
    if (currentUser.id.isEmpty) return;

    final claimedIds = await _eventService.getUserClaimedVoucherIds(
      userId: currentUser.id,
      eventId: widget.eventId,
    );

    // Fetch full claimed voucher data to get unique codes
    final claimedVouchers = await _eventService.getUserClaimedVouchers(
      userId: currentUser.id,
      eventId: widget.eventId,
    );

    if (mounted) {
      setState(() {
        _claimedVoucherIds = claimedIds.toSet();
        _claimedVouchersMap = {
          for (final v in claimedVouchers) v.voucherId: v
        };
      });
    }
  }

  Future<void> _sendMessage() async {
    final currentUser = User.currentUser;
    if (currentUser.id.isEmpty || currentUser.email.isEmpty) {
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
      await _eventService.sendMessage(
        eventId: widget.eventId,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderEmail: currentUser.email,
        content: content,
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
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _claimVoucher(EventVoucher voucher) async {
    final currentUser = User.currentUser;
    if (currentUser.id.isEmpty || currentUser.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to claim e-Voucher'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _claimingVouchers[voucher.id] = true);

    try {
      await _eventService.claimEventVoucher(
        eventId: widget.eventId,
        voucherId: voucher.id,
        userId: currentUser.id,
        userEmail: currentUser.email,
        userName: currentUser.name,
      );

      setState(() {
        _claimedVoucherIds.add(voucher.id);
      });

      // Refresh claimed vouchers
      await _loadClaimedVouchers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('e-Voucher claimed! Our team will email or call you to redeem the e-Voucher.'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _claimingVouchers[voucher.id] = false);
      }
    }
  }

  void _showAddVoucherSheet(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateEventVoucherSheet(
        eventId: widget.eventId,
        eventTitle: event.title,
      ),
    );
  }

  Future<void> _deleteMessage(EventMessage message) async {
    final currentUser = User.currentUser;
    if (message.senderId != currentUser.id) {
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
        await _eventService.deleteMessage(
          eventId: widget.eventId,
          messageId: message.id,
          currentUserId: currentUser.id,
        );
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

  void _startDirectMessage(EventMessage message) {
    final currentUser = User.currentUser;
    if (currentUser.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to send direct messages'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (message.senderId == currentUser.id) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectMessageChatScreen(
          otherUserId: message.senderId,
          otherUserName: message.senderName,
          otherUserEmail: message.senderEmail,
        ),
      ),
    );
  }

  // ============ STAFF MODERATION ============

  void _showStaffModOptions(EventMessage message) {
    final currentUser = User.currentUser;
    if (!currentUser.isStaff) return;

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
              'Moderate: ${message.senderName}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.content.length > 50
                  ? '"${message.content.substring(0, 50)}..."'
                  : '"${message.content}"',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Delete message
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Message'),
              subtitle: const Text('Remove without trace', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _staffDeleteMessage(message);
              },
            ),

            const Divider(),

            // Cooldown options
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.orange),
              title: const Text('Give Cooldown'),
              subtitle: const Text('Temporarily prevent from chatting', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showCooldownOptions(message);
              },
            ),

            // Kick user
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Kick User'),
              subtitle: const Text('Ban from this event chat', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _kickUser(message);
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _staffDeleteMessage(EventMessage message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Delete this message? It will be removed completely.'),
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
        final currentUser = User.currentUser;
        await _eventService.staffDeleteMessage(
          eventId: widget.eventId,
          messageId: message.id,
          staffId: currentUser.id,
          isStaff: currentUser.isStaff,
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

  void _showCooldownOptions(EventMessage message) {
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
              'Cooldown Duration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'For: ${message.senderName}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.timer, color: Colors.orange),
              title: const Text('5 minutes'),
              onTap: () {
                Navigator.pop(context);
                _applyCooldown(message, const Duration(minutes: 5));
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.orange),
              title: const Text('15 minutes'),
              onTap: () {
                Navigator.pop(context);
                _applyCooldown(message, const Duration(minutes: 15));
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.orange),
              title: const Text('1 hour'),
              onTap: () {
                Navigator.pop(context);
                _applyCooldown(message, const Duration(hours: 1));
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.deepOrange),
              title: const Text('24 hours'),
              onTap: () {
                Navigator.pop(context);
                _applyCooldown(message, const Duration(hours: 24));
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _applyCooldown(EventMessage message, Duration duration) async {
    try {
      final currentUser = User.currentUser;
      await _eventService.giveCooldown(
        eventId: widget.eventId,
        userId: message.senderId,
        userName: message.senderName,
        userEmail: message.senderEmail,
        staffId: currentUser.id,
        staffName: currentUser.name,
        duration: duration,
      );
      if (mounted) {
        final durationText = duration.inHours > 0
            ? '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}'
            : '${duration.inMinutes} minutes';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${message.senderName} has been given a $durationText cooldown'),
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

  Future<void> _kickUser(EventMessage message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kick User'),
        content: Text('Ban ${message.senderName} from this event chat?\n\nThey will not be able to send messages in this event anymore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Kick'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final currentUser = User.currentUser;
        await _eventService.kickUser(
          eventId: widget.eventId,
          userId: message.senderId,
          userName: message.senderName,
          userEmail: message.senderEmail,
          staffId: currentUser.id,
          staffName: currentUser.name,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${message.senderName} has been kicked from this event'),
              backgroundColor: Colors.red,
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

  void _showEventOptions(Event event) {
    final currentUser = User.currentUser;
    final isStaff = currentUser.isStaff;

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
              'Event Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            // Event info (for all users)
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: const Text('Event Info'),
              subtitle: Text(
                '${event.title}\n${event.isActive ? "Live now" : event.isPending ? "Starting soon" : "Ended"}',
                style: const TextStyle(fontSize: 12),
              ),
              isThreeLine: true,
            ),

            // Copy event link (for all users)
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: const Text('Copy Event ID'),
              subtitle: const Text('Share this event with others', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: widget.eventId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Event ID copied to clipboard'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),

            if (isStaff) const Divider(),

            // Add voucher (staff only)
            if (isStaff)
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.green),
                title: const Text('Add e-Voucher'),
                subtitle: const Text('Create a new e-Voucher for this event', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddVoucherSheet(event);
                },
              ),

            // Share to global chat (staff only)
            if (isStaff && !event.isSharedToGlobalChat)
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Share to Global Chat'),
                subtitle: const Text('Announce this event to everyone', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _shareToGlobalChat(event);
                },
              ),

            if (isStaff && event.isSharedToGlobalChat)
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.grey[400]),
                title: Text('Already Shared', style: TextStyle(color: Colors.grey[600])),
                subtitle: const Text('This event was shared to global chat', style: TextStyle(fontSize: 12)),
              ),

            // Delete event (staff only)
            if (isStaff)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Event'),
                subtitle: const Text('Permanently remove this event', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteEvent(event);
                },
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _shareToGlobalChat(Event event) async {
    try {
      final currentUser = User.currentUser;
      await _eventService.shareToGlobalChat(
        eventId: widget.eventId,
        staffId: currentUser.id,
        staffName: currentUser.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event shared to global chat!'),
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

  Future<void> _deleteEvent(Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?\n\nThis will also delete all messages and e-Vouchers. This action cannot be undone.'),
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
        await _eventService.deleteEvent(widget.eventId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event deleted'),
              backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;

    return StreamBuilder<Event?>(
      stream: _eventService.getEventStream(widget.eventId),
      builder: (context, eventSnapshot) {
        final event = eventSnapshot.data;

        if (eventSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              title: const Text('Loading...'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (event == null) {
          return Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              title: const Text('Event'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Event not found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: event.isActive
                          ? [Colors.orange, Colors.deepOrange]
                          : event.isPending
                              ? [Colors.blue, Colors.blueAccent]
                              : [Colors.grey, Colors.grey],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event,
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
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      EventCountdownTimer(event: event),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showEventOptions(event),
              ),
            ],
          ),
          body: Column(
            children: [
              // Vouchers section (collapsible)
              _buildVouchersSection(event),

              // Chat messages
              Expanded(
                child: StreamBuilder<List<EventMessage>>(
                  stream: _eventService.getMessagesStream(widget.eventId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start the conversation!',
                              style: TextStyle(color: Colors.grey[500]),
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
                        final message = messages[index];
                        final isCurrentUser = message.senderId == currentUser.id;
                        final isStaff = currentUser.isStaff;

                        return _buildMessageBubble(
                          message,
                          isCurrentUser,
                          isStaff: isStaff,
                        );
                      },
                    );
                  },
                ),
              ),

              // Message input or ban notice
              if (!isGuest)
                StreamBuilder<EventBan?>(
                  stream: _eventService.getUserBanStatusStream(widget.eventId, currentUser.id),
                  builder: (context, banSnapshot) {
                    final ban = banSnapshot.data;

                    // If user is kicked (permanent ban)
                    if (ban != null && ban.banType == EventBanType.kicked) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border(
                            top: BorderSide(color: Colors.red[200]!),
                          ),
                        ),
                        child: SafeArea(
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Colors.red[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'You have been kicked from this event',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (ban.reason != null && ban.reason!.isNotEmpty)
                                      Text(
                                        'Reason: ${ban.reason}',
                                        style: TextStyle(
                                          color: Colors.red[600],
                                          fontSize: 12,
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

                    // If user is on cooldown
                    if (ban != null && ban.banType == EventBanType.cooldown && ban.isActive) {
                      return EventCooldownDisplay(ban: ban);
                    }

                    // Normal message input
                    return _buildMessageInput();
                  },
                ),

              // Guest prompt
              if (isGuest)
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
                        Icon(Icons.info_outline, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sign in to join the conversation',
                            style: TextStyle(color: Colors.orange[700]),
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

  Widget _buildVouchersSection(Event event) {
    final currentUser = User.currentUser;
    final isStaff = currentUser.isStaff;

    return StreamBuilder<List<EventVoucher>>(
      stream: _eventService.getEventVouchersStream(widget.eventId),
      builder: (context, snapshot) {
        final vouchers = snapshot.data ?? [];

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Card(
            margin: const EdgeInsets.all(12),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: event.isActive
                      ? [Colors.orange[400]!, Colors.deepOrange[500]!]
                      : event.isPending
                          ? [Colors.blue[400]!, Colors.blue[600]!]
                          : [Colors.grey[400]!, Colors.grey[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Header row with expand/collapse
                  InkWell(
                    onTap: () => setState(() => _isVoucherExpanded = !_isVoucherExpanded),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_offer, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${vouchers.length} e-Voucher${vouchers.length != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Add voucher button for staff
                          if (isStaff)
                            GestureDetector(
                              onTap: () => _showAddVoucherSheet(event),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            _isVoucherExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expanded content - voucher list
                  if (_isVoucherExpanded) ...[
                    if (vouchers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.local_offer_outlined, color: Colors.white.withOpacity(0.7), size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'No e-Vouchers yet',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isStaff)
                                Text(
                                  'Tap + to add an e-Voucher',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...vouchers.map((voucher) => _buildVoucherItem(voucher, event)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoucherItem(EventVoucher voucher, Event event) {
    final hasClaimed = _claimedVoucherIds.contains(voucher.id);
    final isClaiming = _claimingVouchers[voucher.id] ?? false;
    final canClaim = event.isActive && voucher.canBeClaimed && !hasClaimed;
    final hasCustomExpiry = voucher.expiresAt != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voucher header - description on top, discount below
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description (top)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        voucher.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Claimed badge (when already claimed) - stays with description
                    if (hasClaimed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Claimed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Discount badge (compact)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    voucher.discountText,
                    style: TextStyle(
                      color: Colors.deepOrange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Bottom row: Expires on left, CLAIM button on right
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Expires countdown at bottom left (live updating)
                if (hasCustomExpiry && !voucher.isExpired && event.isActive)
                  VoucherExpiryCountdown(expiresAt: voucher.expiresAt!),
                const Spacer(),
                // CLAIM button at bottom right with "left" count above
                if (canClaim)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // "X left" above CLAIM button
                      if (voucher.maxClaims != null) ...[
                        Text(
                          '${voucher.remainingClaims} left',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      ElevatedButton(
                        onPressed: isClaiming ? null : () => _claimVoucher(voucher),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: isClaiming
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'CLAIM',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ],
                  ),
              ],
            ),

            // Status message for unavailable vouchers
            if (!canClaim && !hasClaimed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    !voucher.isActive
                        ? Icons.block
                        : voucher.isExpired
                            ? Icons.timer_off
                            : voucher.isFullyClaimed
                                ? Icons.remove_shopping_cart
                                : event.isPending
                                    ? Icons.schedule
                                    : Icons.timer_off,
                    color: Colors.white.withOpacity(0.7),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    !voucher.isActive
                        ? 'e-Voucher inactive'
                        : voucher.isExpired
                            ? 'e-Voucher expired'
                            : voucher.isFullyClaimed
                                ? 'Sold out'
                                : event.isPending
                                    ? 'Event not started'
                                    : 'Event ended',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatVoucherExpiry(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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
                    borderSide: const BorderSide(color: Color(0xFF0056AC)),
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
    );
  }

  Widget _buildMessageBubble(EventMessage message, bool isCurrentUser, {required bool isStaff}) {
    if (message.type == EventMessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    if (message.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisAlignment:
              isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isCurrentUser) const SizedBox(width: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    'This message was deleted',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrentUser) const SizedBox(width: 40),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            GestureDetector(
              onTap: () => _startDirectMessage(message),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: _getAvatarColor(message.senderName),
                child: Text(
                  message.senderName.isNotEmpty
                      ? message.senderName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: isCurrentUser
                  ? () => _deleteMessage(message)
                  : (isStaff ? () => _showStaffModOptions(message) : null),
              onTap: !isCurrentUser ? () => _startDirectMessage(message) : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrentUser ? const Color(0xFF0056AC) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                    bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          message.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: isCurrentUser ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrentUser
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF0056AC).withOpacity(0.2),
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF0056AC),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
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

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }
}

/// Widget that displays countdown timer for event
class EventCountdownTimer extends StatefulWidget {
  final Event event;

  const EventCountdownTimer({super.key, required this.event});

  @override
  State<EventCountdownTimer> createState() => _EventCountdownTimerState();
}

class _EventCountdownTimerState extends State<EventCountdownTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.event.isExpired) {
      return Text(
        'Event ended',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      );
    }

    if (widget.event.isPending) {
      return Text(
        'Starts in ${_formatDuration(widget.event.timeUntilStart)}',
        style: const TextStyle(fontSize: 12, color: Colors.blue),
      );
    }

    return Text(
      'Ends in ${_formatDuration(widget.event.remainingTime)}',
      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

/// Widget that displays cooldown countdown with real-time timer
class EventCooldownDisplay extends StatefulWidget {
  final EventBan ban;

  const EventCooldownDisplay({super.key, required this.ban});

  @override
  State<EventCooldownDisplay> createState() => _EventCooldownDisplayState();
}

class _EventCooldownDisplayState extends State<EventCooldownDisplay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.ban.remainingCooldown;

    if (remaining == null || remaining.isNegative) {
      return const SizedBox.shrink();
    }

    return Container(
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
            Icon(Icons.timer, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You are on cooldown',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Time remaining: ${widget.ban.remainingTimeFormatted}',
                    style: TextStyle(
                      color: Colors.orange[600],
                      fontSize: 12,
                    ),
                  ),
                  if (widget.ban.reason != null && widget.ban.reason!.isNotEmpty)
                    Text(
                      'Reason: ${widget.ban.reason}',
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontSize: 12,
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
}

/// Widget that displays live countdown timer for voucher expiry
class VoucherExpiryCountdown extends StatefulWidget {
  final DateTime expiresAt;

  const VoucherExpiryCountdown({super.key, required this.expiresAt});

  @override
  State<VoucherExpiryCountdown> createState() => _VoucherExpiryCountdownState();
}

class _VoucherExpiryCountdownState extends State<VoucherExpiryCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.expiresAt.difference(DateTime.now());
    final isExpired = remaining.isNegative;

    if (isExpired) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_off,
            color: Colors.yellow[300],
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Expired',
            style: TextStyle(
              color: Colors.yellow[300],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          color: Colors.yellow[300],
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          'Expires in ${_formatDuration(remaining)}',
          style: TextStyle(
            color: Colors.yellow[300],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
