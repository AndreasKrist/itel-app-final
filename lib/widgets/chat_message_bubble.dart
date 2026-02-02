// lib/widgets/chat_message_bubble.dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;
  final VoidCallback? onTapAuthor;  // Callback for tapping on author to start DM
  final Function(String eventId)? onTapEvent; // Callback for tapping event share message

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onDelete,
    this.onLongPress,
    this.onTapAuthor,
    this.onTapEvent,
  });

  @override
  Widget build(BuildContext context) {
    // System messages (join/leave notifications)
    if (message.type == MessageType.system) {
      return _buildSystemMessage();
    }

    // Event share messages
    if (message.type == MessageType.event_share) {
      return _buildEventShareMessage(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other users (left side) - tappable for DM
          if (!isCurrentUser) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapAuthor,
              child: CircleAvatar(
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
                    // Author name (only for other users) - tappable for DM
                    if (!isCurrentUser)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onTapAuthor,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            message.authorName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: onTapAuthor != null
                                  ? const Color(0xFF0056AC)
                                  : _getAvatarColor(message.authorName),
                              decoration: onTapAuthor != null
                                  ? TextDecoration.underline
                                  : null,
                            ),
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

  Widget _buildEventShareMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: message.eventId != null && onTapEvent != null
            ? () => onTapEvent!(message.eventId!)
            : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange[400]!, Colors.deepOrange[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.event,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'EVENT',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Content
                Text(
                  message.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                // Tap to join button
                if (message.eventId != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.deepOrange,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Tap to join',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Timestamp
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
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
