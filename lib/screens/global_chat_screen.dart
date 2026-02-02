// lib/screens/global_chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ITEL/models/chat_message.dart';
import 'package:ITEL/models/chat_ban.dart';
import 'package:ITEL/models/user.dart';
import 'package:ITEL/services/chat_service.dart';
import 'package:ITEL/widgets/chat_message_bubble.dart';
import 'package:ITEL/screens/direct_message_chat_screen.dart';
import 'package:ITEL/screens/event_chat_screen.dart';

class GlobalChatScreen extends StatefulWidget {
  const GlobalChatScreen({super.key});

  @override
  State<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends State<GlobalChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;

    if (isGuest) {
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
      // Double-check ban status before sending
      final banStatus = await _chatService.getUserBanStatus(currentUser.id);
      if (banStatus != null && banStatus.isActive) {
        if (mounted) {
          final message = banStatus.banType == ChatBanType.kicked
              ? 'You have been kicked from chat'
              : 'You are on cooldown. Please wait ${banStatus.remainingTimeFormatted}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _chatService.sendMessage(
        authorId: currentUser.id,
        authorName: currentUser.name,
        authorEmail: currentUser.email,
        content: content,
      );
      _messageController.clear();

      // Scroll to bottom after sending
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

  Future<void> _deleteMessage(ChatMessage message) async {
    final currentUser = User.currentUser;

    if (message.authorId != currentUser.id) {
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
        await _chatService.deleteMessage(
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

  void _startDirectMessage(ChatMessage message) {
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

    // Don't allow DM to yourself
    if (message.authorId == currentUser.id) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectMessageChatScreen(
          otherUserId: message.authorId,
          otherUserName: message.authorName,
          otherUserEmail: message.authorEmail,
        ),
      ),
    );
  }

  // ============ STAFF MODERATION ============

  void _showStaffModOptions(ChatMessage message) {
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
              'Moderate: ${message.authorName}',
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
              subtitle: const Text('Permanently ban from chat', style: TextStyle(fontSize: 12)),
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

  Future<void> _staffDeleteMessage(ChatMessage message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Delete this message? It will be removed completely without any trace.'),
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
        await _chatService.staffDeleteMessage(
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

  void _showCooldownOptions(ChatMessage message) {
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
              'For: ${message.authorName}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Duration options
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

  Future<void> _applyCooldown(ChatMessage message, Duration duration) async {
    try {
      final currentUser = User.currentUser;
      await _chatService.giveCooldown(
        odGptUserId: message.authorId,
        userName: message.authorName,
        userEmail: message.authorEmail,
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
            content: Text('${message.authorName} has been given a $durationText cooldown'),
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

  Future<void> _kickUser(ChatMessage message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kick User'),
        content: Text('Permanently ban ${message.authorName} from ITEL Community chat?\n\nThis user will not be able to send messages anymore.'),
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
        await _chatService.kickUser(
          odGptUserId: message.authorId,
          userName: message.authorName,
          userEmail: message.authorEmail,
          staffId: currentUser.id,
          staffName: currentUser.name,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${message.authorName} has been kicked from chat'),
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

    return Column(
      children: [
        // Chat messages
        Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _chatService.getMessagesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading messages...'),
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
                              'Error loading messages',
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
                          ],
                        ),
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
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
                              'Be the first to say hello!',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Latest messages at bottom
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCurrentUser = message.authorId == currentUser.id;
                      final isStaff = currentUser.isStaff;

                      return ChatMessageBubble(
                        message: message,
                        isCurrentUser: isCurrentUser,
                        onLongPress: isCurrentUser
                            ? () => _deleteMessage(message)
                            : (isStaff ? () => _showStaffModOptions(message) : null),
                        onTapAuthor: !isCurrentUser
                            ? () => _startDirectMessage(message)
                            : null,
                        onTapEvent: _openEventFromMessage,
                      );
                    },
                  );
                },
              ),
            ),

            // Message input (for logged-in users) - with ban status check
            if (!isGuest)
              StreamBuilder<ChatBan?>(
                stream: _chatService.getUserBanStatusStream(currentUser.id),
                builder: (context, banSnapshot) {
                  final ban = banSnapshot.data;

                  // If user is kicked (permanent ban)
                  if (ban != null && ban.banType == ChatBanType.kicked) {
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
                                    'You have been kicked from chat',
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

                  // If user is on cooldown (temporary ban) - use timer widget for real-time countdown
                  if (ban != null && ban.banType == ChatBanType.cooldown && ban.isActive) {
                    return CooldownDisplay(ban: ban);
                  }

                  // Normal message input
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
                                  : const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
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
    );
  }

  /// Handle tapping on an event share message
  void _openEventFromMessage(String eventId) {
    if (eventId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventChatScreen(eventId: eventId),
      ),
    );
  }
}

/// Widget that displays cooldown countdown with real-time timer
class CooldownDisplay extends StatefulWidget {
  final ChatBan ban;

  const CooldownDisplay({super.key, required this.ban});

  @override
  State<CooldownDisplay> createState() => _CooldownDisplayState();
}

class _CooldownDisplayState extends State<CooldownDisplay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update every second for real-time countdown
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

    // If cooldown has expired, show nothing (parent StreamBuilder will update)
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
