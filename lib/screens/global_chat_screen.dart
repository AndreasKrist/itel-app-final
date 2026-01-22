// lib/screens/global_chat_screen.dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../models/voucher.dart';
import '../services/chat_service.dart';
import '../services/voucher_service.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/voucher_card.dart';
import '../widgets/create_voucher_sheet.dart';
import 'direct_message_chat_screen.dart';

class GlobalChatScreen extends StatefulWidget {
  const GlobalChatScreen({super.key});

  @override
  State<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends State<GlobalChatScreen> {
  final ChatService _chatService = ChatService();
  final VoucherService _voucherService = VoucherService();
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

  void _showCreateVoucherSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateVoucherSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;
    final canManageVouchers = currentUser.canManageVouchers;

    return Stack(
      children: [
        Column(
          children: [
            // Active Vouchers Section
            StreamBuilder<List<Voucher>>(
              stream: _voucherService.getActiveVouchersStream(),
              builder: (context, voucherSnapshot) {
                final vouchers = voucherSnapshot.data ?? [];
                final activeVouchers = vouchers
                    .where((v) => v.isActive || v.isPending)
                    .toList();

                if (activeVouchers.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flash_on,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'FLASH SALES',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${activeVouchers.length} active',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        itemCount: activeVouchers.length,
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: MediaQuery.of(context).size.width * 0.85,
                            child: VoucherCard(
                              voucher: activeVouchers[index],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
            ),

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

                      return ChatMessageBubble(
                        message: message,
                        isCurrentUser: isCurrentUser,
                        onLongPress: isCurrentUser
                            ? () => _deleteMessage(message)
                            : null,
                        onTapAuthor: !isCurrentUser
                            ? () => _startDirectMessage(message)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),

            // Message input (for logged-in users)
            if (!isGuest)
              Container(
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

        // Admin FAB for creating vouchers
        if (canManageVouchers)
          Positioned(
            right: 16,
            bottom: isGuest ? 80 : 100,
            child: FloatingActionButton.extended(
              onPressed: _showCreateVoucherSheet,
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.local_offer),
              label: const Text('Create Voucher'),
            ),
          ),
      ],
    );
  }
}
