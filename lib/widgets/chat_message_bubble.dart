// lib/widgets/chat_message_bubble.dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onDelete,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // System messages (join/leave notifications)
    if (message.type == MessageType.system) {
      return _buildSystemMessage();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other users (left side)
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _getAvatarColor(message.authorName),
              child: Text(
                message.authorName.isNotEmpty
                    ? message.authorName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? const Color(0xFF0056AC)
                      : Colors.white,
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
                    // Author name (only for other users)
                    if (!isCurrentUser)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          message.authorName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getAvatarColor(message.authorName),
                          ),
                        ),
                      ),

                    // Message content
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: isCurrentUser ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),

                    // Timestamp
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

          // Avatar for current user (right side)
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF0056AC).withOpacity(0.2),
              child: Text(
                message.authorName.isNotEmpty
                    ? message.authorName[0].toUpperCase()
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

  Widget _buildSystemMessage() {
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

  // Generate consistent color based on username
  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF0056AC), // Blue
      const Color(0xFFFF6600), // Orange
      const Color(0xFF4CAF50), // Green
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF3F51B5), // Indigo
    ];

    if (name.isEmpty) return colors[0];
    final index = name.codeUnitAt(0) % colors.length;
    return colors[index];
  }
}
