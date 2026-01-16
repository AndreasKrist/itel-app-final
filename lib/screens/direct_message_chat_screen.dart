// lib/screens/direct_message_chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../models/direct_message.dart';
import '../models/user.dart';
import '../models/user_presence.dart';
import '../services/direct_message_service.dart';
import '../widgets/direct_message_bubble.dart';

class DirectMessageChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserEmail;
  final String? otherUserProfileImage;

  const DirectMessageChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserEmail,
    this.otherUserProfileImage,
  });

  @override
  State<DirectMessageChatScreen> createState() => _DirectMessageChatScreenState();
}

class _DirectMessageChatScreenState extends State<DirectMessageChatScreen>
    with WidgetsBindingObserver {
  final DirectMessageService _dmService = DirectMessageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isSending = false;
  String? _conversationId;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initConversation();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    // Clear typing status when leaving
    if (_conversationId != null) {
      _dmService.setTypingStatus(
        userId: User.currentUser.id,
        conversationId: _conversationId!,
        isTyping: false,
      );
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userId = User.currentUser.id;
    if (userId.isEmpty) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _dmService.setOnlineStatus(userId, false);
    } else if (state == AppLifecycleState.resumed) {
      _dmService.setOnlineStatus(userId, true);
    }
  }

  Future<void> _initConversation() async {
    final currentUser = User.currentUser;
    if (currentUser.id.isEmpty) return;

    try {
      final conversation = await _dmService.getOrCreateConversation(
        currentUserId: currentUser.id,
        currentUserName: currentUser.name,
        currentUserEmail: currentUser.email,
        currentUserProfileImage: currentUser.profileImage,
        otherUserId: widget.otherUserId,
        otherUserName: widget.otherUserName,
        otherUserEmail: widget.otherUserEmail,
        otherUserProfileImage: widget.otherUserProfileImage,
      );

      setState(() {
        _conversationId = conversation.id;
      });

      // Mark conversation as read
      await _dmService.markAsRead(
        conversationId: conversation.id,
        userId: currentUser.id,
      );

      // Set online status
      await _dmService.setOnlineStatus(currentUser.id, true);
    } catch (e) {
      print('Error initializing conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTextChanged() {
    if (_conversationId == null) return;

    final hasText = _messageController.text.trim().isNotEmpty;

    if (hasText && !_isTyping) {
      _isTyping = true;
      _dmService.setTypingStatus(
        userId: User.currentUser.id,
        conversationId: _conversationId!,
        isTyping: true,
      );
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTyping) {
        _isTyping = false;
        _dmService.setTypingStatus(
          userId: User.currentUser.id,
          conversationId: _conversationId!,
          isTyping: false,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_conversationId == null) return;

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

    // Clear typing status
    _isTyping = false;
    _dmService.setTypingStatus(
      userId: currentUser.id,
      conversationId: _conversationId!,
      isTyping: false,
    );

    try {
      await _dmService.sendMessage(
        conversationId: _conversationId!,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderEmail: currentUser.email,
        content: content,
        recipientId: widget.otherUserId,
      );

      _messageController.clear();

      // Scroll to bottom
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

  Future<void> _deleteMessage(DirectMessage message) async {
    if (_conversationId == null) return;

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
        await _dmService.deleteMessage(
          conversationId: _conversationId!,
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

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: _getAvatarColor(widget.otherUserName),
              backgroundImage: widget.otherUserProfileImage != null
                  ? NetworkImage(widget.otherUserProfileImage!)
                  : null,
              child: widget.otherUserProfileImage == null
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Name and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Online status and typing indicator
                  StreamBuilder<UserPresence?>(
                    stream: _dmService.getUserPresenceStream(widget.otherUserId),
                    builder: (context, presenceSnapshot) {
                      final presence = presenceSnapshot.data;

                      // Check typing status
                      if (_conversationId != null) {
                        return StreamBuilder<bool>(
                          stream: _dmService.getTypingStatusStream(
                            conversationId: _conversationId!,
                            otherUserId: widget.otherUserId,
                          ),
                          builder: (context, typingSnapshot) {
                            final isTyping = typingSnapshot.data ?? false;

                            if (isTyping) {
                              return Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0056AC),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'typing...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF0056AC),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              );
                            }

                            return _buildOnlineStatus(presence);
                          },
                        );
                      }

                      return _buildOnlineStatus(presence);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _conversationId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<DirectMessage>>(
                    stream: _dmService.getMessagesStream(_conversationId!),
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
                              const SizedBox(height: 8),
                              Text(
                                'Say hello to ${widget.otherUserName}!',
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

                          return DirectMessageBubble(
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
          // Message input
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
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineStatus(UserPresence? presence) {
    if (presence == null) {
      return Text(
        'Offline',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: presence.isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          presence.getLastSeenText(),
          style: TextStyle(
            fontSize: 12,
            color: presence.isOnline ? Colors.green : Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
